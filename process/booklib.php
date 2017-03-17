<?php

require_once 'convertor.php';

date_default_timezone_set('Asia/Chongqing');

class booklib extends Convertor
{
    private $cache;
    private $expire;
    private $booklibPDO;

    public function __construct($dataType, $gatherMode, $args) 
    {
        parent::__construct($dataType, $gatherMode);
        $this->cache = NULL;
        
        if(empty($args)) 
            throw new Exception ('convert arguments is empty');
        
        if(isset($args['DB.booklib']) && !empty($args['DB.booklib']))
            $booklibDB = explode(':', $args['DB.booklib']);
        else 
            throw new Exception ('DB.booklib set error in [convert]');
        
        if(isset($args['cache']) && !empty($args['cache']))
            $cache = explode(':', $args['cache']);
        else 
            throw new Exception ('cache set error in [convert]');
        
        // 连接booklib DB，采用持久连接减少连接数。
        try {
            $dsn = 'mysql:' . 'host=' . $booklibDB[0] . ';' . 'port=' . $booklibDB[1] . ';' . 'dbname=' . $booklibDB[4] . ';' . 'charset=utf8';
            if($this->gatherMode == 0) { // rebuild mode 
                $this->booklibPDO = new PDO($dsn, $booklibDB[2], $booklibDB[3], array(PDO::ATTR_PERSISTENT => false));
                $this->booklibPDO->query("SET SESSION wait_timeout=28800");
            } else { // update mode
                $this->booklibPDO = new PDO($dsn, $booklibDB[2], $booklibDB[3], array(PDO::ATTR_PERSISTENT => true));
            }
            $this->booklibPDO->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            throw new Exception($this->errorInfo);
        }
        
        // 连接redis cache
        $this->cache = new Redis();
        $conn = $this->cache->pconnect($cache[0], $cache[1]);
        if($conn === false) {
            $this->cache = NULL;
            $this->errorInfo = "connect cache server [{$cache[0]}:{$cache[1]}] failure.";
            throw new Exception($this->errorInfo);
        }
        $this->expire = $cache[2];
        
        
    }
    
    public function __destruct() 
    {
        if($this->cache !== NULL) {
            $this->cache->close();
        }
 
        if($this->gatherMode == 0) { // rebuild mode
            $this->booklibPDO = NULL;
        }
        
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
    
    public function bookId($value)
    {
        $this->record['bookId'] = $value;
        $getBooksDescResult = $this->getBooksDesc();
        if ($getBooksDescResult === false && $this->record['booksDesc'] === -2) {
            return false;
        }
        
        $getBooksExtendsInfoResult = $this->getBooksExtendsInfo();
        if ($getBooksExtendsInfoResult === false && $this->record['booksExtendsInfo'] === -1) {
            return array();
        } else if ($getBooksExtendsInfoResult === false && $this->record['booksExtendsInfo'] === -2) {
            return false;
        }
        
        $getBooksPicResult = $this->getBooksPic();
        if ($getBooksPicResult === false && $this->record['booksPic'] === -2) {
            return false;
        }
        
        $getBookAuthorIdResult = $this->getBookAuthorId();
        if($getBookAuthorIdResult === false && $this->record['authorId'] === -2) {
            return false;
        }
        
        if($this->record['authorId'] > 0) {
            $getAuthorInfoResult = $this->getAuthorInfo();
            if($getAuthorInfoResult == false && $this->record['authorInfo'] === -2) {
                return false;
            }
        } else {
            $this->record['authorInfo'] = array();
        }
        
        if ($this->record['authorId'] > 0) {
            $getAuthorsDescResult = $this->getAuthorsDesc();
            if ($getAuthorsDescResult === false && $this->record['authorsDesc'] === -2) {
                return false;
            }
        } else {
            $this->record['authorsDesc'] = array();
        }
        
        if ($this->record['authorId'] > 0) {
            $getBookjobIdResult = $this->getBookjobId();
            if ($getBookjobIdResult === false && $this->record['jobId'] === -2) {
                return false;
            }
        } else {
            $this->record['jobId'] = 0;
        }
        
        if (isset($this->record['jobId']) && $this->record['jobId'] > 0) {
            $getBookjobNameResult = $this->getJobName();
            if ($getBookjobNameResult === false && $this->record['jobName'] === -2) {
                return false;
            }
        }
        
        if(isset($this->record['authorIds']) && $this->record['authorIds']) {
            $getAuthorNamesResult = $this->getAuthorNames();
            if($getAuthorNamesResult === false && $this->record['authorNames'] === -2) {
                return false;
            }
        }
        
        if(isset($this->record['jobIds']) && $this->record['jobIds']) {
            $getJobNamesResult = $this->getJobNames();
            if($getJobNamesResult === false && $this->record['jobNames'] === -2) {
                return false;
            }
        }
        
        $getBookPressIdResult = $this->getBookPressId();
        if($getBookPressIdResult === false && $this->record['pressId'] === -2) {
            return false;
        }
        
        if($this->record['pressId'] > 0) {
            $getPressInfoResult = $this->getPressInfo();
            if($getPressInfoResult == false && $this->record['pressInfo'] === -2) {
                return false;
            }
        } else {
            $this->record['pressInfo'] = array();
        }
        
        return $value;
    }
    
    private function getBooksDesc()
    {
        $sql = "SELECT * FROM booksDesc WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['booksDesc'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['booksDesc'] = array();
        } else {
            $this->record['booksDesc'] = $resultset[0];
        }
    }
    
