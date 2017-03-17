<?php

require_once 'utils.php';
require_once 'dao.php';
require_once 'process.php';
require_once 'ElasticSearch.php';

class GatherES {
    private $daos;
    private $cache;
    private $config;
    private $stmts;
    private $logpath;
    private $errorinfo;
    private $searchcols;
    private $processor;
    private $processorFixStr;
    private $filternum;
    private $errornum;
    private $dataname;
    private $datatype;
    private $mode;

    const MODE_BUILD = 0;
    const MODE_UPDATE = 1;
   
    public function __construct($config, $logpath='', $mode=self::MODE_BUILD) 
    {
        $this->daos = array();  
        $this->cache = NULL;    
        $this->stmts = array(); 
        $this->errorinfo = '';
        $this->searchcols = '';
        $this->processor = NULL;
        $this->processorFixStr = '_ES';
        $this->filternum = 0;
        $this->errornum = 0;
        $this->mode = $mode;
        $this->config = $config;
        
        if(empty($logpath))
            $this->logpath = $this->config['logpath'];
        else
            $this->logpath = $logpath;
    }
    
    // 返回一个主表数组： array(array(table=>db), ...);
    // $k: DB.db1, $v: table[n-m] table0 table1
    private static function getPrimaryTables($k, $v) 
    {
        $tables = array();
        $t = explode(' ', $v);
        if ($t === false)
            return false;

        foreach ($t as $it) {
            $it = trim($it);
            if(empty($it) && $it !== '0' && $it !== 0) continue;
            $r = sscanf($it, "%[^[][%[^-]-%[^]]]", $n, $b, $e);
            if ($r == 3) {
                for ($i = $b; $i <= $e; $i++) {
                    $table = array();
                    $table[$n . $i] = $k;
                    array_push($tables, $table);
                }
            } else {
                $table = array();
                $table[$it] = $k;
                array_push($tables, $table);
            }
        }

        return $tables;
    }

    // 返回一个辅表数组： array('table'=>db, ...);
    // $k: DB.db1, $v: table[n-m] table0 table1
    private static function getSecondaryTables($k, $v) 
    {
        $tables = array();
        $t = explode(' ', $v);
        if ($t === false)
            return false;

        foreach ($t as $it) {
            $it = trim($it);
            if(empty($it) && $it !== '0' && $it !== 0) continue;
            $r = sscanf($it, "%[^[][%[^-]-%[^]]]", $n, $b, $e);
            if ($r == 3) {
                for ($i = $b; $i <= $e; $i++) {
                    $tables[$n . $i] = $k; 
                }
            } else {
                $tables[$it] = $k;
            }
        }

        return $tables;
    }

    // 参数$v:   primary [table field] [alias], normal alias, foreign table field
    // 返回一个数组：array('type'=> , 'alias' => , 'fk_table' => 'fk_field' => );
    private static function getField($v) 
    {
        $field = array();
        $rr = array();
        $r = explode(' ', $v);
        foreach($r as $s) {
            $s = trim($s);
            if(empty($s)) continue;
            array_push($rr, $s);
        }

        $c = count($rr);
        if($c == 0 || $c > 4) return false;

        if (strncmp($rr[0], "primary", 7) == 0) {
            $field['type'] = $rr[0];
            if($c == 2) {
                $field['alias'] = $rr[1];
            } else if($c == 3) {
                $field['fk_table'] = $rr[1];
                $field['fk_field'] = $rr[2];
            } else if($c == 4) {
                $field['fk_table'] = $rr[1];
                $field['fk_field'] = $rr[2];
                $field['alias'] = $rr[3];
            } 
        } else if(strncmp($rr[0], "normal", 6) == 0) { 
            $field['type'] = $rr[0];
            if($c == 2) $field['alias'] = $rr[1];
        } else if (strncmp($rr[0], "foreign", 7) == 0) {
            if($c != 3) return false;
            $field['type'] = $rr[0];
            $field['fk_table'] = $rr[1];
            $field['fk_field'] = $rr[2];
        } else if (strncmp($rr[0], "foreignormal", 12) == 0) {
            $field['type'] = $rr[0];
            if($c == 3) {
                $field['fk_table'] = $rr[1];
                $field['fk_field'] = $rr[2];
            } else if($c == 4) {
                $field['fk_table'] = $rr[1];
                $field['fk_field'] = $rr[2];
                $field['alias'] = $rr[3];
            } else {
                return false;
            }
        } else if (strncmp($rr[0], "extern", 6) == 0) {
            $field['type'] = $rr[0];
        } else {
            return false;
        }

        return $field;
    }

