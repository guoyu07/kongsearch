<?php

class DAO {
    private $pdo;
    private $dsn;
    private $user;
    private $password;
    private $errorInfo;

    public function __construct($dsn)  
    {
        $this->dsn = 'mysql: charset=utf8;';
        $this->dsn .=  ('host=' . $dsn['host'] . ';' );
        
        if(!empty($dsn['port']))
            $this->dsn .=  ('port=' .  $dsn['port'] . ';' );
        else
            $this->dsn .=  ('port=' . '3306' . ';' );
        
        if(!empty($dsn['db']))
            $this->dsn .=  ('dbname=' . $dsn['db'] . ';' );
        
        $this->user = $dsn['user'];
        $this->password = $dsn['password'];
        $this->errorInfo = '';
    }
    
    // 和数据库建立连接或持久连接，$waitTimeout=0表示不设置，MySQL默认为28800s
    public function connect($isPersistent=false, $waitTimeout=0)
    {
        $connectNum = 2; //连接失败后再重连一次，最多两次。
        do {
            try {
                if($isPersistent)
                    $this->pdo = new PDO($this->dsn, $this->user, $this->password, array(PDO::ATTR_PERSISTENT => true));
                else
                    $this->pdo = new PDO($this->dsn, $this->user, $this->password, array(PDO::ATTR_PERSISTENT => false));
                
                //$this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION); 取消，避免抛出异常
                $this->pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false); 
                $this->pdo->query("SET NAMES utf8");
                $this->pdo->query("SET SESSION query_cache_type=OFF");
                if($waitTimeout > 0) {
                    $this->pdo->query("SET SESSION wait_timeout={$waitTimeout}");
                }
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
    
    private function ping()
    {
        $serverInfo = $this->pdo->getAttribute(PDO::ATTR_SERVER_INFO);
        if ($serverInfo == 'MySQL server has gone away') {
            return $this->connect();
        } 
        return false;
    }
    
    private function query($sql)
    {
        $result = $this->pdo->query($sql);
        if($result === false) {
            if($this->ping()) {
                $result = $this->pdo->query($sql);
                if($result !== false)
                    return $result;
            }
            $e = $this->pdo->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return $result;
    }
    
    private function exec($sql)
    {
        $result = $this->pdo->exec($sql);
        if($result === false) {
            if($this->ping()) {
                $result = $this->pdo->exec($sql);
                if($result !== false)
                    return $result;
            }
            $e = $this->pdo->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
        
        return $result;
    }

    public function disconnect() {
        $this->pdo = NULL;
    }
    
    public function getErrorInfo()
    {
        return $this->errorInfo;
    }
    
    // $values可以是一维数组，也可以是二维数组（批量插入）
    public function insert($table, $cols, $values, $action='INSERT') 
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
        $sql = "$action INTO $table ( $collist ) VALUES ( $vallist ) ";
        $stmt = $this->pdo->prepare($sql);
        if($stmt === false) {
            $e = $this->pdo->errorInfo();
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

        return $result;
    }
    
    public function replace($table, $cols, $values)
    {
        return $this->insert($table, $cols, $values, 'REPLACE');
    }
    
    // $id: 需要删除的文档id，可以是单个id，可以是多个id(数组类型)
    public function delete($table, $id, $where='', $idcol='id')
    {
        if(is_array($id)) {
            $idlist = implode(',', $id);
            $sql = "DELETE FROM $table WHERE $idcol IN ({$idlist})";
        } else if($id !== '') {
            $sql = "DELETE FROM $table WHERE $idcol = $id";
        } else if($where !== ''){
            $sql = "DELETE FROM $table WHERE $where";
        } else {
            $this->errorInfo = "id and where is empty for delete";
            return false;
        }
        
        $result = $this->exec($sql);
        return $result;
    }
    
    // $attr: 可以是数组(col=>newval,...)或字符串形式(col1 = newval1 [, ...])
    public function update($table, $attr, $id='', $where='', $idcol='id')
    {
        $attrs = '';
        if(is_array($attr)) {
            foreach($attr as $col => $newval) {
                $attrs .= "$col = $newval,";
            }
            $attrs = rtrim($attrs,',');
        } else {
            $attrs = $attr;
        }
        
        if(is_array($id)) {
            $idlist = implode(',', $id);
            $sql = "UPDATE $table SET $attrs WHERE $idcol IN ({$idlist})";
        } else if($id !== '') {
            $sql = "UPDATE $table SET $attrs WHERE $idcol = $id";
        } else if($where !== '') {
            $sql = "UPDATE $table SET $attrs WHERE $where";
        } else {
            $this->errorInfo = "id and where is empty for update";
            return false;
        }
        
        $result = $this->exec($sql);
        return $result;
    }
    
    private function doAction($table, $action, $id='', $where='', $idcol='id', $isdeleted='isdeleted')
    {
        if(is_array($id)) {
            $idlist = implode(',', $id);
            if($action == 'remove')
                $sql = "UPDATE $table SET $isdeleted = 1 WHERE $idcol IN ({$idlist})";
            else if($action == 'unremove')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $idcol IN ({$idlist}) AND $isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $table SET $isdeleted = 2 WHERE $idcol IN ({$idlist}) AND $isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $idcol IN ({$idlist}) AND $isdeleted = 2";
        } else if($id !== '') {
            if($action == 'remove')
                $sql = "UPDATE $table SET $isdeleted = 1 WHERE $idcol = $id";
            else if($action == 'unremove')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $idcol = $id AND $isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $table SET $isdeleted = 2 WHERE $idcol = $id AND $isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $idcol = $id AND $isdeleted = 2";
        } else if($where !== '') {
            if($action == 'remove')
                $sql = "UPDATE $table SET $isdeleted = 1 WHERE $where";
            else if($action == 'unremove')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $where AND $isdeleted = 1";
            else if($action == 'softdelete')
                $sql = "UPDATE $table SET $isdeleted = 2 WHERE $where AND $isdeleted = 0";
            else if($action == 'recovery')
                $sql = "UPDATE $table SET $isdeleted = 0 WHERE $where AND $isdeleted = 2";
        } else {
            $this->errorInfo = "id and where is empty for $action";
            return false;
        }
        
        $result = $this->exec($sql);
        return $result;
    }

    // 打上真正删除标记。 支持单个、批量、按查询条件删除。
    public function remove($table, $id='', $where='', $idcol='id', $isdeleted='isdeleted')
    {
       return $this->doAction($table, 'remove', $id, $where, $idcol, $isdeleted);
    }
    
    public function unremove($table, $id='', $where='', $idcol='id', $isdeleted='isdeleted')
    {
        return $this->doAction($table, 'unremove', $id, $where, $idcol, $isdeleted);
    }
    
    // 打上暂时删除标记、可以恢复。 支持单个、批量、按查询条件删除。
    public function softdelete($table, $id='', $where='', $idcol='id', $isdeleted='isdeleted')
    {
        return $this->doAction($table, 'softdelete', $id, $where, $idcol, $isdeleted);
    }
    
    public function recovery($table, $id='', $where='', $idcol='id', $isdeleted='isdeleted')
    {
        return $this->doAction($table, 'recovery', $id, $where, $idcol, $isdeleted);
    }
    
    // 清空表里所有记录
    public function truncate($table)
    {
        $sql = "TRUNCATE TABLE $table";
        $result = $this->exec($sql);
        return $result;
    }

    public function getIDRange($table, $id)
    {
        $IDRange = array();
        if(empty($table) || empty($id))
            return false;
        
        $sql = "SELECT MIN({$id}),MAX({$id}) FROM $table";
        $result = $this->query($sql);
        if($result === false) {
            return false;
        }
        
        foreach($result as $row) {
            $IDRange[0] = intval($row[0]);
            $IDRange[1] = intval($row[1]);
        }
        
        return $IDRange;
    }
     
    public function queryByRange($table, $id, $start, $end, $cols, $where='')
    {
        $collist = implode(',', $cols);
        $sql = "SELECT $collist FROM $table WHERE $id >= $start AND $id <= $end";
        if(!empty($where)) {
            $sql = $sql . ' AND ' . $where; 
        }
        
        $result = $this->query($sql);
        if($result === false) {
            return false;
        }
        
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC); // 结果集的字段值都是字符串
        return $resultset;
    }
    
    // $list可以是字符串或数组形式。
    public function queryByList($table, $id, $list, $cols, $where='')
    {
        $collist = implode(',', $cols);
        if(is_array($list)) {
            $lists = implode(',', $list);
            $sql = "SELECT $collist FROM $table WHERE $id IN ( $lists )";
        } else {
            $sql = "SELECT $collist FROM $table WHERE $id = $list";
        }
        if(!empty($where)) {
            $sql = $sql . ' AND ' . $where; 
        }
        
        $result = $this->query($sql);
        if($result === false) {
            return false;
        }
        
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC); // 结果集的字段值都是字符串
        return $resultset;
    }
    
    public function queryByFK($table, $fk, $fkv, $cols)
    {
        $collist = implode(',', $cols);
        $sql = "SELECT $collist FROM $table WHERE $fk = $fkv";
        $result = $this->query($sql);
        if($result === false) {
            return false;
        }
        
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) //返回的结果为空。
            return $resultset;
        else
            return $resultset[0]; 
    }
    
    public function queryByPK($table, $pk, $pkv, $cols) 
    {
        return queryByFK($table, $pk, $pkv, $cols);
    }
    
    public function prepareInsert($table, $cols, $action='INSERT')
    {
        $collist = implode(',', $cols);
        $colnum = count($cols);
        $vals = array_fill(0, $colnum, '?');
        $vallist = implode(',', $vals);
        $sql = "$action INTO $table ( $collist ) VALUES ( $vallist ) ";
        $stmt = $this->pdo->prepare($sql);
        if($stmt === false) {
            $e = $this->pdo->errorInfo();
            $this->errorInfo = $e[2];
            return false;
        }
       return $stmt;
    }
    
    public function executeInsert($stmt, $values)
    {
        $result = $stmt->execute($values); // $value里的字段值都是字符串，会自动转换为参数类型、数据库列类型。
        if($result === false) {
            $e = $stmt->errorInfo();
            $this->errorInfo = $e[2];
            if($e[1] === 1062) { //$e[1]=1062, $e[2] = "Duplicate entry '11' for key 'PRIMARY'"
                return 1062; // 主键重复。
            } else {
                return false;
            }
        }
        return true;
    }
    
    public function deleteByPK($table,$pk, $pkv) 
    {
        $sql = "DELETE FROM $table where $pk = $pkv";
        $result = $this->exec($sql);
        if($result === false) {
            return false;
        }
        return true;
    }
}


?>