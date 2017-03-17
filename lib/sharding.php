<?php

date_default_timezone_set('Asia/Chongqing');

/**
 * sharding类实现：路由、读写分离、一主多从、从库负载均衡
 */

class Sharding
{
    private $config;
    private $errorInfo;
    
    /**
     * 构造函数。
     * @param array $config  sharding配置
     */
    public function __construct($config) 
    {
        $this->config = $config;
        $this->errorInfo = '';
    }

    public function __destruct() {
        unset($this->config);
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    private static function parseDB($db)
    {
        $r = array();
        if(empty($db)) return $r;
        $dba = explode(',', $db);
        foreach($dba as $value) {
            $value = trim($value);
            if(empty($value)) continue;
            $dbw = explode(":", $value);
            if(count($dbw) == 1) {
                $r[$dbw[0]] = 1;
            } else {
                $r[$dbw[0]] = intval($dbw[1]);
                if($r[$dbw[0]] <= 0) $r[$dbw[0]] = 1;
            }
        }
        return $r;
    }
    
    private static function parseModDB($db, $modlist) 
    {
        $modDB = array();
        $list = explode(',', $modlist);
        foreach ($list as $mod) {
            $mod = trim($mod);
            if(empty($mod) && $mod !== '0' && $mod !== 0) continue;
            $r = sscanf($mod, "%[^-]-%[^]]", $b, $e);
            if ($r == 2) {
                for ($i = $b; $i <= $e; $i++) {
                    $modDB[$i] = $db; 
                }
            } else {
                $modDB[$mod] = $db;
            }
        }

        return $modDB;
    }
    
    private static function parseDateRange($dateRange)
    {
        $range = array();
        if ($dateRange == 'all') {
            $range[0] = 0;
            $range[1] = 0;
            return $range;
        }
        
        if(($date = stristr($dateRange, ' ago', true)) !== false) {
            $date = trim($date);
            $range[0] = 0;
            $range[1] = strtotime($date);
            if($range[1] === false || $range[1] <= 0)
                return false;
            else
                return $range;
        }

        $r = explode(',', $dateRange);
        if(count($r) == 1) {
            $range[1] = 0;
            $range[0] = strtotime(trim($r[0]));
            if($range[0] === false || $range[0] <= 0)
                return false;
            else
                return $range;
        } else if(count($r) == 2) {
            $range[0] = strtotime(trim($r[0]));
            if($range[0] === false || $range[0] <= 0)
                return false;
            $range[1] = strtotime(trim($r[1]));
            if($range[1] === false || $range[1] <= 0)
                return false;
            if($range[0] > $range[1])
                return false;
            else 
                return $range;
        } else {
            return false;
        }
    }
    
    private static function parseHistory($history)
    {
        if(($num = stristr($history,'day', true)) !== false) {
            $num = intval(trim($num));
            if($num <= 0) return false;
            $time = "-{$num} day";
        } else if(($num = stristr($history,'month', true)) !== false) {
            $num = intval(trim($num));
            if($num <= 0) return false;
            $time = "-{$num} month";
        } else if(($num = stristr($history,'year', true)) !== false) {
            $num = intval(trim($num));
            if($num <= 0) return false;
            $time = "-{$num} year";
        } else {
            return false;
        }
        
        return $time;
    }
    
    private static function parseRange($range)
    {
        $r = array();
        $list = explode(',', $range);
        foreach ($list as $item) {
            $item = trim(strtr($item,':','-'));
            $n = explode("-", $item);
            if(count($n) == 3) {
                $r[$n[0]][0] = intval($n[1]);
                $r[$n[0]][1] = intval($n[2]);
            } else if(count($n) == 2){
                $r[$n[0]][0] = intval($n[1]);
                $r[$n[0]][1] = 0;
            } else {
                return false;
            }       
        }
        return $r;
    }
    
    private static function parseRangeDB($db, $rangelist) 
    {
        $rangeDB = array();
        $list = explode(',', $rangelist);
        foreach ($list as $range) {
            $range = trim($range);
            if(empty($range) && $range !== '0' && $range !== 0) 
                continue;
            else
                $rangeDB[$range] = $db;
        }

        return $rangeDB;
    }
    
    private static function parseMapDB($db, $tabidlist) 
    {
        $dbs = array();
        $list = explode(',', $tabidlist);
        foreach ($list as $tabid) {
            $tabid = trim($tabid);
            if(empty($tabid) && $tabid !== '0' && $tabid !== 0) continue;
            $r = sscanf($tabid, "%[^-]-%[^]]", $b, $e);
            if ($r == 2) {
                for ($i = $b; $i <= $e; $i++) {
                    $dbs[$db][] = intval($i); 
                }
            } else {
                $dbs[$db][] = intval($tabid);
            }
        }

        return $dbs;
    }
    
    private static function parseUDF($func)
    {
        $pos = strpos($func,'(');
        if($pos === false) return false;
        $funcname = substr($func, 0, $pos);
        $funcname = trim($funcname);
        $end = strpos($func,')');
        if($end === false) return false;
        $funcarg = substr($func, $pos+1,$end-$pos-1);
        if($funcarg === false) {
            $funcargs = array();
        } else {
            $funcarg = trim($funcarg);
            $funcargs = explode(',', $funcarg);
            foreach ($funcargs as $key => $arg) {
                $arg = trim($arg);
                $funcargs[$key] = $arg; 
            }
        }
        $r[0] = $funcname;
        $r[1] = $funcargs;
        
        return $r;
    }

    /**
     * 可以直接传递一个数组，也可以传递一个配置文件，自己加载处理为数组
     * @param string $inifile sharding配置文件
     * @return array sharding配置数组
     * $config = array('@db@' => array(dbname => array('host','port','user','password','db'),...)
     *                 tablename => array('shardtype' =>,
     *                                    'difftable' =>,
     *                                    'masters' => array(dbname => weight,...)
     *                                    'slaves' => array(masterdb => array(dbname => weight,...))
     *                                    'mod' =>,
     *                                    'db' => array(mod=>dbname,...),
     *                                    'date' =>,
     *                                    'db' => array(masterdb => array(beg,end));
     *                                    'history' => n days ago / n months ago / n years ago
     *                                    'status' => ...
     *                                    'conds' => both/any
     *                                    'db' => array('current' => dbname, 'history' => dbname)
     *                                    'range' => array(rangename => array(min,max), ...)
     *                                    'db' => array(rangename => dbname,...)
     *                                    'redis' => array(host,port,dbnum)
     *                                    'db' => array(masterdb => array(tabid,...))
     *                                    'udf' => array(funcname,array(arg1,arg2,...))
     */
    public static function getConfig($inifile) 
    {
        $config = array();
        $ini = parse_ini_file($inifile, true);
        if($ini === false) {
            echo "can't parse ini file\n";
            return false;
        }
        
        // shardDB
        if(isset($ini['shardDB']) && !empty($ini['shardDB'])) {
            foreach($ini['shardDB'] as $k => $v) {
                $t = explode(':', $v);
                $r = array();
                $r['host'] = $t[0];
                $r['port'] = intval($t[1]);
                $r['user'] = $t[2];
                $r['password'] = $t[3];
                if(isset($t[4])) $r['db'] = $t[4];
                $config['@db@'][$k] = $r;
           }
        }
        
        // shard
        if(!isset($ini['shard']) || empty($ini['shard'])) {
            echo "[shard] isn't set in configuration.\n";
            return false;
        }
        
        // table 
        foreach($ini['shard'] as $k => $v) {
            $pos = strpos($k,'.');
            if($pos === false) {
                echo "{$k} set error in [shard]\n";
                return false;
            }
            $table = substr($k,0,$pos);
            $key = substr($k,$pos+1);
            if(strcasecmp($key, 'shardtype') == 0) {
                if(empty($v))
                    $config[$table]['shardtype'] = 'none';
                else
                    $config[$table]['shardtype'] = strtolower($v);
            } else if(strcasecmp($key, 'difftable') == 0 && !empty($v)) {
                $config[$table]['difftable'] = intval($v);
            } else if(strcasecmp($key, 'masters') == 0 && !empty($v)) {
                $config[$table]['masters'] = self::parseDB($v);
                foreach($config[$table]['masters'] as $db => $weight) {
                    $s = $table . '.slaves.' . $db; 
                    if(isset($ini['shard'][$s]) && !empty($ini['shard'][$s])) {
                        $config[$table]['slaves'][$db] = self::parseDB($ini['shard'][$s]);
                    }
                }
            } 
        }
        
        // get table sharding
        foreach($ini['shard'] as $k => $v) {
            $pos = strpos($k,'.');
            if($pos === false) {
                echo "{$k} set error in [shard]\n";
                return false;
            }
            $table = substr($k,0,$pos);
            $key = substr($k,$pos+1);
            
            switch($config[$table]['shardtype']) {
                case 'none':
                    break;
                case 'mod':
                    if(strcasecmp($key, 'storebymod') == 0 && !empty($v)) {
                        $config[$table]['mod'] = intval($v); 
                    } else if(($db = stristr($key, 'mod.')) !== false) {
                        $db = substr($db,strlen('mod.'));
                        if(!isset($config[$table]['db'])) $config[$table]['db'] = array();
                        $config[$table]['db'] += self::parseModDB($db, $v);
                    }
                    break;
                case 'date':
                    if(strcasecmp($key, 'storebydate') == 0 && !empty($v)) {
                        $config[$table]['date'] = strtolower($v); 
                        if($config[$table]['date'] != 'year'   && $config[$table]['date'] != 'half-year' &&
                           $config[$table]['date'] != 'season' && $config[$table]['date'] != 'month') {
                            echo "$table storebydate set error.\n";
                            return false;
                        }
                    } else if(($db = stristr($key, 'date.')) !== false) {
                        $db = substr($db,strlen('date.'));
                        $config[$table]['db'][$db] = self::parseDateRange($v);
                        if($config[$table]['db'][$db] === false) {
                            echo "$table $db date set error.\n";
                            return false;
                        }
                    }
                    break;
                case 'history':
                    if(strcasecmp($key, 'storebyhistory') == 0 && !empty($v)) {
                        $config[$table]['history'] = self::parseHistory($v); 
                    } else if(strcasecmp($key, 'storebystatus') == 0 && !empty($v)) {
                        $config[$table]['status'] = $v; 
                    } else if(strcasecmp($key, 'storebyconds') == 0 && !empty($v)) {
                        $config[$table]['conds'] = strtolower($v);
                        if($config[$table]['conds'] != 'both' && $config[$table]['conds'] != 'any') {
                            echo "$table storebyconds set error.\n";
                            return false;
                        }
                    } else if(($db = stristr($key, 'history.')) !== false) {
                        $db = substr($db,strlen('history.'));
                        if(strtolower($v) == 'current') {
                            $config[$table]['db']['current'] = $db;
                        } else if(strtolower($v) == 'history') { 
                            $config[$table]['db']['history'] = $db;
                        } else {
                            echo "$table database set error.\n";
                            return false;
                        }   
                    }
                    break;
                case 'range':
                    if(strcasecmp($key, 'storebyrange') == 0 && !empty($v)) {
                        $config[$table]['range'] = self::parseRange($v); 
                    } else if(($db = stristr($key, 'range.')) != false) {
                        $db = substr($db,strlen('range.'));
                        if(!isset($config[$table]['db'])) $config[$table]['db'] = array();
                        $config[$table]['db'] += self::parseRangeDB($db, $v);
                    }
                    break;
                case 'map':
                    if(strcasecmp($key, 'map.redis') == 0 && !empty($v)) {
                        $config[$table]['redis'] = explode(':', $v);
                    } else if(($db = stristr($key, 'map.')) != false) {
                        $db = substr($db,strlen('map.'));
                        if(!isset($config[$table]['db'])) $config[$table]['db'] = array();
                        $config[$table]['db'] += self::parseMapDB($db, $v);
                    }
                    break;
                case 'udf':
                    if(strcasecmp($key, 'udf') == 0 && !empty($v)) {
                        $config[$table]['udf'] = self::parseUDF($v);
                        if($config[$table]['udf'] === false) {
                            echo "$table udf set error.\n";
                            return false;
                        }
                    }
                    break;
                default:
                    echo "$table shard type set error.\n";
                    return false;
           }
        }
        
        // check ...
        foreach($config as $table => $shard) {
            if($table == '@db@') continue;
            if(!isset($shard['difftable'])) $shard['difftable'] = 0;
            if($shard['shardtype'] != 'udf' && !isset($shard['masters'])) {
                echo "$table masters isn't set\n";
                return false;
            }
            
            switch($shard['shardtype']) {
                case 'mod': 
                    if(!isset($shard['mod'], $shard['db'])) {
                        echo "$table mod or db isn't set\n";
                        return false;
                    }
                    break;
                case 'date':
                    if(!isset($shard['date'], $shard['db'])) {
                        echo "$table date or db isn't set\n";
                        return false;
                    }
                    break;
                case 'history':
                    if(!isset( $shard['db'])) {
                        echo "$table db isn't set\n";
                        return false;
                    }
                    break;
                case 'range':
                    if(!isset($shard['range'], $shard['db'])) {
                        echo "$table range or db isn't set\n";
                        return false;
                    }
                    break;
                case 'map':
                    if(!isset($shard['redis']) || ($shard['difftable'] == 1 && !isset($shard['db']))) {
                        echo "$table redis or db isn't set\n";
                        return false;
                    }
                    break;
                case 'udf':
                    if(!isset($shard['udf'])) {
                        echo "$table udf isn't set\n";
                        return false;
                    }
                    if(!method_exists('Sharding', $shard['udf'][0])) {
                        echo "$table udf {$shard['udf'][0]} is inexist.\n";
                        return false;
                    }
                    break;
            }
        }
        
        return $config;
    }
    
    //根据DB的权重随机选择一个DB
    public function getDbByWeight($db)
    {
        $dbr = array();
        $totalweigth = array_sum($db);
        $start = 1;
        foreach($db as $name => $weight) {
            $dbr[$name][0] = $start;
            $dbr[$name][1] = intval($start + $weight/$totalweigth * 100 - 1);
            $start = $dbr[$name][1] + 1;
        }
        
        $r = mt_rand(1, $start-1);
        foreach($dbr as $name => $range) {
            if ($r >= $range[0] && $r <= $range[1]) {
                unset($dbr);
                return $name;
            }
        }
        
        unset($dbr);
        return $name;
    }
    
    private function packDBInfo($dbname, $tablename, $dbtype)
    {
        $db = $this->config['@db@'][$dbname];
        $db['table'] = $tablename;
        $db['type'] = $dbtype;
        return $db;
    }

    /**
     * 获取sharding db信息。
     * @param string $table: 表名。
     * @param string $key:   用于切分的key。如果切分方式为history,key取值格式为： date / @status / date@status
     * @param string $dbtype: 返回的数据库类型:  master,slave
     * @return array dbinfo = array('host'=>,'port'=>,'user'=>,'password'=>,'db'=>,'table'=>,'type'=>'master' or 'slave')
     */
    public function getDBInfo($table, $key, $dbtype='master')
    {
        if(!isset($this->config[$table]) || empty($this->config[$table])) {
            $this->errorInfo = "$table sharding is unsupport."; 
            return false;
        }
        
        if($dbtype != 'master' && $dbtype != 'slave') {
            $this->errorInfo = "$table dbtype set error.";
            return false;
        }
        
        $shard = $this->config[$table];
        $shardtype = $shard['shardtype'];
        if($shardtype != 'udf' && $shardtype != 'none')
            $difftable = $shard['difftable'];
        
        $db = '';
        switch ($shardtype) {
             case 'none':
                 reset($shard['masters']);
                 $db = key($shard['masters']);
                 break;
             case 'mod':
                 $mod = $key % $shard['mod'];
                 $db = $shard['db'][$mod];
                 if($difftable) $table .= "_{$mod}";
                 break;
             case 'date':
                 $time = strtotime($key);
                 if($time === false || $time <= 0) {
                     $this->errorInfo = "$key is invalid date format";
                     return false;
                 }
                 
                 $db = '';
                 foreach($shard['db'] as $dbname => $date) {
                     if(($date[0] == 0 && $date[1] == 0) || 
                        ($time >= $date[0] && ($date[1] == 0 || $time <= $date[1]))) {
                         $db = $dbname;
                         break;
                     }
                 }
                 if(empty($db)) {
                     $this->errorInfo = "$key out of date range.";
                     return false;
                 }
 
                 if(!$difftable) break;
                 $parseDate = date_parse($key);
                 $year = $parseDate['year'];
                 $month = $parseDate['month'];
                 switch ($shard['date']) {
                    case 'year': 
                        $table .= "_{$year}";
                        break;
                    case 'half-year':
                        if($month <= 6) {
                            $table .= "_{$year}A";
                        } else {
                            $table .= "_{$year}B";
                        }
                        break;
                    case 'season': 
                        if($month <= 3) {
                            $table .= "_{$year}S1";
                        } else if($month <= 6) {
                            $table .= "_{$year}S2";
                        } else if($month <= 9) {
                            $table .= "_{$year}S3";
                        } else if($month <= 12) {
                            $table .= "_{$year}S4";
                        } 
                        break;
                    case 'month': // 月
                        if($month < 10)
                            $table .= "_{$year}0{$month}";
                        else
                            $table .= "_{$year}{$month}";
                        break;
                 }
                 break;
             case 'history':
                 $pos = strpos($key,'@'); // $key=date[@status] 
                 if($pos === false) {
                     $date = $key;
                     $status = '';
                 } else {
                     $date = substr($key,0,$pos);
                     $status = substr($key,$pos+1);
                 }
                 
                 $isHistory = 0;
                 if($shard['conds'] == 'any') {
                     if(isset($shard['histroy']) && !empty($shard['history']) && !empty($date)) {
                         $time = strtotime($date);
                         if($time === false || $time <= 0) {
                             $this->errorInfo = "$key date set error.";
                             return false;
                         }
                         if($time < strtotime($shard['histroy'])) {
                             $isHistory = 1;
                         }
                     }
                     
                     if(!$isHistory && isset($shard['status']) && !empty($shard['status']) && !empty($status)) {
                         if($status == $shard['status']) {
                             $isHistory = 1;
                         }
                     }
                 } else if($shard['conds'] == 'both') {
                     if(isset($shard['history']) && !empty($shard['history']) && !empty($date) && 
                        isset($shard['status'])  && !empty($shard['status'])  && !empty($status)) {
                         $time = strtotime($date);
                         if($time === false || $time <= 0) {
                             $this->errorInfo = "$key date set error.";
                             return false;
                         }
                         
                         $history = strtotime($shard['history']);
                         if($time <  $history && $status == $shard['status']) {
                             $isHistory = 1;
                         }
                     }
                 }
                 
                 if($isHistory) {
                     $db = $shard['db']['history'];
                     if($difftable) $table .= '_h';
                 } else {
                     $db = $shard['db']['current'];
                 }
                 break;
             case 'range':
                 foreach($shard['range'] as $name => $range) {
                    if($key >= $range[0] && ($range[1] == 0 || $key <= $range[1])) {
                        $db = $shard['db'][$name];
                        if($difftable)  $table .= "_{$name}";
                        break;
                    }
                 }
                 break;
             case 'map':
                 $keylen = strlen($key);
                 if($keylen <= 3) {
                     $hkey = $table . ':0';
                     $field = $key;
                 } else {
                     $seglen = $keylen - 3;
                     $hkey = $table . ':' . substr($key,0,$seglen);
                     $field = substr($key,$seglen);
                 }
                 
                $redis = new Redis();
                if (!$redis->connect($shard['redis'][0], $shard['redis'][1])) {
                    $this->errorInfo = "connect redis[{$shard['redis'][0]}:{$shard['redis'][1]}] failure.";
                    return false;
                }
                $value = $redis->hGet($hkey, $field);
                if ($value === false) {
                    $db = $this->getDbByWeight($shard['masters']);
                    if($difftable) {
                        $tabidnum = count($shard['db'][$db]);
                        $index = mt_rand(0, $tabidnum-1);
                        $tabid = $shard['db'][$db][$index];
                        $table .= "_{$tabid}";
                        $value = $db . ':' . $tabid;
                    } else {
                        $value = $db;
                    }
                    if($redis->hSet($hkey, $field, $value) === false) {
                        $this->errorInfo = "store $key error.";
                        return false;
                    }
                } else if($difftable) {
                    $pos = strpos($value,':');
                    $db = substr($value, 0, $pos);
                    $tabid = strstr($value, $pos+1);
                    $table .= "_{$tabid}";
                } else {
                    $db = $value; 
                }
                $redis->close();
                break;
             case 'udf':
                 $udfargs = array();
                 $udfargs[0] = $table;
                 $udfargs[1] = $key;
                 $udfargs[2] = $dbtype;
                 $udfargs[3] = $shard['udf'][1];
                 $r = call_user_func_array(array($this, $shard['udf'][0]), $udfargs); 
                 if($r === false) {
                     $this->errorInfo = "call udf {$shard['udf'][0]} error: " . $this->errorInfo;
                     return false;
                 }
                 return $r;
        }
        
        if($dbtype == 'master') {
            return $this->packDBInfo($db,$table,$dbtype);
        } else if($dbtype == 'slave') {
            if(!isset($shard['slaves']) || empty($shard['slaves'])) {
                $this->errorInfo = "$table slaves isn't set.";
                return false;
            }
            $db = $this->getDbByWeight($shard['slave'][$db]);
            return $this->packDBInfo($db,$table,$dbtype);
        } else {
            $this->errorInfo = "$table dbtype set error.";
            return false;
        }
    }
    
    /**
     * TODO: support multi-sharding.
     * @param string $table
     * @param array  $key      array(key1,key2,key3,...); 每一个key用于一种切分方式。
     * @param string $dbtype
     */
    public function getDBInfoForMultiShard($table, $key, $dbtype='master')
    {
        
    }
      
    public function getProductDBInfo($table, $key, $dbtype, $args)
    {
        if(empty($args) || count($args) != 5) {
            $this->errorInfo = 'parameters is error';
            return false;
        } else {
            $mapDB = $args;
        }
        
        // 连接map DB
        try {
            $dsn = 'mysql:' . 'host=' . $mapDB[0] . ';' . 'port=' . $mapDB[1] . ';' . 'dbname=' . $mapDB[4] . ';' . 'charset=utf8';
            $mapPDO = new PDO($dsn, $mapDB[2], $mapDB[3], array(PDO::ATTR_PERSISTENT => true)); // 采用持久连接，减少连接数。
            $mapPDO->query("SET NAMES utf8");
            //$mapPDO->query("SET SESSION wait_timeout=10"); // 让MySQL自动关闭连接，防止连接过多。
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            return false;
        }
        
        // 先根据userId从userMap查询user商品所在的tableID
        $sql = "SELECT tableId FROM userMap WHERE userId = $key";
        $result = $mapPDO->query($sql);
        if($result === false) {
            $e = $mapPDO->errorInfo();
            $this->errorInfo = $e[2];
            //$mapPDO = NULL;
            return false;
        }

        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) { //返回的结果为空。
            $this->errorInfo = "userID [{$key}] inexist in userMap";
            //$mapPDO = NULL;
            return false;
        }

        $tabID = $resultset[0]['tableId']; 

        // 根据tableId从tableMap查询table对应的连接信息
        if($dbtype == 'master')
            $sql = "SELECT masterHost, dbName FROM tableMap WHERE tableId = $tabID";
        else
            $sql = "SELECT slaveHost, dbName FROM tableMap WHERE tableId = $tabID";
        
        $result = $mapPDO->query($sql);
        if($result === false) {
            $e = $mapPDO->errorInfo();
            $this->errorInfo = $e[2];
            //$mapPDO = NULL;
            return false;
        }

        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) { //返回的结果为空。
            $this->errorInfo = "tableID [{$tabId}] inexist in tableMap";
            //$mapPDO = NULL;
            return false;
        }
        
