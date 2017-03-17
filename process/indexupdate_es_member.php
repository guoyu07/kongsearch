<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_member
{
    private $errorInfo;
    private $record;
    
    public function __construct($config) 
    {
        $this->errorInfo = '';
        $this->record = array();
        
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
    
    /**
     * 处理insert、modify的数据
     */
    public function deal($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        $msgFields = array(
            'userId',
            'username',
            'nickname',
            'isForbidden',
            'isDelete'
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //isdeleted
        $msg['isdeleted'] = 0;
        
        //username
        $msg['username'] = $this->fan2jian($msg['username']);
        
        //_username
        $msg['_username'] = $msg['username'];
        
        //nickname
        $msg['nickname'] = $this->fan2jian($msg['nickname']);
        
        //_nickname
        $msg['_nickname'] = $msg['nickname'];
        
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
        
        //username
        if(isset($msg['username']) && $msg['username']) {
            $msg['username'] = $this->fan2jian($msg['username']);
        }
        
        //_username
        if(isset($msg['username']) && $msg['username']) {
            $msg['_username'] = $msg['username'];
        }
        
        //nickname
        if(isset($msg['nickname']) && $msg['nickname']) {
            $msg['nickname'] = $this->fan2jian($msg['nickname']);
        }
        
        //_nickname
        if(isset($msg['nickname']) && $msg['nickname']) {
            $msg['_nickname'] = $msg['nickname'];
        }
        
        //isdeleted
        if(isset($msg['isDelete']) && $msg['isDelete'] == 1) {
            $msg['isdeleted'] = 1;
        } else {
            $msg['isdeleted'] = 0;
        }
        
        //isForbidden
        if(isset($msg['isForbidden']) && $msg['isForbidden'] == 1) {
            $msg['isforbidden'] = 1;
        } else {
            $msg['isforbidden'] = 0;
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
}
