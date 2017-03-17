<?php

require_once 'sphinxapi.php';

/**
 * 索引访问对象(IAO: Index Access Object)
 * 要求索引有名为isdeleted的属性，isdeleted取值说明如下：
 * 0 - 没有删除，1 - 删除， 2 - 软删除。
 */

class IAO 
{
    private $rtc;           // realtime index connect 
    private $dsn;
    private $errorInfo;

    public function __construct($host='localhost', $port='9306')  
    { 
        $this->dsn = 'mysql:'; // charset=utf8;
        $this->dsn .=  ('host=' . $host . ';' );
        $this->dsn .=  ('port=' . $port);
        $this->errorInfo = '';
    }
    
    public function connect($isPersistent=false)
    {
        $connectNum = 2; //连接失败后再重连一次，最多两次。
        do {
            try {
                if($isPersistent)
                    $this->rtc = new PDO($this->dsn, '', '', array(PDO::ATTR_PERSISTENT => true));
                else
                    $this->rtc = new PDO($this->dsn, '', '', array(PDO::ATTR_PERSISTENT => false));
                $this->rtc->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_SILENT); 
                $this->rtc->setAttribute(PDO::ATTR_EMULATE_PREPARES, true); 
                return true;
            } catch (PDOException $e) {
                $connectNum--;
                if($connectNum == 0) {
                    $this->errorInfo = $e->getMessage();
                    return false;
                }
            }
        } while($connectNum > 0);
    }
    
    public function disconnect() 
    {
        $this->rtc = NULL;
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    // MVA value: (int,int,...) 注意：()是合法的值，'' NULL 不是合法的值。
    private function is_mva($value)
    {
        if(empty($value)) return false;
        $len = strlen($value);
        if(strpos($value,'(') === 0 && strrpos($value, ')') === ($len-1)) {
            $n = substr($value, 1, $len-2);
            $r = explode(',', $n);
            foreach($r as $v) {
                $v = trim($v);
                if(empty($v)) continue;
                if(!is_numeric($v)) 
                    return false;
            }
            return true;
        }
        return false;
    }

    // $values可以是一维数组，也可以是二维数组（批量插入） 支持MVA。
    public function insert($rtindex, $cols, $values, $action='INSERT') 
    {
        if(!is_array($cols) || !is_array($values)) {
            $this->errorInfo = "$action parameters error.";
            return false;
        }
        
        if(is_array($values[0])) {
            foreach($values as $value) {
                if(count($cols) != count($value)) {
                    $this->errorInfo = "$action parameters mismatch.";
                    return false;
                }
            }
        } else if(count($cols) != count($values)) {
            $this->errorInfo = "$action parameters mismatch.";
            return false;
        }
        
        if(is_array($values[0])) {
            foreach($values as $key => $value) {
                $vs[$key] = $value;
            }
        } else {
            $vs[0] = $values;
        }
        
        foreach($vs as $value) {
            $collist = '';
            $vallist = '';
            foreach ($value as $k => $v) {
                if($v == '()' || $v == '( )') {
                    $v = "'（）'";
                }
                if(is_int($v)) {
                    $vallist .= $v;
                } else if(is_null($v) || $v === '') {
                    continue;
                } else if($this->is_mva($v)) {
                    $vallist .= $v;
                } else {
                    $vallist .= $this->rtc->quote($v);
                }
                $vallist .= ',';
                $collist .= $cols[$k];
                $collist .= ',';
            }
            
            $collist = rtrim($collist, ',');
            $vallist = rtrim($vallist, ',');
            $sql = "$action INTO $rtindex ( $collist ) VALUES ( $vallist ) ";
            $result = $this->rtc->exec($sql);
            if($result === false) {
                $e = $this->rtc->errorInfo();
                $this->errorInfo = $e[2];
                return false;
            }
        }
  
        return true;
    }
    
    // $values可以是一维数组，也可以是二维数组（批量插入） 不支持MVA。
    public function insert2($rtindex, $cols, $values, $action='INSERT') 
    {
        if(!is_array($cols) || !is_array($values)) {
            $this->errorInfo = "$action parameters error.";
            return false;
        }
        
        if(is_array($values[0])) {
            foreach($values as $value) {
                if(count($cols) != count($value)) {
                    $this->errorInfo = "$action parameters mismatch.";
                    return false;
                }
            }
        } else if(count($cols) != count($values)) {
            $this->errorInfo = "$action parameters mismatch.";
            return false;
        }
        
        $collist = implode(',', $cols);
        $colnum = count($cols);
        $vals = array_fill(0, $colnum, '?');
        $vallist = implode(',', $vals);
        $sql = "$action INTO $rtindex ( $collist ) VALUES ( $vallist ) ";
        $stmt = $this->rtc->prepare($sql);
        if($stmt === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }

        if(is_array($values[0])) {
            foreach($values as $value) {
                foreach ($value as $k => $v) {
                    if(is_int($v))
                        $stmt->bindValue($k+1, $v, PDO::PARAM_INT);
                    else if(is_null($v))
                        $stmt->bindValue($k+1, '', PDO::PARAM_STR);
                    else
                        $stmt->bindValue($k+1, $v, PDO::PARAM_STR);
                }
                $result = $stmt->execute();
                if($result === false) break;
            }
        } else {
            foreach ($values as $k => $v) {
                if(is_int($v))
                    $stmt->bindValue($k+1, $v, PDO::PARAM_INT);
                else if(is_null($v))
                    $stmt->bindValue($k+1, '', PDO::PARAM_STR);
                else
                    $stmt->bindValue($k+1, $v, PDO::PARAM_STR);
            }
            $result = $stmt->execute();
        }
        
        if($result === false) {
            $e = $stmt->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }

        return true;
    }
    
    public function replace($rtindex, $cols, $values)
    {
        return $this->insert($rtindex, $cols, $values, 'REPLACE');
    }
    
    // $id: 需要删除的文档id，可以是单个id，可以是多个id(数组类型)
    public function delete($rtindex, $id)
    {
        if(is_array($id)) {
            $idlist = implode(',', $id);
            $sql = "DELETE FROM $rtindex WHERE id IN ({$idlist})";
        } else {
            $sql = "DELETE FROM $rtindex WHERE id = $id";
        }
        
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return $result;
    }
    
    // 更新实时索引或硬盘索引、分布式索引（包括local、remote agent）的属性
    // $attr: 可以是数组(col=>newval,...)或字符串形式(col1 = newval1 [, ...])
    public function update($index, $attr, $id='', $where='')
    {
        $attrs = '';
        if(is_array($attr)) {
            foreach ($attr as $col => $newval) {
                $attrs .= "$col = $newval,";
            }
            $attrs = rtrim($attrs,',');
        } else {
            $attrs = $attr;
        }
        
        if(is_array($id)) {
            $idlist = implode(',', $id);
            $sql = "UPDATE $index SET $attrs WHERE id IN ({$idlist}) OPTION ignore_nonexistent_columns = 1";
        } else if($id !== '') {
            $sql = "UPDATE $index SET $attrs WHERE id = $id OPTION ignore_nonexistent_columns = 1";
        } else if($where !== '') {
            $sql = "UPDATE $index SET $attrs WHERE $where OPTION ignore_nonexistent_columns = 1";
        } else {
            $this->errorInfo = "id and where is empty for update attribute";
            return false;
        }
        
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return $result;
    }
    
    private function doAction($index, $action, $id='', $where='')
    {
        if(is_array($id)) {
            $idlist = implode(',', $id);
            if($action == 'remove')
                $sql = "UPDATE $index SET isdeleted = 1 WHERE id IN ({$idlist})";
            else if($action == 'unremove')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE id IN ({$idlist}) AND isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $index SET isdeleted = 2 WHERE id IN ({$idlist}) AND isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE id IN ({$idlist}) AND isdeleted = 2";
        } else if($id !== '') {
            if($action == 'remove')
                $sql = "UPDATE $index SET isdeleted = 1 WHERE id = $id";
            else if($action == 'unremove')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE id = $id AND isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $index SET isdeleted = 2 WHERE id = $id AND isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE id = $id AND isdeleted = 2";
        } else if($where !== '') {
            if($action == 'remove')
                $sql = "UPDATE $index SET isdeleted = 1 WHERE $where";
            else if($action == 'unremove')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE $where AND isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $index SET isdeleted = 2 WHERE $where AND isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $index SET isdeleted = 0 WHERE $where AND isdeleted = 2";
        } else {
            $this->errorInfo = "id and where is empty for $action";
            return false;
        }
        
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return $result;
    }

    // 给硬盘索引、实时索引、分布式索引打上真正删除标记。 支持单个、批量、按查询条件删除。
    public function remove($index, $id='', $where='')
    {
       return $this->doAction($index, 'remove', $id, $where);
    }
    
    public function unremove($index, $id='', $where='')
    {
        return $this->doAction($index, 'unremove', $id, $where);
    }
    
    // 给硬盘索引、实时索引、分布式索引打上暂时删除标记、可以恢复。 支持单个、批量、按查询条件删除。
    public function softdelete($index, $id='', $where='')
    {
        return $this->doAction($index, 'softdelete', $id, $where);
    }
    
    public function recovery($index, $id='', $where='')
    {
        return $this->doAction($index, 'recovery', $id, $where);
    }
    
    // 清空实时索引 
    public function truncate($rtindex)
    {
        $sql = "TRUNCATE RTINDEX $rtindex";
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return true;
    }
    
    // 刷新实时索引
    public function flush($rtindex)
    {
        $sql = "FLUSH RTINDEX $rtindex";
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return true;
    }
    
    // 把硬盘索引加载为实时索引
    public function attach($diskindex, $rtindex)
    {
        $sql = "ATTACH INDEX $diskindex TO RTINDEX $rtindex";
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return true;
    }
    
    // 优化实时索引
    public function optimize($rtindex)
    {
        $sql = "OPTIMIZE INDEX $rtindex";
        $result = $this->rtc->exec($sql);
        if($result === false) {
            $e = $this->rtc->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return true;
    }
    
    // 对于分布式索引，需要连接每一个节点进行刷新。
    // $servers格式为: "host1:port,host2:port,..."
    public static function flushAttrs($servers)
    {
        $serverlist = explode(',', $servers);
        foreach($serverlist as $server) {
            $server = trim($server);
            $s = explode(':', $server);
            $cl = new SphinxClient();
            $cl->SetServer($s[0],$s[1]);
            $cl->SetConnectTimeout(2);
            $status = $cl->FlushAttributes();
            if($status < 0) 
                return false;
        }
        
        return true;
    }
}

?>
