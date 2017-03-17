<?php

require_once 'iao.php';
require_once 'dao.php';
require_once 'sharding.php';
require_once 'gather.class.php';

class IndexUpdate 
{
    private $config;
    private $indexconfig;
    private $errorInfo;
    private $indexname;
    private $rtIAO;
    private $distIAO;
    private $dao;

    public function __construct($indexname, $config) {
        $this->config = $config;
        $this->errorInfo = '';
        $this->indexname = $indexname;
        
        if(isset($config[$indexname]) && !empty($config[$indexname])) 
            $this->indexconfig = $config[$indexname];
        else
            throw new Exception("$indexname is invalid.");
        
        // 连接实时索引节点
        $this->rtIAO = new IAO($this->indexconfig['rtindex']['host'], $this->indexconfig['rtindex']['port']);
        if($this->rtIAO->connect(true) === false) {
            $this->errorInfo = $this->rtIAO->getErrorInfo();
            throw new Exception($this->errorInfo);
        }
        
        // 连接分布式索引节点
        $this->distIAO = new IAO($this->indexconfig['distindex']['host'], $this->indexconfig['distindex']['port']);
        if($this->distIAO->connect(true) === false) {
            $this->errorInfo = $this->distIAO->getErrorInfo();
            throw new Exception($this->errorInfo);
        }
        
        // 连接Search DB
//        $this->dao = new DAO($this->indexconfig['searchdb']);
//        if($this->dao->connect(true, 0) === false) {
//            $this->errorInfo = $this->dao->getErrorInfo();
//            throw new Exception($this->errorInfo);
//        }
    }
    
