<?php

require_once 'convertor.php';
date_default_timezone_set('Asia/Chongqing');

class member_es extends Convertor
{
    
    private $args;
    
    public function __construct($dataType, $gatherMode, $args) 
    {
        parent::__construct($dataType, $gatherMode);
        
        if(empty($args)) 
            throw new Exception ('convert arguments is empty');
        
        $this->args = $args;
    }
    
    public function __destruct() 
    {
        unset($this->record);
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
    
    public function isdeleted($value)
    {
        if(isset($this->record['isForbidden']) && $this->record['isForbidden'] == 0 && isset($this->record['isDelete']) && $this->record['isDelete'] == 0) {
            return 0;
        } else {
            return 1;
        }
    }
    
    
}

?>