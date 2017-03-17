<?php

require_once 'convertor.php';
date_default_timezone_set('Asia/Chongqing');

class message_es extends Convertor
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
    
    public function sendTime($value) 
    {
        if($value) {
            return strtotime($value);
        } else {
            return 0;
        }
    }

    public function contentId($value)
    {
        if(isset($this->record['msgContent']) && !empty($this->record['msgContent'])) {
            $preg = '/[\x{4e00}-\x{9fa5}a-z0-9,.。，（(）)：:]+/iu';
            preg_match_all($preg, $this->record['msgContent'], $result);
            $works = isset($result[0]) ? $result[0] : array();
            return md5(implode('', $works));
        } else {
            return '';
        }
        
    }
}

?>