     /**获得数据采集配置，返回一个配置数组，具体如下：
     *  array(
     *        'logpath' => ,
     *        'data' => array('name' =>, 'type'=),
     *        'cache' => array('host'=>, 'port' =>, 'expire' =>),
     *        'db' => array(dbname => array(host,port,user,pwd,db), ...),
     *        'primary' => array('tables' => array(array(tablename => dbname), ...),
     *                           'fields' => array(fieldname => array('type' =>, 
     *                                                                'alias'=>,
     *                                                                'fk_table'=>,
     *                                                                'fk_field'=>), ...)
     *                           'where' => where clause ...
     *                           'wheres' => array(datatype => where clause)
     *                           'ranges' => array(tablename => array(start,end));
     *                           'step' => ,
     *        'secondary' => array('tables' => array(tablename => dbname, ...),
     *                             tablename => array(fieldname => array('type' =>, ), ...))),
     *        'process' => array(fieldname=> array(), ...)
     *        'convert' => array()
     *        )
     */

    public static function getConfig($inifile)
    {
        $config = array();
        $ini = parse_ini_file_extended($inifile);
        if($ini === false || empty($ini)) {
            echo "Can't parse $inifile.\n";
            return false;
        }

        // base
        $config['logpath'] = 'gather.log';
        if(isset($ini['base']) && isset($ini['base']['logpath']) && !empty($ini['base']['logpath']))
           $config['logpath'] = $ini['base']['logpath'];

        // data
        if(isset($ini['data']) && isset($ini['data']['name']) && !empty($ini['data']['name'])) {
            $config['data']['name'] = $ini['data']['name'];
        } else {
            echo "data name isn't set in configuration [data] section.\n";
            return false;
        }

        if(isset($ini['data']) && isset($ini['data']['type']) && !empty($ini['data']['type'])) {
            $config['data']['type'] = $ini['data']['type'];
        } 

        // db
        if(!isset($ini['db']) || empty($ini['db'])) {
            echo "DB isn't set in configuration.\n";
            return false;
        }

        foreach($ini['db'] as $k => $v) {
            $t = explode(':', $v);
            if ($t === false) {
                echo "$k set error in configuration.\n";
                return false;
            }
            $r = array();
            $r['host'] = $t[0];
            $r['port'] = intval($t[1]);
            $r['user'] = $t[2];
            $r['password'] = $t[3];
            $r['db'] = $t[4];
            $config['db'][$k] = $r;
        }

        // cache
        $config['cache']['host'] = '';
        $config['cache']['port'] = 0;
        $config['cache']['expire'] = 86400;
        if(   isset($ini['cache']) 
           && isset($ini['cache']['host'], $ini['cache']['port']) 
           && !empty($ini['cache']['port'])
           && !empty($ini['cache']['host'])) {
            $config['cache']['host'] = $ini['cache']['host'];
            $config['cache']['port'] = intval($ini['cache']['port']);
            if(isset($config['cache']['expire']))
                $config['cache']['expire'] = intval($ini['cache']['expire']);
        }

        // primary
        if(!isset($ini['primary']) || empty($ini['primary'])) {
            echo "[primary] isn't set in configuration.\n";
            return false;
        }

        $config['primary']['tables'] = array();
        $config['primary']['fields'] = array();
        $config['primary']['where'] = '';
        $config['primary']['step'] = 1000;
        $config['primary']['wheres'] = array();
        $config['primary']['ranges'] = array();
        foreach($ini['primary'] as $k => $v) {
            if (strncmp($k, "DB.", 3) == 0) {
                $tables = self::getPrimaryTables($k, $v);
                if ($tables === false) {
                    echo "$k set error in configuration [primary].\n";
                    return false;
                }
                $config['primary']['tables'] = array_merge($config['primary']['tables'],$tables);
            } else if((strcasecmp($k, 'where') == 0)) {
                if(!empty($v)) $config['primary']['where'] = $v;
            } else if((strcasecmp($k, 'step') == 0)) {
                if(!empty($v)) $config['primary']['step'] = intval($v);
            } else if(($datatype = stristr($k, '.where', true)) !== false) {
                if(!empty($v)) $config['primary']['wheres'][$datatype] = $v;
            } else if(($table = stristr($k, '.range', true)) !== false) {
                if(!empty($v)) $config['primary']['ranges'][$table] = explode(',',$v);
            } else {
                $field = self::getField($v);
                if ($field === false) {
                    echo "$k set error in configuration [primary].\n";
                    return false;
                }
                $config['primary']['fields'][$k] = $field;
            }
        }

        // secondary
        if(isset($ini['secondary']) &&  !empty($ini['secondary'])) {
            $config['secondary']['tables'] = array();
            foreach($ini['secondary'] as $k => $v) {
                if (strncmp($k, "DB.", 3) == 0) {
                    $tables = self::getSecondaryTables($k, $v);
                    if ($tables === false) {
                        echo "$k set error in configuration [secondary].\n";
                        return false;
                    }
                    $config['secondary']['tables'] = array_merge($config['secondary']['tables'],$tables);
                } else {
                    $field = self::getField($v);
                    if ($field === false) {
                        echo "$k set error in configuration [secondary].\n";
                        return false;
                    }

                    $pos = strrpos($k, '.');
                    if($pos === false) {
                        echo "$k syntax error in configuration [secondary].\n";
                        return false;
                    }
                    $tablename = substr($k, 0, $pos);
                    $fieldname = substr($k, $pos+1);
                    $config['secondary'][$tablename][$fieldname] = $field;
                }
            }
        }

        // process
        if(isset($ini['process']) && !empty($ini['process'])) {
            foreach($ini['process'] as $k => $v) {
                $procs = array();
                $vv = explode(')', $v);
                foreach ($vv as $vvv) {
                    $vvv = trim($vvv);
                    if(empty($vvv)) continue;
                    $pos = strpos($vvv,"(");
                    if($pos === false) {
                        echo "$k set error in [process].\n";
                        return false;
                    }
                    $funcname = substr($vvv, 0, $pos);
                    $funcname = trim($funcname);
                    $funcarg = substr($vvv, $pos+1);
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
                    $func[0] = $funcname;
                    $func[1] = $funcargs;
                    array_push($procs, $func);
                }
                $config['process'][$k] = $procs;
            }
        }

        // convert
        if(isset($ini['convert']) && !empty($ini['convert'])) {
            $config['convert'] = $ini['convert'];
        }
        
        //elastic
        if(isset($ini['elastic']) && !empty($ini['elastic'])) {
            $config['elastic'] = $ini['elastic'];
        }

        return $config;
    }
    
