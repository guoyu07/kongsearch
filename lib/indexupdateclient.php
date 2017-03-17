<?php
date_default_timezone_set('Asia/Chongqing');

/**
 * 索引更新服务客户端类
 * @author      liuxingzhi
 * @date        2013-09
 */

class IndexUpdateClient 
{
    private $jobServers;
    private $timeout;
    private $redis;
    private $user;
    private $password;
    private $errorInfo;

    /**
     * 构造函数
     * @param string $jobServers gearman服务器列表(eg,"host1:port,host2:port")
     * @param string $redis      redis服务器(host:port)，用于存放gearman故障时的更新消息。
     * @param string $user       索引更新服务的用户名，默认为空。
     * @param string $password   索引更新服务的密码，默认为空。
     * @param int    $timeout    gearman超时时间(毫秒)
     */
    public function __construct($jobServers, $redis, $user='', $password='', $timeout=5000)
    {
       $this->jobServers = $jobServers;
       $this->timeout = $timeout;
       $this->redis = explode(':', $redis);
       $this->user = $user;
       $this->password = $password;
       $this->errorInfo = '';
    }
    
    public function getErrorInfo()
    {
        return $this->errorInfo;
    }
    
    private function getJsonErrorMsg() 
    {
        switch (json_last_error()) {
            case JSON_ERROR_NONE:
                $errmsg = 'No errors';
                break;
            case JSON_ERROR_DEPTH:
                $errmsg = 'Maximum stack depth exceeded';
                break;
            case JSON_ERROR_STATE_MISMATCH:
                $errmsg = 'Underflow or the modes mismatch';
                break;
            case JSON_ERROR_CTRL_CHAR:
                $errmsg = 'Unexpected control character found';
                break;
            case JSON_ERROR_SYNTAX:
                $errmsg = 'Syntax error, malformed JSON';
                break;
            case JSON_ERROR_UTF8:
                $errmsg = 'Malformed UTF-8 characters, possibly incorrectly encoded';
                break;
            default:
                $errmsg = 'Unknown error';
                break;
        }
        
        return $errmsg;
    }

    public function sendToGearmand ($packet, $isAsync)
    {   
        if (!is_string($this->jobServers) || empty($this->jobServers)) {
            $this->errorInfo = 'job servers set error';
            return false;
        }

        try {
          $gearmanClient = new GearmanClient();
          $gearmanClient->addServers($this->jobServers);
          $gearmanClient->setTimeout(intval($this->timeout));
        } catch (GearmanException $e) {
            $this->errorInfo = $e->getMessage();
            return NULL;
        }
        
        //把job交给job server
        if ($isAsync)
            $result = @$gearmanClient->doBackground('updateIndex', $packet);
        else
            $result = @$gearmanClient->do('updateIndex', $packet); // v0.25版本只能用do(),不能用doNormal()
           
        $status = $gearmanClient->returnCode();
        if ($status == GEARMAN_SUCCESS) {
            if($isAsync) {
                return true;
            } else {
                $result = json_decode($result, true);
                if($result['status'] === true) {
                    return true;
                } else {
                    $this->errorInfo = $result['result'];
                    return false;
                }   
            }
        } else {
            if ($status == GEARMAN_TIMEOUT){
                $this->errorInfo = "[{$status}] Gearman Client timeout";
            } else if($status == GEARMAN_COULD_NOT_CONNECT) {
                $this->errorInfo = "[{$status}] can't connect job server";
            } else if($status == GEARMAN_LOST_CONNECTION) {
                $this->errorInfo = "[{$status}] lost connect in request to job server";
            } else {
                $this->errorInfo = "[{$status}] unknow gearman error";
            }

            return NULL;
        }
    }
    
    private function doAction($index, $type, $action, $id='', $attr='', $where='', $shardkey='', $isAsync=false)
    {
        $packet = array();
        $packet['index'] = $index;
        $packet['type'] = $type;
        $packet['action'] = $action;
        $packet['user'] = $this->user;
        $packet['password'] = $this->password;
        $packet['time'] = date("Y-m-d H:i:s");
        
        switch ($action) {
            case 'insert':
            case 'modify':
                $packet['id'] = $id;
                $packet['shardkey'] = '';
                if(!empty($shardkey) || $shardkey === 0 || $shardkey === '0')
                    $packet['shardkey'] = $shardkey;
                break;
            case 'update':
                $packet['attr'] = $attr;
            case 'delete':
            case 'softdelete':
            case 'recovery':
                $packet['id'] = '';
                $packet['where'] = '';
                if(!empty($id) || $id === 0 || $id === '0')
                    $packet['id'] = $id;
                if(!empty($where))
                    $packet['where'] = urlencode($where); // where条件可能存在utf8编码的中文
                break;
            case 'truncate':
            case 'flush':
            case 'attach':
            case 'optimize':
            case 'flushattrs':
            case 'redo':
            case 'retry':
            case 'rebuild-start':
            case 'rebuild-stopped':
                break;
            default:
                $this->errorInfo = 'index update action is unsupport';
                return false;
        }
        
        if(($packet = json_encode($packet)) === false) {
            $errmsg = $this->getJsonErrorMsg();
            $this->errorInfo = "json encode error for {$index}:{$action}: $errmsg";
            return false;
        }
        
        $packet = urldecode($packet);
        $r = $this->sendToGearmand($packet, $isAsync);
        if($r === NULL) { // gearman故障，记录更新消息到失败队列。
            $queue = 'IndexUpdate:'.$index.':FailureQueue';
            $redis = new Redis();
            if($redis->connect($this->redis[0], $this->redis[1]) === false) {
                $this->errorInfo = "connect redis server [{$this->redis[0]}:{$this->redis[1]}] failure.";
                return false;
            }
            
            if($redis->rPush($queue, $packet) === false) {
                $this->errorInfo = "can't push into failure queue: $packet";
                $redis->close();
                return false;
            }
            
            $redis->close();
            return false;
        }
        
        return $r;
    }
    
