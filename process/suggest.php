<?php

require_once 'convertor.php';
require_once dirname(__FILE__) . '/../lib' . '/pinyin.php';
date_default_timezone_set('Asia/Chongqing');

class suggest extends Convertor
{
    
    private $pmPDO;
    private $cache;
    private $expire;
    private $host;
    private $port;
    private $dbUser;
    private $dbPwd;
    private $name;
    private $args;
    
    public function __construct($dataType, $gatherMode, $args) 
    {
        parent::__construct($dataType, $gatherMode);
        $this->cache = NULL;
        
        if(empty($args)) 
            throw new Exception ('convert arguments is empty');
        
        $this->args = $args;
        
        $this->dbUser = '';
        $this->dbPwd = ''; 
        $this->host = '';
        $this->port = '';
        $this->name = '';
        if(isset($args['DB.user']) && !empty($args['DB.user']))
            $this->dbUser = $args['DB.user'];
        if(isset($args['DB.password']) && !empty($args['DB.password']))
            $this->dbPwd = $args['DB.password'];
        if(isset($args['DB.host']) && !empty($args['DB.host']))
            $this->host = $args['DB.host'];
        if(isset($args['DB.port']) && !empty($args['DB.port']))
            $this->port = $args['DB.port'];
        if(isset($args['DB.name']) && !empty($args['DB.name']))
            $this->name = $args['DB.name'];
        // 连接DB，采用持久连接减少连接数。
//        try {
//            $dsn = 'mysql:' . 'host=' . $this->host . ';' . 'port=' . $this->port . ';' . 'dbname=' . $this->name . ';' . 'charset=utf8';
//            if($this->gatherMode == 0) { // rebuild mode 
//                $this->pmPDO = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => false));
//                $this->pmPDO->query("SET SESSION wait_timeout=28800");
//            } else { // update mode
//                $this->pmPDO = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => true));
//            }
//            $this->pmPDO->query("SET NAMES utf8");
//        } catch (PDOException $e) {
//            $this->errorInfo = $e->getMessage();
//            throw new Exception($this->errorInfo);
//        }
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


    /**
     * 汉字转拼音
     */
    public function pinyin()
    {
        $word = isset($this->record['word']) ? $this->record['word'] : '';
        // file_put_contents('/tmp/tmplog.log', $word);
        return pinyin($word);
    }
    
    /**
     * 汉字转拼音
     */
    public function py_word($value)
    {
        $word = isset($this->record['word']) ? $this->record['word'] : '';
        // file_put_contents('/tmp/tmplog.log', $word);
        return pinyin($word);
    }

    /**
     * 是否删除的标志
     */
    public function isdeleted()
    {
        return 0;
    }
}

?>