    /**
     * 数据采集初始化。
     * @param string $datatype  数据类型
     * @param array  $primarydb 指明更新模式初始化时只连接哪个primary db，格式为: 
     *               array('host'=>localhost,'port'=>3306,'user'=xxx,'password'=***,'db'=dbname)
     * @return boolean 
     */
    public function init($datatype='', $primarydb=NULL) 
    {
        // 和cache服务器建立连接
        if(isset($this->config['cache'])) {
            $this->cache = new Redis();
            $conn = $this->cache->pconnect($this->config['cache']['host'], $this->config['cache']['port']);
            if ($conn === false) {
                $this->cache = NULL;
                $this->errorinfo = "connect cache server failure.";
                $this->writeLog($this->errorinfo);
                return false;
            }
        }
        
        // 和相关数据库服务器建立连接，更新模式下只和指定的主库、全部辅库、searchdb建立连接
        // 创建全部索引模式下采用非持久连接，但需要设置wait_timeout=28800s
        // 索引更新模式下采用持久连接，这样是由于数据库连接释放很慢，避免创建更多的连接。
        $pdb = '';
        if($this->mode == self::MODE_UPDATE) {
            if(empty($primarydb)) {
                $this->errorinfo = "primary db isn't set on update mode.";
                $this->writeLog($this->errorinfo);
                return false;
            }
            
            foreach ($this->config['db'] as $dbname => $dsn) {
                if($primarydb['host'] == $dsn['host'] && $primarydb['port'] == $dsn['port'] && 
                   $primarydb['user'] == $dsn['user'] && $primarydb['password'] == $dsn['password'] &&
                   $primarydb['db'] == $dsn['db']) {
                       $pdb = $dbname;
                       break;
                   }
            }
            
            if(empty($pdb)) {
                $this->errorinfo = "primary db set error on update mode.";
                $this->writeLog($this->errorinfo);
                return false;
            }
        }
        
        foreach ($this->config['db'] as $dbname => $dsn) {
            $isPersistent = false; // 是否采用持久连接数据库
            $waitTimeout = 28800;  // MySQL保持空闲连接的最大时间
            if($this->mode == self::MODE_UPDATE) {
                $needInit = 0;
                if($pdb != $dbname) {
                    foreach($this->config['secondary']['tables'] as $dbname2) {
                        if($dbname == $dbname2) {
                            $needInit = 1;
                            break;
                        }
                    }
                
                    if(!$needInit) continue;
                }
                
                // 在索引更新模式下采用持久连接，wait_timeout采用MySQL设置值。
                $isPersistent = true;
                $waitTimeout = 0;
            }
            
            $dao = new DAO($dsn);
            if($dao->connect($isPersistent, $waitTimeout) === false) {
                $error = $dao->getErrorInfo();
                $this->errorinfo = "connect $dbname failure: $error";
                $this->writeLog($this->errorinfo);
                return false;
            }
            $this->daos[$dbname] = $dao;
        }
        
        // 预处理search表的insert语句
        $cols = array();
        foreach ($this->config['primary']['fields'] as $fieldname => $field) {
            if($field['type'] == 'foreign') continue;
            if(isset($field['alias']) && !empty($field['alias']))
                array_push ($cols, $field['alias']);
            else
                array_push ($cols, $fieldname);
        }
        
        foreach ($this->config['secondary'] as $tablename => $table) {
            if($tablename == 'tables') continue;
            foreach ($table as $fieldname => $field) {
                if($field['type'] == 'foreign') continue;
                if(isset($field['alias']) && !empty($field['alias']))
                    array_push ($cols, $field['alias']);
                else
                    array_push ($cols, $fieldname);
            }
        }
        
        // 对处理记录时会增加字段
        if(isset($this->config['process']) && !empty($this->config['process'])) {
            $proc = $this->config['process'];
            foreach($proc as $fieldname => $funcs) {
                if(!in_array($fieldname,$cols))
                    array_push ($cols, $fieldname);
            }
        }
        
        // 处理初始化
        try {
            $dataName = $this->config['data']['name']. $this->processorFixStr;
            $dataType = '';
            if(isset($this->config['data']['type']) && !empty($this->config['data']['type']))
                $dataType = $this->config['data']['type'];
            if(!empty($datatype))
                $dataType = $datatype;
            
            $convArgs = NULL;
            $proc = NULL;
            if(isset($this->config['convert']) && !empty($this->config['convert']))
                $convArgs = $this->config['convert'];
            if(isset($this->config['process']) && !empty($this->config['process']))
                $proc = $this->config['process'];
            $this->processor = new Process($dataName, $dataType, $convArgs, $this->mode, $proc);
            $this->dataname = $dataName;
            $this->datatype = $dataType;
        } catch (Exception $e) {
            $this->errorinfo = $e->getMessage();
            $this->writeLog($this->errorinfo);
            return false;
        }
        
        // 对处理函数进行检查
        if(isset($this->config['process'])) {
            foreach ($this->config['process'] as $fieldname => $funcs) {
                foreach ($funcs as $func) {
                    if(!method_exists('Process', $func[0])) {
                        $this->errorinfo = "process funciton $func[0] is undefine in field $fieldname";
                        $this->writeLog($this->errorinfo);
                        return false;
                    }
                }
            }
        }
            
        return true;
    }
    
