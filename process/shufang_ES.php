<?php
require_once 'convertor.php';

date_default_timezone_set('Asia/Chongqing');

/**
 * Created by PhpStorm.
 * User: diao
 * Date: 16-9-22
 * Time: 上午10:10
 */
class shufang_es extends Convertor
{
    private $cache;
    private $expire;
    private $shufangPDO;

    public function __construct($dataType, $gatherMode, $args)
    {
        parent::__construct($dataType, $gatherMode);
        $this->cache = NULL;
        $this->dataType = $dataType;
        if (empty($args))
            throw new Exception ('convert arguments is empty');

        if (isset($args['DB.study']) && !empty($args['DB.study']))
            $shufangDB = explode(':', $args['DB.study']);
        else
            throw new Exception ('DB.booklib set error in [convert]');

        if (isset($args['cache']) && !empty($args['cache']))
            $cache = explode(':', $args['cache']);
        else
            throw new Exception ('cache set error in [convert]');

        // 连接booklib DB，采用持久连接减少连接数。
        try {
            $dsn = 'mysql:' . 'host=' . $shufangDB[0] . ';' . 'port=' . $shufangDB[1] . ';' . 'dbname=' . $shufangDB[4] . ';' . 'charset=utf8';
            if ($this->gatherMode == 0) { // rebuild mode
                $this->shufangPDO = new PDO($dsn, $shufangDB[2], $shufangDB[3], array(PDO::ATTR_PERSISTENT => false));
                $this->shufangPDO->query("SET SESSION wait_timeout=28800");
            } else { // update mode
                $this->shufangPDO = new PDO($dsn, $shufangDB[2], $shufangDB[3], array(PDO::ATTR_PERSISTENT => true));
            }
            $this->shufangPDO->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            throw new Exception($this->errorInfo);
        }

        // 连接redis cache
        $this->cache = new Redis();
        $conn = $this->cache->pconnect($cache[0], $cache[1]);
        if ($conn === false) {
            $this->cache = NULL;
            $this->errorInfo = "connect cache server [{$cache[0]}:{$cache[1]}] failure.";
            throw new Exception($this->errorInfo);
        }
        $this->expire = $cache[2];
    }

    public function __destruct()
    {
        if ($this->cache !== NULL) {
            $this->cache->close();
        }

        if ($this->gatherMode == 0) { // rebuild mode
            $this->shufangPDO = NULL;
        }

        unset($this->record);
    }

    public function id($value)
    {
        $this->record['id'] = $value;
        return $value;
    }

    public function studyId($value)
    {
        $this->record['studyId'] = $value;
        return $value;
    }

    public function uid($value)
    {
        $this->record['uid'] = $value;
        return $value;
    }

    public function studyName($value)
    {
        $this->record['studyName'] = $value;
        return $value;
    }

    public function nickName($value)
    {
        $this->record['nickName'] = $value;
        return $value;
    }

    public function bookId($value)
    {
        $this->record['bookId'] = $value;
        return $value;
    }

    public function bookFrom($value)
    {
        $this->record['bookFrom'] = $value;
        return $value;
    }

    public function bookName($value)
    {
        $this->record['bookName'] = $value;
        return $value;
    }

    public function author($value)
    {
        $this->record['author'] = $value;
        return $value;
    }

    public function isbn($value)
    {
        $this->record['isbn'] = $value;
        return $value;
    }

    public function press($value)
    {
        $this->record['press'] = $value;
        return $value;
    }

    public function pubDate($value)
    {
        $this->record['pubDate'] = $value;
        return $value;
    }

    public function image($value)
    {
        $this->record['image'] = $value;
        return $value;
    }

    public function _studyName($value)
    {
        return isset($this->record['studyName']) ? $this->record['studyName'] : '';
    }

    public function _nickName($value)
    {
        return isset($this->record['nickName']) ? $this->record['nickName'] : '';
    }

    public function _bookName($value)
    {
        return isset($this->record['bookName']) ? $this->record['bookName'] : '';
    }

    public function _author($value)
    {
        return isset($this->record['author']) ? $this->record['author'] : '';
    }
}