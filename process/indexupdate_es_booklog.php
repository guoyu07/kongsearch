<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_booklog
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
            'itemname', //图书名称
            'shopname', //书店名称
            'opname', //审核人姓名
            'shopid', //书店编号
            'userid', //卖家编号
            'nickname', //卖家昵称
            'itemid', //图书编号
            'biztype', //业务类型（全部0、书店1、书摊2）
            'op', //审核操作（全部0、通过1、驳回2、删除3、冻结4）
            'optype', //审核方式（全部0、人工1、自动2）
            'optime', //审核时间
            'match5', //五个比对项（自动）（全部0、ISBN+书名1、ISBN+作者2、ISBN+出版社3、出版社+书名4、书名+作者5）
            'distkey', //违禁关键词
            'comparedb', //比对库（自动）（全部0、可信任图书库1、违禁关键词库2、在售图书库3）
            'certifynum', //审核次数
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
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
    
    /**
     * 处理update的数据
     */
    public function dealUp($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        
        //itemname
        if(isset($msg['itemname']) && $msg['itemname']) {
            $msg['itemname'] = $msg['itemname'];
        }
        
        //shopname
        if(isset($msg['shopname']) && $msg['shopname']) {
            $msg['shopname'] = $msg['shopname'];
        }
        
        //opname
        if(isset($msg['opname']) && $msg['opname']) {
            $msg['opname'] = $msg['opname'];
        }
        
        //shopid
        if(isset($msg['shopid']) && $msg['shopid']) {
            $msg['shopid'] = $msg['shopid'];
        }
        
        //userid
        if(isset($msg['userid']) && $msg['userid']) {
            $msg['userid'] = $msg['userid'];
        }
        
        //nickname
        if(isset($msg['nickname']) && $msg['nickname']) {
            $msg['nickname'] = $msg['nickname'];
        }
        
        //itemid
        if(isset($msg['itemid']) && $msg['itemid']) {
            $msg['itemid'] = $msg['itemid'];
        }
        
        //biztype
        if(isset($msg['biztype']) && $msg['biztype']) {
            $msg['biztype'] = $msg['biztype'];
        }
        
        //op
        if(isset($msg['op']) && $msg['op']) {
            $msg['op'] = $msg['op'];
        }
        
        //optype
        if(isset($msg['optype']) && $msg['optype']) {
            $msg['optype'] = $msg['optype'];
        }
        
        //optime
        if(isset($msg['optime']) && $msg['optime']) {
            $msg['optime'] = $msg['optime'];
        }
        
        //match5
        if(isset($msg['match5']) && $msg['match5']) {
            $msg['match5'] = $msg['match5'];
        }
        
        //distkey
        if(isset($msg['distkey']) && $msg['distkey']) {
            $msg['distkey'] = $msg['distkey'];
        }
        
        //comparedb
        if(isset($msg['comparedb']) && $msg['comparedb']) {
            $msg['comparedb'] = $msg['comparedb'];
        }
        
        //certifynum
        if(isset($msg['certifynum']) && $msg['certifynum']) {
            $msg['certifynum'] = $msg['certifynum'];
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