    public function free()
    {
        if($this->mode === self::MODE_BUILD) {
            foreach ($this->daos as $dao) {
                $dao->disconnect();
            }
        }
        
        if($this->cache !== NULL) {
            $this->cache->close();
        }
        
        $this->processor = NULL;
    }
    
    public function getErrorInfo() 
    {
        return $this->errorinfo;
    }
    
    public function writeLog($msg) 
    {
        error_log(date('Y-m-d H:i:s') . " " . $msg . "\n", 3, $this->logpath);
    }
    
    public function getFieldsByFK($table,$fk,$fkv,$cols)
    {
        if(!empty($this->datatype)) { 
            // 先用datatype.tablename检测是否存在对应的DB，如果不存在则采用tablename对应的DB
            $fulltable = $this->datatype . '.' . $table;
            if(isset($this->config['secondary']['tables'][$fulltable]))
                $dbname = $this->config['secondary']['tables'][$fulltable];
            else
                $dbname = $this->config['secondary']['tables'][$table];
        } else {
            $dbname = $this->config['secondary']['tables'][$table];
        }
        
        $dao = $this->daos[$dbname];
        $cache = $this->cache;
        $expire = $this->config['cache']['expire'];
        
        if($fkv === '' || $fkv === NULL) { // 如果外键值为空，则外键关联表里提取的字段值都为NULL
            foreach ($cols as $col) {
                $r[$col] = NULL;
            }
            return $r;
        }
        
        if($cache !== NULL && $this->mode == self::MODE_BUILD) { // 重建模式先从cache里取，而更新模式下则不从cache里取
            $key = $dbname . $table . $fk . $fkv;
            $key = $dbname . ':' . $table . ':' . sha1($key);
            $value = $cache->get($key);
            if($value !== false) {
                return unserialize($value);
            }
        }

        // cache里没有则从数据库里读取
        $r = $dao->queryByFK($table,$fk,$fkv,$cols);
        if($r === false) {
            $this->errorinfo = $dao->getErrorInfo();
            return false;
        }
        
        if(empty($r)) { // 根据外键查询的结果为空，则外键关联表里提取的字段值都为NULL
            foreach ($cols as $col) {
                $r[$col] = NULL;
            }
            return $r;
        }
        
        // 把结果存到cache，并设置过期时间
        if($cache !== NULL && $this->mode == self::MODE_BUILD) {
            $value = serialize($r);
            $cache->set($key,$value);
            if($expire > 0)
                $cache->expire($key, $expire);
        }

        return $r;
    }
    
