<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_shop_recommend
{
    private $errorInfo;
    private $record;
    private static $authorBlist;
    
    public function __construct($config) 
    {
        $this->errorInfo = '';
        $this->record = array();
        
        // 加载作者黑名单
        if(!isset(self::$authorBlist)) {
            self::$authorBlist = array();
            if(isset($config['blacklist.author']) && !empty($config['blacklist.author'])) {
                $blist = file($config['blacklist.author']);
                if($blist === false) {
                    $this->errorInfo = "load {$config['blacklist.author']} failure.";
                    throw new Exception($this->errorInfo);
                }

               foreach($blist as $key){
                   $key = trim($key);
                   self::$authorBlist[$key] = 1;
                }
            }
        }
        
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    // 此方法依赖于mbstring扩展。
    public function fan2jian($value)
    {
        global $Unihan;

        if ($value === '')
            return '';
        $r = '';
        $len = mb_strlen($value, 'UTF-8');
        for ($i = 0; $i < $len; $i++) {
            $c = mb_substr($value, $i, 1, 'UTF-8');
            if (isset($Unihan[$c]))
                $c = $Unihan[$c];
            $r .= $c;
        }

        return $r;
    }
    
    private function trimTail($str,$tails)
    {
        $slen = strlen($str);
        foreach($tails as $tail) {
            $tlen = strlen($tail);
            if($tlen > $slen) continue;
            if(substr_compare($str, $tail, -$tlen, $tlen) == 0) {
                return substr($str, 0, $slen - $tlen);
            }
        }
        return $str;
    }
    
    private function trimHead($str,$heads)
    {
        $slen = strlen($str);
        foreach($heads as $head) {
            $hlen = strlen($head);
            if($hlen > $slen) continue;
            if(substr_compare($str, $head, 0, $hlen) == 0) {
                return substr($str, $hlen, $slen - $hlen);
            }
        }
        return $str;
    }
    
    public function author2($value)
    {
        if(empty($value))
            return '';
        
        $other = '其他';
        $value = trim($value);
        if(empty($value)) return '';
        $len = mb_strlen($value,'UTF-8'); 
        if($len == 1) return $other;
        if(!empty(self::$authorBlist) && isset(self::$authorBlist[$value]))
            return $other;
                
        $src = array(' ', '　','...', '*', '★',  ',', '//', ':', '・', '•', '(',  ')',  '[',  ']',  '【', '】',  '［', '］');
        $dst = array( '',   '',   '',  '',   '', '，', '，', '：', '·', '·', '（', '）', '（', '）',  '（',  '）', '（', '）');
        $head = array('：',':','！','!');
        $tail = array('/著','编著','编辑','主编','(作者)','(编者)','绘画','绘制','绘著','编绘','漫画','著','撰','编','绘','。','.','？？','？','??','?');
        
        //先去头去尾，再替换、过滤
        $value = $this->trimHead($value, $head);
        if(empty($value)) return $other;
        $value = $this->trimTail($value, $tail);
        if(empty($value)) return $other;
        $value = str_replace($src, $dst, $value);
        return $value;
    }
    
    /**
     * 处理insert、modify的数据
     */
    public function deal($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        $msgFields = array(
            'itemId',
            'itemName',
            'catId',
            'imgUrl',
            'shopClass',
            'addTime',
            'sellerId',
            'shopId',
            'count',
            'isDelete',
            'price',
            'shopTrust',
            'ranker'
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //itemName
        $msg['itemName'] = $this->fan2jian($msg['itemName']);
        
        //_itemName
        $msg['_itemName'] = $msg['itemName'];
        
        //author
        if(isset($msg['author'])) {
            $msg['author'] = $this->fan2jian($msg['author']);
        }
        
        //_author
        if(isset($msg['author'])) {
            $msg['_author'] = $msg['author'];
        }
        
        //author2
        if(isset($msg['author'])) {
            $msg['author2'] = $this->author2($msg['author']);
        }
        
        //isdeleted
        $msg['isdeleted'] = $msg['isDelete'];
        unset($msg['isDelete']);
        
        //大小写转换
        foreach($msg as $k => $v) {
            $lower_k = strtolower($k);
            if($k === $lower_k) {
                continue;
            }
            $msg[$lower_k] = $v;
            unset($msg[$k]);
        }
        
        return $msg;

    }
    
    /**
     * 处理update的数据
     */
    public function dealUp($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        
        //itemName
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['itemName'] = $this->fan2jian($msg['itemName']);
        }
        
        //_itemName
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['_itemName'] = $msg['itemName'];
        }
        
        //author
        if(isset($msg['author']) && $msg['author']) {
            $msg['author'] = $this->fan2jian($msg['author']);
        }
        
        //_author
        if(isset($msg['author']) && $msg['author']) {
            $msg['_author'] = $msg['author'];
        }
        
        //author2
        if(isset($msg['author']) && $msg['author']) {
            $msg['author2'] = $this->author2($msg['author']);
        }
        
        //isdeleted
        if(isset($msg['isDelete'])) {
            $msg['isdeleted'] = $msg['isDelete'] ? $msg['isDelete'] : 0;
            unset($msg['isDelete']);
        }
        
        //count
        if(isset($msg['count'])) {
            $msg['count'] = $msg['count'] > 0 ? $msg['count'] : 0;
        }
        
        //大小写转换
        foreach($msg as $k => $v) {
            $lower_k = strtolower($k);
            if($k === $lower_k) {
                continue;
            }
            $msg[$lower_k] = $v;
            unset($msg[$k]);
        }
        
        return $msg;

    }
    
    public function customupdate($indexconfig, $msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $msgPrimaryKey = isset($indexconfig['msgPrimaryKey']) && !empty($indexconfig['msgPrimaryKey']) ? $indexconfig['msgPrimaryKey'] : 'itemId';
        if(!isset($msg['data'][$msgPrimaryKey]) || empty($msg['data'][$msgPrimaryKey])) {
            $this->errorInfo = "[ERROR]: the primary key isn't set.";
            return false;
        }
        
        $redisInfo = $indexconfig['redis'];
        if(!isset($redisInfo[0]) && !isset($redisInfo[1])) {
            $this->errorInfo = "Redis Set Error.";
            return false;
        }
        $redisObj = new Redis();
        if($redisObj->connect($redisInfo[0], $redisInfo[1]) === false && $redisObj->connect($redisInfo[0], $redisInfo[1]) === false) {
            $this->errorInfo = "redis connect error .";
            return false;
        }

        $updateData = $this->dealUp($msg);
        if($updateData === false) {
            $this->errorInfo = $this->getErrorInfo();
            return false;
        }
        $server = ElasticSearchModel::getServer($indexconfig['servers']);
        $result = ElasticSearchModel::updateDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $msg['data'][$msgPrimaryKey], $updateData);
        if($result && (isset($result['_version']) || (isset($result['status']) && $result['status'] == '404'))) {
            if(isset($updateData['count'])) { //更新点击次数
                $itemCountHashTableKey = 'itemCountHashTable';
                $redisObj->hset($itemCountHashTableKey, $msg['data'][$msgPrimaryKey], $updateData['count']);
            }
            if(isset($result['status']) && $result['status'] == '404') {
                $this->errorInfo = json_encode($result);
            }
            return true;
        } else {
            $this->errorInfo = "[ERROR]: ". var_export($result, true);
            return false;
        }
    }
    
}
