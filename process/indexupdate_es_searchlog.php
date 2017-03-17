<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_searchlog
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
            'id',
            'keyword',
            'insertTime'
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //keyword
        $msg['keyword'] = $this->fan2jian($msg['keyword']);
        
        //_keyword
        $msg['_keyword'] = $msg['keyword'];
        
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
    
    public function custominsert($indexconfig, $msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $insertData = $this->deal($msg);
        if($insertData === false) {
            $this->errorInfo = $this->getErrorInfo();
            return false;
        }
        $server = ElasticSearchModel::getServer($indexconfig['servers']);
        $searchHasResult = ElasticSearchModel::getDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $insertData['id']);
        $count = 0;
        $isdeleted = 0;
        if(!empty($searchHasResult) && isset($searchHasResult['found']) && $searchHasResult['found'] == 'true' && isset($searchHasResult['_source']) && isset($searchHasResult['_source']['count']) && isset($searchHasResult['_source']['isdeleted'])) {
            $count = $searchHasResult['_source']['count'];
            $isdeleted = $searchHasResult['_source']['isdeleted'];
        }
        $insertData['count'] = $count + 1;
        $insertData['isdeleted'] = $isdeleted;
        $result = ElasticSearchModel::indexDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $insertData, $insertData['id']);
        if(!$result || !isset($result['created'])) {
            $this->errorInfo = "[ERROR]: ". var_export($result, true);
            return false;
        }
        
        return true;
    }
}
