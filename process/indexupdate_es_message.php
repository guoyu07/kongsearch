<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_message
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
    
    public function contentId($msgContent)
    {
        if(!empty($msgContent)) {
            $preg = '/[\x{4e00}-\x{9fa5}a-z0-9,.。，（(）)：:]+/iu';
            preg_match_all($preg, $msgContent, $result);
            $works = isset($result[0]) ? $result[0] : array();
            return md5(implode('', $works));
        } else {
            return '';
        }
        
    }
    
    public function sendTime($value) 
    {
        if($value) {
            return strtotime($value);
        } else {
            return 0;
        }
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
            'messageId',
            'catId',
            'sender',
            'senderNickname',
            'receiver',
            'receiverNickname',
            'msgContent',
            'sendTime'
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //contentId
        $msg['contentId'] = $this->contentId($msg['msgContent']);
        
        //isdeleted
        $msg['isdeleted'] = 0;
        
        //senderNickname
        $msg['senderNickname'] = $this->fan2jian($msg['senderNickname']);
        
        //_senderNickname
        $msg['_senderNickname'] = $msg['senderNickname'];
        
        //receiverNickname
        $msg['receiverNickname'] = $this->fan2jian($msg['receiverNickname']);
        
        //_receiverNickname
        $msg['_receiverNickname'] = $msg['receiverNickname'];
        
        //msgContent
        $msg['msgContent'] = $this->fan2jian($msg['msgContent']);
        
        //_msgContent
        $msg['_msgContent'] = $msg['msgContent'];
        
        //sendTime
        $msg['sendTime'] = $this->sendTime($msg['sendTime']);
        
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
        
        //contentId
        if(isset($msg['msgContent']) && $msg['msgContent']) {
            $msg['contentId'] = $this->contentId($msg['msgContent']);
        }
        
        //senderNickname
        if(isset($msg['senderNickname']) && $msg['senderNickname']) {
            $msg['senderNickname'] = $this->fan2jian($msg['senderNickname']);
        }
        
        //_senderNickname
        if(isset($msg['senderNickname']) && $msg['senderNickname']) {
            $msg['_senderNickname'] = $msg['senderNickname'];
        }
        
        //receiverNickname
        if(isset($msg['receiverNickname']) && $msg['receiverNickname']) {
            $msg['receiverNickname'] = $this->fan2jian($msg['receiverNickname']);
        }
        
        //_receiverNickname
        if(isset($msg['receiverNickname']) && $msg['receiverNickname']) {
            $msg['_receiverNickname'] = $msg['receiverNickname'];
        }
        
        //msgContent
        if(isset($msg['msgContent']) && $msg['msgContent']) {
            $msg['msgContent'] = $this->fan2jian($msg['msgContent']);
        }
        
        //_msgContent
        if(isset($msg['msgContent']) && $msg['msgContent']) {
            $msg['_msgContent'] = $msg['msgContent'];
        }
        
        //sendTime
        if(isset($msg['sendTime']) && $msg['sendTime']) {
            $msg['sendTime'] = $this->sendTime($msg['sendTime']);
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