        // 采用持久连接，在没有错误的情况下不主动关闭连接。
        //$mapPDO = NULL;
        
        // 返回数据库信息
        if($dbtype == 'master')
            $host = $resultset[0]['masterHost'];
        else 
            $host = $resultset[0]['slaveHost'];
        
        $dbname = $resultset[0]['dbName'];
        if($dbname == 'product_a1' || $dbname == 'product_a2') {
            $user = 'producta20150720';
            $pass = 'Pqp5YACzO7';
        } elseif ($dbname == 'product_b1' || $dbname == 'product_b2') {
            $user = 'productb20150720';
            $pass = 'guDvP39EZn';
        }
        
        $dbInfo['host'] = $host;
        $dbInfo['port'] = 3306;
        $dbInfo['user'] = $user;
        $dbInfo['password'] = $pass;
        $dbInfo['db'] = $dbname;
        $dbInfo['table'] = $table . '_' .$tabID;
        $dbInfo['type'] = $dbtype;
        return $dbInfo;
    }
    
    public function getOrdersDBInfo($table, $key, $dbtype, $args)
    {
        if(empty($args) || count($args) != 5) {
            $this->errorInfo = 'parameters is error';
            return false;
        } else {
            $mapDB = $args;
        }
        
        // 连接map DB
        try {
            $dsn = 'mysql:' . 'host=' . $mapDB[0] . ';' . 'port=' . $mapDB[1] . ';' . 'dbname=' . $mapDB[4] . ';' . 'charset=utf8';
            $mapPDO = new PDO($dsn, $mapDB[2], $mapDB[3], array(PDO::ATTR_PERSISTENT => true)); // 采用持久连接，减少连接数。
            $mapPDO->query("SET NAMES utf8");
            //$mapPDO->query("SET SESSION wait_timeout=10"); // 让MySQL自动关闭连接，防止连接过多。
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            return false;
        }
        
        $sql = "SELECT tableId FROM sellerOrderMap WHERE userId = $key";
        $result = $mapPDO->query($sql);
        if($result === false) {
            $e = $mapPDO->errorInfo();
            $this->errorInfo = $e[2];
            //$mapPDO = NULL;
            return false;
        }

        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) { //返回的结果为空。
            $this->errorInfo = "userID [{$key}] inexist in userMap";
            //$mapPDO = NULL;
            return false;
        }

        $tabID = $resultset[0]['tableId']; 

        $dbInfo['host'] = $mapDB[0];
        $dbInfo['port'] = 3306;
        $dbInfo['user'] = $mapDB[2];
        $dbInfo['password'] = $mapDB[3];
        $dbInfo['db'] = $mapDB[4];
        $dbInfo['table'] = $table . '_' .$tabID;
        $dbInfo['type'] = $dbtype;
        return $dbInfo;
    }
    
    public function getPmDBInfo($table, $key, $dbtype, $args)
    {
        if(empty($args) || count($args) != 5) {
            $this->errorInfo = 'parameters is error';
            return false;
        } else {
            $mapDB = $args;
        }
        
        // 连接map DB
        try {
            $dsn = 'mysql:' . 'host=' . $mapDB[0] . ';' . 'port=' . $mapDB[1] . ';' . 'dbname=' . $mapDB[4] . ';' . 'charset=utf8';
            $mapPDO = new PDO($dsn, $mapDB[2], $mapDB[3], array(PDO::ATTR_PERSISTENT => true)); // 采用持久连接，减少连接数。
            $mapPDO->query("SET NAMES utf8");
            //$mapPDO->query("SET SESSION wait_timeout=10"); // 让MySQL自动关闭连接，防止连接过多。
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            return false;
        }
        
        $sql = "SELECT tableId FROM sellerTableMap WHERE userId = $key";
        $result = $mapPDO->query($sql);
        if($result === false) {
            $e = $mapPDO->errorInfo();
            $this->errorInfo = $e[2];
            //$mapPDO = NULL;
            return false;
        }

        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) { //返回的结果为空。
            $this->errorInfo = "userID [{$key}] inexist in sellerTableMap";
            //$mapPDO = NULL;
            return false;
        }

        $tabID = $resultset[0]['tableId']; 

        $dbInfo['host'] = $mapDB[0];
        $dbInfo['port'] = 3306;
        $dbInfo['user'] = $mapDB[2];
        $dbInfo['password'] = $mapDB[3];
        $dbInfo['db'] = $mapDB[4];
        $dbInfo['table'] = $table . '_' .$tabID;
        $dbInfo['type'] = $dbtype;
        return $dbInfo;
    }
    
    public function getTestDBInfo($table, $key, $dbtype, $args)
    {
        $dbInfo['host'] = '127.0.0.1';
        $dbInfo['port'] = 3306;
        $dbInfo['user'] = 'root';
        $dbInfo['password'] = '';
        $dbInfo['db'] = 'search';
        $dbInfo['table'] = 'page';
        $dbInfo['type'] = 'master';
        return $dbInfo;
    }
}

?>