    /**
     * 插入新增的记录
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param mixed   $id          新增记录id，可以是int string or array
     * @param int/string $shardkey 用于水平切分的key。可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean
     */
    public function insert($index, $type, $id, $shardkey='', $isAsync=true)
    {
        if(empty($id) && $id !== 0 && $id !== '0') { 
            $this->errorInfo = "id is empty for insert";
            return false;
        } 
        
        return $this->doAction($index, $type, 'insert', $id, '', '', $shardkey, $isAsync);
    }
    
    /** 
     * 从索引中删除指定的记录。
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param mixed   $id          删除记录id，可以是int string or array，可选。
     * @param string  $where       删除条件，可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean 
     */
    public function delete($index, $type, $id='', $where='', $isAsync=true)
    {
        if((empty($id) && $id !== 0 && $id !== '0') && empty($where)) {
            $this->errorInfo = 'id and where is empty for delete';
            return false;
        } 
        
        return $this->doAction($index, $type, 'delete', $id, '', $where, '', $isAsync);
    }
    
    /** 
     * 指明索引中哪些记录的字段发生修改了。 
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param mixed   $id          修改的记录id，可以是int string or array
     * @param int/string $shardkey 用于水平切分的key。可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean
     */
    public function modify($index, $type, $id, $shardkey='', $isAsync=true)
    {
        if(empty($id) && $id !== 0 && $id !== '0') { 
            $this->errorInfo = "id is empty for modify";
            return false;
        } 
        
        return $this->doAction($index, $type, 'modify', $id, '', '', $shardkey, $isAsync);
    }
    
    /**
     * 更新索引中记录的属性
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param string  $attr        需要更新的属性以及取值，格式为： name=value, name=value,... 
     * @param mixed   $id          更新记录id，可以是int string or array。可选。
     * @param string  $where       属性更新的查询条件。可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean
     */
    public function update($index, $type, $attr, $id='', $where='', $isAsync=true)
    {
        if((empty($id) && $id !== 0 && $id !== '0') && empty($where)) {
            $this->errorInfo = 'id and where is empty for update';
            return false;
        } 
        
        if(empty($attr)) {
            $this->errorInfo ='attribute is empty for update';
            return false;
        }
        
        return $this->doAction($index, $type, 'update', $id, $attr, $where, '', $isAsync);
    }
    
     /** 
     * 从索引中给指定的记录打上删除标记。可以恢复。
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param mixed   $id          删除记录id，可以是int string or array，可选。
     * @param string  $where       删除查询条件，可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean 
     */
    public function softdelete($index, $type, $id='', $where='', $isAsync=true)
    {
        if((empty($id) && $id !== 0 && $id !== '0') && empty($where)) {
            $this->errorInfo = 'id and where is empty for softdelete';
            return false;
        } 
        
        return $this->doAction($index, $type, 'softdelete', $id, '', $where, '', $isAsync);
    }
    
    /** 
     * 从索引中恢复软删除的记录。
     * @param string  $index       索引名
     * @param string  $type        索引数据类型
     * @param mixed   $id          恢复记录id，可以是int string or array，可选。
     * @param string  $where       恢复查询条件，可选。
     * @param boolean $isAsync     是否异步处理
     * @return boolean 
     */
    public function recovery($index, $type, $id='', $where='', $isAsync=true)
    {
        if((empty($id) && $id !== 0 && $id !== '0') && empty($where)) {
            $this->errorInfo = 'id and where is empty for recovery';
            return false;
        } 
        
        return $this->doAction($index, $type, 'recovery', $id, '', $where, '', $isAsync);
    }
    
    /**
     * 清空实时索引
     */
    public function truncate($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'truncate', '', '', '', '', $isAsync);
    }
    
    /**
     * 刷新实时索引
     */
    public function flush($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'flush', '', '', '', '', $isAsync);
    }
    
    /**
     * 把硬盘索引加载为实时索引。
     */
    public function attach($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'attach', '', '', '', '', $isAsync);
    }
    
    /**
     * 优化实时索引。
     */
    public function optimize($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'optimize', '', '', '', '', $isAsync);
    }
    
    /**
     * 刷新更新属性。
     */
    public function flushattrs($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'flushattrs', '', '', '', '', $isAsync);
    }
    
    /**
     * 对updatelog的更新消息进行重做。
     */
    public function redo($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'redo', '', '', '', '', $isAsync);
    }
    
    /**
     * 对失败队列里的更新消息进行重试。
     */
    public function retry($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'retry', '', '', '', '', $isAsync);
    }
    
    /**
     * 通知索引更新服务正在进行重建索引。
     */
    public function rebuild_start($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'rebuild-start', '', '', '', '', $isAsync);
    }
    
    /**
     * 通知索引更新服务重建索引完毕。
     */
    public function rebuild_stopped($index, $type, $isAsync=true)
    {
        return $this->doAction($index, $type, 'rebuild-stopped', '', '', '', '', $isAsync);
    }
}

?>