    public function addFkFields($priRec)
    {
        $record = array();
        $result = array();
        
        //把主表记录中字段都入栈
        foreach($this->config['primary']['fields'] as $name => $meta) {
            $field = array();
            if($meta['type'] != 'extern') {
                $field['name'] = $name;          
                $field['value'] = $priRec[$name]; 
                foreach ($meta as $n => $v)
                   $field[$n] = $v;
                array_push($record, $field);
            }
        }
        
        while(($field = array_pop($record)) !== NULL) {
            if($field['type'] == 'foreign' || $field['type'] == 'foreignormal' || ($field['type'] == 'primary' && isset($field['fk_table']))) {
                if($field['type'] == 'primary' || $field['type'] == 'foreignormal') {
                    if(isset($field['alias']) && !empty($field['alias']))
                        $result[$field['alias']] = $field['value'];
                    else
                        $result[$field['name']] = $field['value'];
                } 
               
                $fk_table = $field['fk_table'];
                $fk_field = $field['fk_field'];
                $fk_value = $field['value'];
                
                $fk_fields = array();
                if(!empty($this->datatype)) { 
                    // 先用datatype.tablename检测是否存在对应的字段，如果不存在则采用tablename对应的字段
                    $fulltable = $this->datatype . '.' . $fk_table;
                    if(isset($this->config['secondary'][$fulltable]))
                        $f = $this->config['secondary'][$fulltable];
                    else
                        $f = $this->config['secondary'][$fk_table];
                } else {
                    $f = $this->config['secondary'][$fk_table];
                }
               
                foreach ($f as $n => $v) {
                    array_push($fk_fields, $n);
                }
                
                $r = $this->getFieldsByFK($fk_table, $fk_field, $fk_value, $fk_fields);
                if($r === false) 
                    return false;
                
                //把根据外键查询得到的字段入栈
                foreach($f as $name => $meta) {
                    $field = array();
                    $field['name'] = $name;          
                    $field['value'] = $r[$name]; 
                    foreach ($meta as $n => $v)
                        $field[$n] = $v;            
                    array_push($record, $field);
                }
            } else {
                if(isset($field['alias']) && !empty($field['alias']))
                    $result[$field['alias']] = $field['value'];
                else
                    $result[$field['name']] = $field['value'];
            }
        }
        
        return $result;
    }
    