    private function getBooksExtendsInfo()
    {
        $sql = "SELECT * FROM booksExtendsInfo WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['booksExtendsInfo'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['booksExtendsInfo'] = -1;
            return false;
        }
            
        $this->record['booksExtendsInfo'] = $resultset[0];
    }
    
    private function getBooksPic()
    {
        $sql = "SELECT * FROM booksPic WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['booksPic'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['booksPic'] = array();
        } else {
            $this->record['booksPic'] = $resultset[0];
        }
    }
    
    private function getBookAuthorId()
    {
        $sql = "SELECT authorId FROM authorsBooks WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['authorId'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['authorId'] = 0;
            $this->record['authorIds'] = '';
        } else {
            $this->record['authorIds'] = '';
            foreach($resultset as $r) {
                $this->record['authorIds'] .= ','. $r['authorId'];
            }
            $this->record['authorIds'] = trim($this->record['authorIds'], ',');
            $this->record['authorId'] = $resultset[0]['authorId'];
        }
    }
    
    private function getAuthorInfo()
    {
        $sql = "SELECT authorId,authorName,authorNamePinyin,authorUrl FROM authors WHERE authorId='". $this->record['authorId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['authorInfo'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['authorInfo'] = array();
        } else {
            $this->record['authorInfo'] = $resultset[0];
        }
    }
    
    private function getBookPressId()
    {
        $sql = "SELECT pressId FROM pressBooks WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['pressId'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['pressId'] = 0;
        } else {
            $this->record['pressId'] = $resultset[0]['pressId'];
        }
    }
    
    private function getPressInfo()
    {
        $sql = "SELECT pressId,pressName,pressUrl FROM press WHERE pressId='". $this->record['pressId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['pressInfo'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['pressInfo'] = array();
        } else {
            $this->record['pressInfo'] = $resultset[0];
        }
    }
    
    private function getAuthorsDesc()
    {
        $sql = "SELECT authorId,image,lifeStory FROM authorsDesc WHERE authorId='". $this->record['authorId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['authorsDesc'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['authorsDesc'] = array();
        } else {
            $this->record['authorsDesc'] = $resultset[0];
        }
    }
    
    private function getBookjobId()
    {
        $sql = "SELECT authorId FROM authorsBooks WHERE bookId='". $this->record['bookId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['jobId'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['jobId'] = 0;
            $this->record['jobIds'] = '';
        } else {
            $this->record['jobIds'] = '';
            foreach($resultset as $r) {
                $this->record['jobIds'] .= ','. $r['jobId'];
            }
            $this->record['jobIds'] = trim($this->record['jobIds'], ',');
            $this->record['jobId'] = $resultset[0]['jobId'];
        }
    }
    
    private function getJobName()
    {
        $sql = "SELECT jobName FROM job WHERE jobId='". $this->record['jobId']. "'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['jobName'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['jobName'] = '';
        } else {
            $this->record['jobName'] = $resultset[0]['jobName'];
        }
    }
    
    private function getAuthorNames()
    {
        $sql = "SELECT authorName FROM authors WHERE authorId IN (". $this->record['authorIds']. ")";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['authorNames'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        $this->record['authorNames'] = '';
        if(!$resultset) {
            foreach($resultset as $r) {
                $this->record['authorNames'] .= '|'. $r['authorName'];
            }
            $this->record['authorNames'] = trim($this->record['authorNames'], '|');
        }
    }
    
    private function getJobNames()
    {
        $sql = "SELECT jobName FROM job WHERE jobId IN (". $this->record['jobIds']. ")";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            $this->record['jobNames'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        $this->record['jobNames'] = '';
        if(!$resultset) {
            foreach($resultset as $r) {
                $this->record['jobNames'] .= '|'. $r['jobName'];
            }
            $this->record['jobNames'] = trim($this->record['jobNames'], '|');
        }
    }


    public function bookName($value)
    {
        $this->record['bookName'] = $value;
        return $value;
    }
    
    public function _bookName($value)
    {
        return $this->record['bookName'];
    }
    
    public function catName($value)
    {
        $this->record['catName'] = $value;
        return $value;
    }
    
    public function jcatId1($value)
    {
        if(!$this->record['catName']) {
            return 0;
        }
        if(preg_match('/[a-z0-9]/is', mb_substr($this->record['catName'], 0, 1, 'UTF-8'))) {
            return 0;
        }
        $catArr = explode('/', $this->record['catName']);
        if(count($catArr) < 2) {
            return 0;
        }
        $catArr_num = count($catArr);
        $catName = addslashes(preg_replace('/_/is', '/', $catArr[$catArr_num - 1]));
        $sql = "SELECT jcatId,jcatName,lev1,lev2,level FROM jcat WHERE jcatName='$catName'";
        $result = $this->booklibPDO->query($sql);
        if ($result === false) {
            $e = $this->booklibPDO->errorInfo();
            $this->booklibPDO = $e[2];
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['jcatId2'] = 0;
            return 0;
        } else {
            $this->record['jcatId2'] = $resultset[0]['lev2'];
            return $resultset[0]['lev1'];
        }
    }
    
    public function jcatId2($value)
    {
        return isset($this->record['jcatId2']) ? $this->record['jcatId2'] : 0;
    }
    
    public function certifyStatus($value)
    {
        switch($value) {
            case 'notCertified':
                return 0;
            case 'certified':
                return 1;
            case 'failed':
                return 2;
        }
    }
    
    public function _catName($value)
    {
        return $this->record['catName'];
    }
    
    public function author($value)
    {
        $this->record['author'] = $value;
        return $value;
    }
    
    public function _author($value)
    {
        return $this->record['author'];
    }
    
    public function press($value)
    {
        $this->record['press'] = $value;
        return $value;
    }
    
    public function _press($value)
    {
        return $this->record['press'];
    }
    
    public function pubDate($value)
    {
        $this->record['pubDate'] = $value;
        return $value;
    }
    
    public function _pubDate($value)
    {
        return $this->record['pubDate'];
    }
    
    public function isbn($value)
    {
        $this->record['isbn'] = $value;
        return $value;
    }
    
    public function _isbn($value)
    {
        return $this->record['isbn'];
    }
    
    public function tag($value)
    {
        $this->record['tag'] = $value;
        return $value;
    }
    
    public function _tag($value)
    {
        return $this->record['tag'];
    }
    
    public function jobName($value)
    {
        return isset($this->record['jobName']) ? $this->record['jobName'] : '';
    }
    
    public function _jobName($value)
    {
        return isset($this->record['jobName']) ? $this->record['jobName'] : '';
    }
    
    public function authorIds($value)
    {
        return isset($this->record['authorIds']) ? $this->record['authorIds'] : '';
    }
    
    public function _authorIds($value)
    {
        return isset($this->record['authorIds']) ? $this->record['authorIds'] : '';
    }
    
    public function authorNames($value)
    {
        return isset($this->record['authorNames']) ? $this->record['authorNames'] : '';
    }
    
    public function _authorNames($value)
    {
        return isset($this->record['authorNames']) ? $this->record['authorNames'] : '';
    }
    
    public function jobIds($value)
    {
        return isset($this->record['jobIds']) ? $this->record['jobIds'] : '';
    }
    
    public function _jobIds($value)
    {
        return isset($this->record['jobIds']) ? $this->record['jobIds'] : '';
    }
    
    public function jobNames($value)
    {
        return isset($this->record['jobNames']) ? $this->record['jobNames'] : '';
    }
    
    public function _jobNames($value)
    {
        return isset($this->record['jobNames']) ? $this->record['jobNames'] : '';
    }
    
    public function editorComment($value)
    {
        return isset($this->record['booksDesc']['editorComment']) ? $this->record['booksDesc']['editorComment'] : '';
    }
    
    public function contentIntroduction($value)
    {
        return isset($this->record['booksDesc']['contentIntroduction']) ? $this->record['booksDesc']['contentIntroduction'] : '';
    }
    
    public function directory($value)
    {
        return isset($this->record['booksDesc']['directory']) ? $this->record['booksDesc']['directory'] : '';
    }
    
    public function Illustration($value)
    {
        return isset($this->record['booksDesc']['Illustration']) ? $this->record['booksDesc']['Illustration'] : '';
    }
    
    public function description($value)
    {
        return isset($this->record['booksDesc']['description']) ? $this->record['booksDesc']['description'] : '';
    }
    
    public function bookForeign($value)
    {
        return $this->record['booksExtendsInfo']['bookForeign'] ? $this->record['booksExtendsInfo']['bookForeign'] : '';
    }
    
    public function area($value)
    {
        return $this->record['booksExtendsInfo']['area'] ? $this->record['booksExtendsInfo']['area'] : '';
    }
    
    public function language($value)
    {
        return $this->record['booksExtendsInfo']['language'] ? $this->record['booksExtendsInfo']['language'] : '';
    }
    
    public function originalLanguage($value)
    {
        return $this->record['booksExtendsInfo']['originalLanguage'] ? $this->record['booksExtendsInfo']['originalLanguage'] : '';
    }
    
    public function catAgency($value)
    {
        return $this->record['booksExtendsInfo']['catAgency'] ? $this->record['booksExtendsInfo']['catAgency'] : '';
    }
    
    public function wordNum($value)
    {
        return $this->record['booksExtendsInfo']['wordNum'] ? $this->record['booksExtendsInfo']['wordNum'] : '';
    }
    
    public function pageNum($value)
    {
        return $this->record['booksExtendsInfo']['pageNum'] ? $this->record['booksExtendsInfo']['pageNum'] : '';
    }
    
    public function printingNum($value)
    {
        return $this->record['booksExtendsInfo']['printingNum'] ? $this->record['booksExtendsInfo']['printingNum'] : '';
    }
    
    public function printingTime($value)
    {
        return $this->record['booksExtendsInfo']['printingTime'] ? $this->record['booksExtendsInfo']['printingTime'] : '';
    }
    
    public function pageSize($value)
    {
        return $this->record['booksExtendsInfo']['pageSize'] ? $this->record['booksExtendsInfo']['pageSize'] : '';
    }
    
    public function setNum($value)
    {
        return $this->record['booksExtendsInfo']['setNum'] ? $this->record['booksExtendsInfo']['setNum'] : '';
    }
    
    public function impression($value)
    {
        return $this->record['booksExtendsInfo']['impression'] ? $this->record['booksExtendsInfo']['impression'] : '';
    }
    
    public function usedPaper($value)
    {
        return $this->record['booksExtendsInfo']['usedPaper'] ? $this->record['booksExtendsInfo']['usedPaper'] : '';
    }
    
    public function issn($value)
    {
        return $this->record['booksExtendsInfo']['issn'] ? $this->record['booksExtendsInfo']['issn'] : '';
    }
    
    public function unifiedIsbn($value)
    {
        return $this->record['booksExtendsInfo']['unifiedIsbn'] ? $this->record['booksExtendsInfo']['unifiedIsbn'] : '';
    }
    
    public function binding($value)
    {
        return $this->record['booksExtendsInfo']['binding'] ? $this->record['booksExtendsInfo']['binding'] : '';
    }
    
    public function series($value)
    {
        return $this->record['booksExtendsInfo']['series'] ? $this->record['booksExtendsInfo']['series'] : '';
    }
    
    public function bookSize($value)
    {
        return $this->record['booksExtendsInfo']['bookSize'] ? $this->record['booksExtendsInfo']['bookSize'] : '';
    }
    
    public function bookWeight($value)
    {
        return $this->record['booksExtendsInfo']['bookWeight'] ? $this->record['booksExtendsInfo']['bookWeight'] : '';
    }
    
    public function normalImg($value)
    {
        return isset($this->record['booksPic']['normalImg']) ? $this->record['booksPic']['normalImg'] : '';
    }
    
    public function smallImg($value)
    {
        return isset($this->record['booksPic']['smallImg']) ? $this->record['booksPic']['smallImg'] : '';
    }
    
    public function bigImg($value)
    {
        return isset($this->record['booksPic']['bigImg']) ? $this->record['booksPic']['bigImg'] : '';
    }
    
    public function authorId($value)
    {
        return $this->record['authorId'];
    }
    
    public function authorName($value)
    {
        return isset($this->record['authorInfo']['authorName']) ? $this->record['authorInfo']['authorName'] : '';
    }
    
    public function _authorName($value)
    {
        return isset($this->record['authorInfo']['authorName']) ? $this->record['authorInfo']['authorName'] : '';
    }
    
    public function authorNamePinyin($value)
    {
        return isset($this->record['authorInfo']['authorNamePinyin']) ? $this->record['authorInfo']['authorNamePinyin'] : '';
    }
    
    public function authorUrl($value)
    {
        return isset($this->record['authorInfo']['authorUrl']) ? $this->record['authorInfo']['authorUrl'] : '';
    }
    
    public function pressId($value)
    {
        return $this->record['pressId'];
    }
    
    public function pressName($value)
    {
        return isset($this->record['pressInfo']['pressName']) ? $this->record['pressInfo']['pressName'] : '';
    }
    
    public function _pressName($value) 
    {
        return isset($this->record['pressInfo']['pressName']) ? $this->record['pressInfo']['pressName'] : '';
    }
    
    public function pressUrl($value)
    {
        return isset($this->record['pressInfo']['pressUrl']) ? $this->record['pressInfo']['pressUrl'] : '';
    }
    
    public function lifeStory($value)
    {
        return isset($this->record['authorsDesc']['lifeStory']) ? $this->record['authorsDesc']['lifeStory'] : '';
    }
    
    public function authorPhoto($value)
    {
        return isset($this->record['authorsDesc']['image']) ? $this->record['authorsDesc']['image'] : '';
    }
    
    public function jobId($value)
    {
        return isset($this->record['jobId']) ? $this->record['jobId'] : 0;
    }
    
    
}