    public function __destruct() 
    {
        //$this->rtIAO->disconnect();
        //$this->distIAO->disconnect();
        //$this->dao->disconnect();
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    /**
     * 获得索引更新配置
     *  config = array(
     *                 jobservers => '...',
     *                 logpath => '',
     *                 redis => '',
     *                 activeindex => '',
     *                 indexname => array(
     *                                    jobservers => '...',
     *                                    logpath => '',
     *                                    redis => '',
     *                                    'datatable' => ,
     *                                    'datagather' => 
     *                                    'searchdb' => array(host,port,user,password,db,table,pk), 
     *                                    'distindex' => array(host,port,name,api-port),
     *                                    'rtindex'   => array(host,port,name,id,diskindex),
     *                                    'distnodes' => ...
     *                                    'auth'      => array(user => array(password,old_password),...)
     *                                    'gatherconfig' => ....
     *                 shard => array()
     * )
     * ) 
     */
    public static function getConfig($inifile)
    {
        $config = array();
        $ini = parse_ini_file($inifile, true);
        if($ini === false) {
            echo "can't parse ini file\n";
            return false;
        }
        
        if(isset($ini['global']) && !empty($ini['global'])) {
            foreach($ini['global'] as $k => $v) {
                if(strcasecmp($k, 'jobservers') == 0 && !empty($v)) {
                    $config['jobservers'] = $v;
                } else if(strcasecmp($k, 'redis') == 0 && !empty($v)) {
                    $config['redis'] = explode(':', $v);       
                    if(isset($config['redis'][1]))
                        $config['redis'][1] = intval($config['redis'][1]);
                    else
                        $config['redis'][1] = 6379;
                    if(isset($config['redis'][2])) 
                        $config['redis'][2] = intval($config['redis'][2]); 
                } else if(strcasecmp($k, 'logpath') == 0 && !empty($v)) {
                    $config['logpath'] = $v;
                } else if(strcasecmp($k, 'activeindex') == 0 && !empty($v)) {
                    $config['activeindex'] = $v;
                }
            }
        }
        
        foreach($ini as $index => $indexcfg) {
            if($index == 'global' || $index == 'shard') continue;
            if(isset($indexcfg['jobservers']) && !empty($indexcfg['jobservers'])) {
                $config[$index]['jobservers'] = $indexcfg['jobservers'];
            } else if(isset($config['jobservers'])) {
                $config[$index]['jobservers'] = $config['jobservers'];
            } else {
                echo "index [{$index}] job servers isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['redis']) && !empty($indexcfg['redis'])) {
                $config[$index]['redis'] = explode(':', $indexcfg['redis']);
                if(isset($config['redis'][1]))
                    $config['redis'][1] = intval($config['redis'][1]);
                else
                    $config['redis'][1] = 6379;
                if(isset($config[$index]['redis'][2])) 
                    $config[$index]['redis'][2] = intval($config[$index]['redis'][2]); 
            } else if(isset($config['redis'])) {
                $config[$index]['redis'] = $config['redis'];
            } else {
                echo "index [{$index}] redis isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['logpath']) && !empty($indexcfg['logpath'])) {
                $config[$index]['logpath'] = $indexcfg['logpath'];
            } else if(isset($config['logpath'])) {
                $config[$index]['logpath'] =  $config['logpath'];
            } else {
                echo "index [{$index}] log path isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['datatable']) && !empty($indexcfg['datatable'])) {
                $config[$index]['datatable'] = $indexcfg['datatable'];
            } else {
                echo "$index datatable isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['datagather']) && !empty($indexcfg['datagather'])) {
                $config[$index]['datagather'] = $indexcfg['datagather'];
                $gatherconfig = Gather::getConfig($indexcfg['datagather']);
                if($gatherconfig === false) {
                    echo "$index gather config set error.\n";
                    return false;
                }
                $config[$index]['gatherconfig'] = $gatherconfig;
            } else {
                echo "$index datagather isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['datatype']) && !empty($indexcfg['datatype'])) {
                $config[$index]['datatype'] = explode(',', $indexcfg['datatype']);
                foreach($config[$index]['datatype'] as $i => $datatype) {
                    $config[$index]['datatype'][$i] = trim($datatype);
                }
            }
            
            if(isset($indexcfg['searchdb']) && !empty($indexcfg['searchdb'])) {
                $config[$index]['searchdb'] = explode(':', $indexcfg['searchdb']);
                if(count($config[$index]['searchdb']) != 7) {
                    echo "$index searchdb set error.\n";
                    return false;
                }
                $config[$index]['searchdb']['host']     = $config[$index]['searchdb'][0];
                $config[$index]['searchdb']['port']     = intval($config[$index]['searchdb'][1]);
                $config[$index]['searchdb']['user']     = $config[$index]['searchdb'][2];
                $config[$index]['searchdb']['password'] = $config[$index]['searchdb'][3];
                $config[$index]['searchdb']['db']       = $config[$index]['searchdb'][4];
                $config[$index]['searchdb']['table']    = $config[$index]['searchdb'][5];
                $config[$index]['searchdb']['pk']       = $config[$index]['searchdb'][6];
            } else {
                echo "$index searchdb isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['distindex']) && !empty($indexcfg['distindex'])) {
                $config[$index]['distindex'] = explode(':', $indexcfg['distindex']);
                if(count($config[$index]['distindex']) != 4) {
                    echo "$index distindex set error.\n";
                    return false;
                }
                $config[$index]['distindex']['host']     = $config[$index]['distindex'][0];
                $config[$index]['distindex']['port']     = intval($config[$index]['distindex'][1]);
                $config[$index]['distindex']['name']     = $config[$index]['distindex'][2];
                $config[$index]['distindex']['port2']    = intval($config[$index]['distindex'][3]);
            } else {
                echo "$index distindex isn't set.\n";
                return false;
            }
            
            $node = getenv("SPHINX_NODE");
            $rtindexnode = 'rtindex_'. $node;
            if(isset($indexcfg['rtindex']) && !empty($indexcfg['rtindex'])) {
                $config[$index]['rtindex'] = explode(':', $indexcfg['rtindex']);
                if(count($config[$index]['rtindex']) < 4) {
                    echo "$index rtindex set error.";
                    return false;
                }
                $config[$index]['rtindex']['host']     = $config[$index]['rtindex'][0];
                $config[$index]['rtindex']['port']     = intval($config[$index]['rtindex'][1]);
                $config[$index]['rtindex']['name']     = $config[$index]['rtindex'][2];
                $config[$index]['rtindex']['id']       = $config[$index]['rtindex'][3];
                if(isset($config[$index]['rtindex'][4])) {
                    $config[$index]['rtindex']['diskindex'] = $config[$index]['rtindex'][4];
                }
            } elseif(isset($indexcfg[$rtindexnode]) && !empty($indexcfg[$rtindexnode])) {
                $config[$index]['rtindex'] = explode(':', $indexcfg[$rtindexnode]);
                if(count($config[$index]['rtindex']) < 4) {
                    echo "$index $rtindexnode set error.";
                    return false;
                }
                $config[$index]['rtindex']['host']     = $config[$index]['rtindex'][0];
                $config[$index]['rtindex']['port']     = intval($config[$index]['rtindex'][1]);
                $config[$index]['rtindex']['name']     = $config[$index]['rtindex'][2];
                $config[$index]['rtindex']['id']       = $config[$index]['rtindex'][3];
                if(isset($config[$index]['rtindex'][4])) {
                    $config[$index]['rtindex']['diskindex'] = $config[$index]['rtindex'][4];
                }
            }else {
                echo "$index rtindex isn't set.\n";
                return false;
            }
            
            if(isset($indexcfg['distnodes']) && !empty($indexcfg['distnodes'])) {
                $config[$index]['distnodes'] = $indexcfg['distnodes'];
            } 
            
            if(isset($indexcfg['authorization']) && !empty($indexcfg['authorization'])) {
                $users = explode(',', $indexcfg['authorization']);
                foreach($users as $user) {
                    $user = trim($user);
                    $user = explode(':', $user);
                    if(count($user) == 1) {
                        $config[$index]['auth'][$user[0]]['password'] = '';
                        $config[$index]['auth'][$user[0]]['old_password'] = '';
                    } else if(count($user) == 2) {
                        $config[$index]['auth'][$user[0]]['password'] = $user[1];
                        $config[$index]['auth'][$user[0]]['old_password'] = '';
                    } else if(count($user) == 3) {
                        $config[$index]['auth'][$user[0]]['password'] = $user[1];
                        $config[$index]['auth'][$user[0]]['old_password'] = $user[2];
                    }
                }
            } 
        }
        
        if(isset($config['activeindex']) && !isset($config[$config['activeindex']])) {
            echo "active index set error.\n";
            return false;
        }
        
        $shardconfig = Sharding::getConfig($inifile);
        if($shardconfig === false) {
            echo "[shard] set error in $inifile\n";
            return false;
        }
        $config['shard'] = $shardconfig;
        
        return $config;
    }
    
    //如果一个文档先增加再删除，又增加，此时实时索引里打上了删除标记，就没法insert，只能replace。
    //参数$id可以是字符串或数组。
    public function insert($type, $id, $shardkey='', $action='REPLACE')
    {
        //同一本书既是书店和书摊的处理。
        if($type == 'bookstall' || $type == 'bookstallsold') {
            if(is_array($id)) {
                foreach($id as $k => $v) {
                    if($v >= 5000000000 ) {
                        $id[$k] = $v - 5000000000;
                    }
                }
            } else if($id >= 5000000000) {
                $id = $id - 5000000000;
            }
        }
            
        // 确定 DB、 table
        $shard = new Sharding($this->config['shard']);
        $dbinfo = $shard->getDBInfo($this->indexconfig['datatable'], $shardkey, 'master'); //主表在重建模式下从slave取，更新模式从master取数据。
        if($dbinfo === false) {
            $this->errorInfo = $shard->getErrorInfo();
            return false;
         }
        
        // 从DB、table中采集数据
        $gather = new Gather($this->indexconfig['gatherconfig'],$this->indexconfig['logpath'],Gather::MODE_UPDATE);
        if($gather->init($type, $dbinfo) === false) {
            $this->errorInfo = $gather->getErrorInfo();
            return false;
        }
        
        $records = $gather->getRecord($dbinfo['table'], $id);
        if($records === false) {
            $this->errorInfo = $gather->getErrorInfo();
            return false;
        }
        
        $gather->free();
        
        //把新增记录 insert into RTIndex，可能是批量数据
        if(empty($records)) 
            return true;
        
        $cols = array();
        foreach($records[0] as $colname => $colvalue) {
            if($colname == $this->indexconfig['rtindex']['id'])
                $colname = 'id'; //sphinx文档ID属性名为：id
            array_push($cols, $colname);
        }
        
        $colvalues = array();
        foreach($records as $record) {
            $values = array();
            foreach($record as $value) {
                array_push($values, $value);
            }
            array_push($colvalues,$values);
            unset($values);
        }
        
        if($this->rtIAO->insert($this->indexconfig['rtindex']['name'], $cols, $colvalues, $action) === false) {
            $this->errorinfo = $this->rtIAO->getErrorInfo();
            return false;
         }
        
        unset($cols);
        unset($colvalues);
        unset($records);
        return true;
    }
    
    public function delete($id, $where)
    {
        // 在索引里删除
        $r = $this->distIAO->remove($this->indexconfig['distindex']['name'], $id, $where);
        if($r === false) {
            $this->errorInfo = $this->distIAO->getErrorInfo();
            return false;
        }
        
        // 在searchDB中删除
//        if($this->dao->delete($this->indexconfig['searchdb']['table'], $id, $where, $this->indexconfig['searchdb']['pk']) === false) {
//            $this->errorInfo = $this->dao->getErrorInfo();
//            return false;
//        }
        
        return true;
    }
    
    public function modify($type, $id, $shardkey) 
    {
        // 先删除...
//        if($this->delete($id, '') === false) {
//            return false;
//        }
        $this->delete($id, '');
        
        // 再插入,如果要删除的文档在实时索引中，由于实时索引里仅仅是打了一个删除的标记，需要用新的repalce老的。
        if($this->insert($type, $id, $shardkey, 'REPLACE') === false) {
            return false;
        }
        
        return true;
    }
    
    public function update($attr, $id='', $where='')
    {
        // 先更新索引属性...
        $r = $this->distIAO->update($this->indexconfig['distindex']['name'], $attr, $id, $where);
        if($r === false) {
            $this->errorInfo = $this->distIAO->getErrorInfo();
            return false;
        }
                
        // 更新数据库中相应字段
//        if($this->dao->update($this->indexconfig['searchdb']['table'], $attr, $id, $where, $this->indexconfig['searchdb']['pk']) === false) {
//            $this->errorInfo = $this->dao->getErrorInfo();
//            return false;
//        }
        
        return true;
    }
    
    public function softdelete($id, $where)
    {
        // 在索引里删除
        $r = $this->distIAO->softdelete($this->indexconfig['distindex']['name'], $id, $where);
        if($r === false) {
            $this->errorInfo = $this->distIAO->getErrorInfo();
            return false;
        }
        
        // 在searchDB中删除
//        if($this->dao->softdelete($this->indexconfig['searchdb']['table'], $id, $where, $this->indexconfig['searchdb']['pk']) === false) {
//            $this->errorInfo = $this->dao->getErrorInfo();
//            return false;
//        }
        
        return true;
    }
    
    public function recovery($id, $where)
    {
        // 在索引里恢复
        $r = $this->distIAO->recovery($this->indexconfig['distindex']['name'], $id, $where);
        if($r === false) {
            $this->errorInfo = $this->distIAO->getErrorInfo();
            return false;
        }
        
        // 在searchDB中恢复
//        if($this->dao->recovery($this->indexconfig['searchdb']['table'], $id, $where, $this->indexconfig['searchdb']['pk']) === false) {
//            $this->errorInfo = $this->dao->getErrorInfo();
//            return false;
//        }
        
        return true;
    }
    
    public function truncate() 
    {
        return $this->rtIAO->truncate($this->indexconfig['rtindex']['name']);
    }
    
    public function flush()
    {
        return $this->rtIAO->flush($this->indexconfig['rtindex']['name']);
    }
    
    public function attach()
    {
        // 先清空实时索引，再把硬盘索引加载为实时索引
        $this->rtIAO->truncate($this->indexconfig['rtindex']['name']);
        return $this->rtIAO->attach($this->indexconfig['rtindex']['diskindex'], $this->indexconfig['rtindex']['name']);
       
    }
    
    public function optimize()
    {
        return $this->rtIAO->optimize($this->indexconfig['rtindex']['name']);
    }
    
    public function flushattrs()
    {
        return IAO::flushAttrs($this->indexconfig['distnodes']);
    }
}

?>