    // 支持两种方式对记录的处理：
    // (1).根据提供与业务名同名的处理类来处理，类中的方法名和字段名相同。
    // (2).根据配置文件中设置处理方法来进行处理。
    public function processRecord($record, $table)
    {
        // 把需要处理的外部字段都加入到record中
        foreach($this->config['primary']['fields'] as $name => $field) {
            if($field['type'] == 'extern') {
                $record[$name] = '';
            }
        }
        
        // 对记录进行转换处理
        $record = $this->processor->convert($record, $table);
        if($record === false) {
            $this->errorinfo = $this->processor->getErrorInfo();
            return false;
        } else if(empty($record)){
            return $record;
        }
         
        // 再进行通用处理，在配置文件配置的处理
        if(!isset($this->config['process']) || empty($this->config['process']))
            return $record;
        $record = $this->processor->exec($record, $table);
        if($record === false) {
            $this->errorinfo = $this->processor->getErrorInfo();
            return false;
        }
        
        return $record;
    }
    
    public function insertRecord($record,$id)
    {
        $ip        = $this->config['elastic']['host'];
        $port      = $this->config['elastic']['port'];
        $indexName = $this->config['elastic']['index'];
        $indexType = $this->config['elastic']['type'];
        
        if($this->datatype == 'shopsold' || $this->datatype == 'bookstallsold') { //已售商品搜索
            $indexName = $this->config['elastic']['index_sold'];
        }
        
        if(empty($record)) {
            return false;
        }
        $record = array_change_key_case($record, CASE_LOWER);
        $result = ElasticSearchModel::indexDocument($ip, $port, $indexName, $indexType, $record, $id);
        if(!$result) {
            $this->errorinfo = 'error elasticsearch config';
            $this->writeLog($this->errorinfo);
            return false;
        }
        if(is_array($result) && isset($result['created']) && !$result['created']) { // 插入记录的主键重复，记录日志。
            $this->errorinfo = "Duplicate entry '". $id. "' for key 'PRIMARY'";
            $this->writeLog($this->errorinfo);
        }
        return true;
    }
        
    // 根据记录主键从table获得记录。$pk可以是字符串或数组。返回记录数组。
    public function getRecord($fromtable, $pk)
    {
        $tables = $this->config['primary']['tables'];
        $fields = $this->config['primary']['fields'];
        $cols = array();
        $id = '';
        
        foreach($fields as $fieldname => $field) {
            if($field['type'] != 'extern')
                array_push($cols, $fieldname);
            if($field['type'] == 'primary') {
                if(empty($id)) {
                    $id = $fieldname;
                } else {
                    $this->errorinfo = "primary key is duplicate";
                    $this->writeLog($this->errorinfo);
                    return false;
                }
            }
        }
        
        if(empty($id)) {
            $this->errorinfo = "primary key isn't set";
            $this->writeLog($this->errorinfo);
            return false;
        }
        
        $fromdb = '';
        foreach($tables as $table) {
            foreach($table as $tablename => $dbname) {
                if($tablename == $fromtable) {
                    $fromdb = $dbname;
                    break;
                }
            }
            if(!empty($fromdb)) break;
        }
        
        if(empty($fromdb)) {
            $this->errorinfo = "$fromtable isn't primary table.";
            $this->writeLog($this->errorinfo);
            return false;
        }
        
        $dao = $this->daos[$fromdb];
        $resultset = $dao->queryByList($fromtable, $id, $pk, $cols);
        if($resultset === false) {
            $this->errorinfo = $dao->getErrorInfo();
            $this->writeLog($this->errorinfo);
            return false;
        }
        
        $records = array();
        foreach($resultset as $row) {
            $rid = $row[$id];
            $record = $this->addFkFields($row);
            if($record === false) {
                $this->writeLog("record[{$rid}] addFkFields failure");
                $this->writeLog($dao->getErrorInfo());
                return false;
            }

            $record = $this->processRecord($record, $fromtable);
            if($record === false) {
                $this->writeLog("record[{$rid}] process failure");
                return false;
            } else if(empty ($record)) {
                $this->writeLog("record[{$rid}] filter.");
                continue;  
            }

//            if($this->insertRecord($record,$record[$id]) === false) {
//                $this->writeLog("record[{$rid}] insert failure");
//                return false;
//            }

            $this->writeLog("record[{$rid}] done.");
            array_push($records, $record);
        }

        return $records;
    }
    
