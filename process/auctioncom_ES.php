<?php
require_once 'convertor.php';

date_default_timezone_set('Asia/Chongqing');

/**
 * Created by diao
 * Date: 16-9-12
 * Time: 上午10:25
 */
class auctioncom_es extends Convertor
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

        if (empty($args))
            throw new Exception ('convert arguments is empty');

        $this->args = $args;

        $this->dbUser = '';
        $this->dbPwd = '';
        $this->host = '';
        $this->port = '';
        $this->name = '';
        $args = explode(':', $args['DB.auctioncom']);
        $args['DB.user'] = $args[2];
        $args['DB.password'] = $args[3];
        $args['DB.host'] = $args[0];
        $args['DB.port'] = $args[1];
        $args['DB.name'] = $args[4];

        if (isset($args['DB.user']) && !empty($args['DB.user']))
            $this->dbUser = $args['DB.user'];
        if (isset($args['DB.password']) && !empty($args['DB.password']))
            $this->dbPwd = $args['DB.password'];
        if (isset($args['DB.host']) && !empty($args['DB.host']))
            $this->host = $args['DB.host'];
        if (isset($args['DB.port']) && !empty($args['DB.port']))
            $this->port = $args['DB.port'];
        if (isset($args['DB.name']) && !empty($args['DB.name']))
            $this->name = $args['DB.name'];
        // 连接DB，采用持久连接减少连接数。
        try {
            $dsn = 'mysql:' . 'host=' . $this->host . ';' . 'port=' . $this->port . ';' . 'dbname=' . $this->name . ';' . 'charset=utf8';
            if ($this->gatherMode == 0) { // rebuild mode
                $this->pmPDO = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => false));
                $this->pmPDO->query("SET SESSION wait_timeout=28800");
            } else { // update mode
                $this->pmPDO = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => true));
            }
            $this->pmPDO->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            throw new Exception($this->errorInfo);
        }
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

    // 日期格式必须为: yyyy-mm-dd  yyyy-m-d
    private function date2int($value, $default = 0)
    {
        $v = $default;
        if ($value != '0000-00-00') {
            $ymd = explode('-', $value);
            foreach ($ymd as $k => $v) {
                if ($k == 0 && strlen($v) != 4)
                    return 0;
                if (($k == 1 || $k == 2) && strlen($v) == 1)
                    $ymd[$k] = '0' . $v;
            }

            if (count($ymd) == 1) {
                $v = intval($ymd[0] . '0000');
            } else if (count($ymd) == 2) {
                $v = intval($ymd[0] . $ymd[1] . '00');
            } else if (count($ymd) == 3) {
                $v = intval($ymd[0] . $ymd[1] . $ymd[2]);
            }
        }

        return $v;
    }

    public function beginTime($value)
    {
        return $this->date2int($value);
    }

    public function beginTime2($value)
    {
        if (!isset($this->record['beginTime']) || empty($this->record['beginTime']))
            return 29991231;
        else
            $value = $this->record['beginTime'];

        $v = $this->date2int($value, 29991231);
        if ($v !== 29991231) { // 日期的年份进行判断
            $year = intval(substr("$v", 0, 4));
            $now = intval(date("Y"));
            if ($year < 1000 || $year > $now)
                return 29991231;
        }
        return $v;
    }

    public function comShortName($value)
    {
        $comShortName = '';
        $comId = isset($this->record['comId']) ? $this->record['comId'] : 0;
        if (!$comId) {
            return $comShortName;
        }

        $sql = 'SELECT comShortName FROM comInfo WHERE comId = ' . $comId;
        $result = $this->pmPDO->query($sql);
        if ($result === false) {
            $serverInfo = $this->pmPDO->getAttribute(PDO::ATTR_SERVER_INFO);
            if ($serverInfo == 'MySQL server has gone away') {
                unset($this->pmPDO);
                $dsn = 'mysql:' . 'host=' . $this->host . ';' . 'port=' . $this->port . ';' . 'dbname=' . $this->name . ';' . 'charset=utf8';
                $this->pmPDO = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => true));
                $this->pmPDO->query("SET NAMES utf8");
                $result = $this->pmPDO->query($sql);
                if ($result === false) {
                    $e = $this->pmPDO->errorInfo();
                    $this->errorInfo = $e[2];
                    return false;
                }
            } else {
                $e = $this->pmPDO->errorInfo();
                $this->errorInfo = $e[2];
                return false;
            }
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if ($resultset) {
            $comShortName = isset($resultset[0]['comShortName']) ? $resultset[0]['comShortName'] : '';
        }
        return $comShortName;
    }
}