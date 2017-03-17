<?php

require_once 'dao.php';

class deltaTool {

    private $logpath;
    private $config;
    private $dao;
    private $daos;
    public  $errorinfo;

    public function __construct($config, $logpath = '') {
        $this->errorinfo = '';
        $this->config = $config;
        $this->logpath = $logpath;
    }

    public static function getDistNodes($inifile) {
        $nodes = parse_ini_file($inifile, true);
        if ($nodes === false) {
            echo "can't parse ini file: $inifile\n";
            exit;
        }

        foreach ($nodes as $nodename => &$node) {
            $node['name'] = $nodename;

            // searchdb
            $node['searchdb'] = explode(':', $node['searchdb']);
            if (count($node['searchdb']) != 5) {
                echo "node [{$nodename}] searchdb set error.\n";
                exit;
            }
            $node['searchdb']['host'] = $node['searchdb'][0];
            $node['searchdb']['port'] = $node['searchdb'][1];
            $node['searchdb']['user'] = $node['searchdb'][2];
            $node['searchdb']['password'] = $node['searchdb'][3];
            $node['searchdb']['db'] = $node['searchdb'][4];
        }

        return $nodes;
    }

    public static function getCurNode($nodes) {
        $env = 'SPHINX_NODE';
        $name = getenv($env);
        if (empty($name)) {
            echo "environment variable [{$env}] isn't set.\n";
            exit;
        }

        if (!isset($nodes[$name])) {
            echo "environment variable [{$env}] set error.\n";
            exit;
        }

        return $nodes[$name];
    }

    public function getTableIds($curNode, $key) {
        $indexs = explode(',', $curNode[$key]);
        $shards = array();
        foreach ($indexs as $shard) {
            $shard = trim($shard);
            if ($shard === '' || $shard == 'dist')
                continue;
            if (($pos = strpos($shard, '-')) === false) {
                array_push($shards, $shard);
            } else {
                if (strpos($shard, '[') === false) {
                    $b = intval(trim(substr($shard, 0, $pos)));
                    $e = intval(trim(substr($shard, $pos + 1)));
                    for ($i = $b; $i <= $e; $i++)
                        array_push($shards, "$i");
                } else {
                    $r = sscanf($shard, "%[^[][%[^-]-%[^]]]", $n, $b, $e); //daydelta_[12-23]
                    if ($r == 3) {
                        for ($i = $b; $i <= $e; $i++) {
                            array_push($shards, $n . $i);
                        }
                    } else {
                        array_push($shards, $shard);
                    }
                }
            }
        }
        return $shards;
    }

    public function writeLog($msg) {
        error_log(date('Y-m-d H:i:s') . " " . $msg . "\n", 3, $this->logpath);
    }

    public function truncateMinTables($datatype, $shards)
    {
        // 连接Search DB
        $this->dao = new DAO($this->config['searchdb']);
        if ($this->dao->connect(true, 0) === false) {
            $errorInfo = $this->dao->getErrorInfo();
            throw new Exception($errorInfo);
        }
        
        if(!$datatype || empty($shards)) {
            $this->errorinfo = 'Truncate Func Failure';
            return false;
        }
        foreach ($shards as $id) {
            $table = $datatype . '_mindelta_' . $id;
            $this->writeLog('Truncate Table ' . $table);
            if ($this->dao->truncate($table) === false) {
                $this->errorinfo = $this->dao->getErrorInfo();
                return false;
            }
        }
        return true;
    }
    
    public function updateIBI()
    {
        $isPersistent = false; // 是否采用持久连接数据库
        $waitTimeout = 0;  // MySQL保持空闲连接的最大时间
        foreach ($this->config['db'] as $dbname => $dsn) {
            $dao = new DAO($dsn);
            if($dao->connect($isPersistent, $waitTimeout) === false) {
                $error = $dao->getErrorInfo();
                $this->errorinfo = "connect $dbname failure: $error";
                $this->writeLog($this->errorinfo);
                return false;
            }
            $this->daos[$dbname] = $dao;
        }
        $tables = $this->config['primary']['tables'];
        foreach($tables as $table) {
            foreach($table as $tablename => $dbname) {
                $this->writeLog('Update Table ' . $tablename);
                $dao = $this->daos[$dbname];
                $resultset = $dao->update($tablename, array('isBuildIndex' => 1), '', '1=1');
                if($resultset === false) {
                    $this->errorinfo = $dao->getErrorInfo();
                    $this->writeLog($this->errorinfo);
                    return false;
                }
            }
        }
        return true;
    }

}

?>