    public function getOneTable($db,$table,$id,$cols)
    {
        $dao = $this->daos[$db];
        $step = $this->config['primary']['step'];
        $wheres = $this->config['primary']['wheres'];
        $ranges = $this->config['primary']['ranges'];
        
        $min = NULL;
        $max = NULL;
        if(isset($ranges[$table]) && !empty($ranges[$table])) {
            $min = intval(trim($ranges[$table][0]));
            if(isset($ranges[$table][1]) && !empty($ranges[$table][1]))
                $max = intval(trim($ranges[$table][1]));
        }
        
        if($min === NULL || $max === NULL) {
            $range = $dao->getIDRange($table, $id);
            if($range === false) {
                $this->errorinfo = $dao->getErrorInfo();
                return false;
            }
            if($min === NULL) $min = $range[0];
            if($max === NULL) $max = $range[1];
        }
        
        $this->writeLog("table [{$table}] id range: $min - $max, step: $step");
        
        if(isset($wheres[$this->datatype]) && !empty($wheres[$this->datatype]))
            $where = $wheres[$this->datatype];
        else
            $where = $this->config['primary']['where'];
        
        if(!empty($where)) {
            $this->writeLog("table [{$table}] where: $where");
        }

        $resulttotal = 0;
        $start = $min;
        while($start <= $max) {
            $end = $start + $step;
            if($end > $max) $end = $max;
            $resultset = $dao->queryByRange($table, $id, $start, $end, $cols, $where);
            if($resultset === false) {
                $this->errorinfo = $dao->getErrorInfo();
                return false;
            }
            $resultnum = count($resultset);
            $resulttotal += $resultnum;
            $this->writeLog("get records: $start - $end, number: $resultnum, total: $resulttotal");
            $start = $end + 1;
            
            foreach($resultset as $row) {
                $rid = $row[$id];
                $record = $this->addFkFields($row);
                if($record === false) {
                    $this->writeLog("record[{$rid}] addFkFields failure");
                    $this->writeLog($dao->getErrorInfo());
                    return false;
                }
                
                $record = $this->processRecord($record, $table);
                if($record === false) {
                    $this->writeLog("record[{$rid}] process failure");
                    $this->errornum++;
                    continue; //记录处理失败，只过滤掉该记录，不退出。
                    //return false;
                } else if(empty ($record)) {
                    $this->filternum++;
                    //$this->writeLog("record[{$rid}] filter.");
                    continue;  
                }
                
                if($this->insertRecord($record,$record[$id]) === false) {
                    $this->writeLog("record[{$rid}] insert failure");
//                    return false;
                }
                
                //$this->writeLog("record[{$rid}] done.");
            }
        }
        
        return $resulttotal;
    }
    
    public function getAllTables($allowTables=array())
    {
        $tables = $this->config['primary']['tables'];
        $fields = $this->config['primary']['fields'];
        $cols = array();
        $id = '';
        
        foreach($fields as $fieldname => $field) {
            if($field['type'] != 'extern')
                array_push($cols, $fieldname);
            if($field['type'] == 'primary') {
                if(empty($id)) {
                    $id = $fieldname;
                } else {
                    $this->errorinfo = "primary key is duplicate";
                    $this->writeLog($this->errorinfo);
                    return false;
                }
            }
        }
        
        if(empty($id)) {
            $this->errorinfo = "primary key isn't set";
            $this->writeLog($this->errorinfo);
            return false;
        }
        
        if(!empty($this->datatype))
            $this->writeLog("Gather data: {$this->dataname}, type: {$this->datatype}");
        else
            $this->writeLog("Gather data: {$this->dataname}");
         
        if(!empty($allowTables)) {
            $fromTables = implode(', ', $allowTables);
            $this->writeLog("From tables: $fromTables");
        }
        
        $total = 0;
        $totalTime = 0.0;
        foreach($tables as $table) {
            foreach($table as $tablename => $dbname) {
                if(!empty($allowTables) && array_search($tablename, $allowTables) === false) //过滤掉不导出的primary tables
                    continue;
                $this->writeLog("Gathering from {$dbname}.{$tablename}, primary key: $id ...");
                $startTime = microtime(TRUE);
                $num = $this->getOneTable($dbname, $tablename, $id, $cols);
                if($num === false) return false;
                $total += $num;
                $endTime = microtime(TRUE);
                $time = $endTime - $startTime;
                $totalTime += $time;
                $time = sprintf("%01.3f", $time);
                $totalTimes = sprintf("%01.3f", $totalTime);
                $this->writeLog("Gather records from {$dbname}.{$tablename}: $num, total: $total, filter: {$this->filternum}, error: {$this->errornum}, time: {$time}s, totalTime: {$totalTimes}s");
            }
        }
        
        return true;
    }

}

?>
