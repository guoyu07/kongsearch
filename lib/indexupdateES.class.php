<?php

require_once 'ElasticSearch.php';
require_once 'unihan.php';

class IndexUpdateES
{
    private $config;
    private $indexconfig;
    private $errorInfo;
    private $indexname;
    private $processObj;

    public function __construct($indexname, $config)
    {
        $this->config = $config;
        $this->errorInfo = '';
        $this->indexname = $indexname;
        
        if(isset($config[$indexname]) && !empty($config[$indexname])) 
            $this->indexconfig = $config[$indexname];
        else
            throw new Exception("$indexname is invalid.");
        
        $className = 'indexupdate_es_'. $this->indexname;
        $processFileName = dirname(dirname(__FILE__)). '/process/'. $className. '.php';
        if(file_exists($processFileName)) {
            require_once $processFileName;
            $this->processObj = new $className($config);
        } else {
            throw new Exception("$processFileName is unexists.");
        }
        
    }
    
    public function __destruct() 
    {

    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    /**
     * 获得索引更新配置
     *  config = array(
     *                 logpath => '',
     *                 redis => '',
     *                 indexname => array(
     *                                    logpath => '',
     *                                    redis => '',
     *                                    'auth'      => array(user => array(password,old_password),...)
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
                if(strcasecmp($k, 'redis') == 0 && !empty($v)) {
                    $config['redis'] = explode(':', $v);       
                    if(isset($config['redis'][1]))
                        $config['redis'][1] = intval($config['redis'][1]);
                    else
                        $config['redis'][1] = 6379;
                    if(isset($config['redis'][2])) 
                        $config['redis'][2] = intval($config['redis'][2]); 
                } else if(strcasecmp($k, 'logpath') == 0 && !empty($v)) {
                    $config['logpath'] = $v;
                } else if(strcasecmp($k, 'trust') == 0 && !empty($v)) {
                    $config['trust'] = $v;
                } else if(strcasecmp($k, 'blacklist.press') == 0 && !empty($v)) {
                    $config['blacklist.press'] = $v;
                } else if(strcasecmp($k, 'blacklist.author') == 0 && !empty($v)) {
                    $config['blacklist.author'] = $v;
                } else if(strcasecmp($k, 'vcategory.map') == 0 && !empty($v)) {
                    $config['vcategory.map'] = $v;
                }
            }
        }
        
        foreach($ini as $index => $indexcfg) {
            if($index == 'global') continue;
            
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
            
            if(isset($indexcfg['msgPrimaryKey']) && !empty($indexcfg['msgPrimaryKey'])) {
                $config[$index]['msgPrimaryKey'] = $indexcfg['msgPrimaryKey'];
            } else {
                $config[$index]['msgPrimaryKey'] = '';
            }
            
            if(isset($indexcfg['indexPrimaryKey']) && !empty($indexcfg['indexPrimaryKey'])) {
                $config[$index]['indexPrimaryKey'] = $indexcfg['indexPrimaryKey'];
            } else {
                $config[$index]['indexPrimaryKey'] = '';
            }
            
            $i = 1;
            $flag = false;
            $servers = array();
            while(true) {
                if(isset($indexcfg['server_'. $i]) && !empty($indexcfg['server_'. $i])) {
                    $flag = true;
                    $servers[] = $indexcfg['server_'. $i];
                    ++$i;
                    continue;
                } else {
                    break;
                }
            }
            if(!$flag) {
                echo "index [{$index}] servers isn't set.\n";
                return false;
            }
            $config[$index]['servers'] = $servers;
            
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
        
        return $config;
    }
    
    public function insert($msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $insertData = $this->processObj->deal($msg);
        if($insertData === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        $server = ElasticSearchModel::getServer($this->indexconfig['servers']);
        $type = $msg['type'];
        $msgPrimaryKey = isset($this->indexconfig['msgPrimaryKey']) && !empty($this->indexconfig['msgPrimaryKey']) ? $this->indexconfig['msgPrimaryKey'] : 'itemId';
        $result = ElasticSearchModel::indexDocument($server['host'], $server['port'], $this->indexname, $type, $insertData, $msg['data'][$msgPrimaryKey]);
        if($result && isset($result['created'])) {
            return true;
        } else {
            if(!$result || $result == 'NULL') {
                $this->errorInfo = "[ERROR]: ". json_encode($msg);
            } else {
                $this->errorInfo = "[ERROR]: ". json_encode($result). "  |  ". json_encode($msg);
            }
            return false;
        }
    }
    
    public function delete($msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $msgPrimaryKey = isset($this->indexconfig['msgPrimaryKey']) && !empty($this->indexconfig['msgPrimaryKey']) ? $this->indexconfig['msgPrimaryKey'] : 'itemId';
        if(!isset($msg['data'][$msgPrimaryKey]) || empty($msg['data'][$msgPrimaryKey])) {
            $this->errorInfo = "[ERROR]: the primary key isn't set.";
            return false;
        }
        $server = ElasticSearchModel::getServer($this->indexconfig['servers']);
        $type = $msg['type'];
        $result = ElasticSearchModel::deleteDocument($server['host'], $server['port'], $this->indexname, $type, $msg['data'][$msgPrimaryKey]);
        if($result && isset($result['found'])) {
            if(!$result['found']) {
                $this->errorInfo = json_encode($result);
            }
            return true;
        } else {
            if(!$result || $result == 'NULL') {
                $this->errorInfo = "[ERROR]: ". json_encode($msg);
            } else {
                $this->errorInfo = "[ERROR]: ". json_encode($result). "  |  ". json_encode($msg);
            }
            return false;
        }
    }
    
    public function modify($msg)
    {
        if(!$this->delete($msg)) {
            return false;
        }
        if(!$this->insert($msg)) {
            return false;
        }
        return true;
    }
    
    public function update($msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $msgPrimaryKey = isset($this->indexconfig['msgPrimaryKey']) && !empty($this->indexconfig['msgPrimaryKey']) ? $this->indexconfig['msgPrimaryKey'] : 'itemId';
        if(!isset($msg['data'][$msgPrimaryKey]) || empty($msg['data'][$msgPrimaryKey])) {
            $this->errorInfo = "[ERROR]: the primary key isn't set.";
            return false;
        }
        $updateData = $this->processObj->dealUp($msg);
        if($updateData === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        $server = ElasticSearchModel::getServer($this->indexconfig['servers']);
        $type = $msg['type'];
        $result = ElasticSearchModel::updateDocument($server['host'], $server['port'], $this->indexname, $type, $msg['data'][$msgPrimaryKey], $updateData);
        if($result && (isset($result['_version']) || (isset($result['status']) && $result['status'] == '404'))) {
            if(isset($result['status']) && $result['status'] == '404') {
                $this->errorInfo = json_encode($result);
            }
            return true;
        } else {
            if(!$result || $result == 'NULL') {
                $this->errorInfo = "[ERROR]: ". json_encode($msg);
            } else {
                $this->errorInfo = "[ERROR]: ". json_encode($result). "  |  ". json_encode($msg);
            }
            return false;
        }
    }
    
    public function multiupdate($msg)
    {
        if(!isset($msg['where']) || empty($msg['where']) || !is_array($msg['where'])) {
            $this->errorInfo = "[ERROR]: where condition isn't set.";
            return false;
        }
        if(!isset($msg['data']) || empty($msg['data']) || !is_array($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $indexPrimaryKey = isset($this->indexconfig['indexPrimaryKey']) && !empty($this->indexconfig['indexPrimaryKey']) ? $this->indexconfig['indexPrimaryKey'] : 'itemid';
        $server = ElasticSearchModel::getServer($this->indexconfig['servers']);
        $type = $msg['type'];
        
        $condition = array();
        foreach($msg['where'] as $k => $v) {
            $condition['filter']['must'][] = array('field' => strtolower($k), 'value' => $v);
        }
        $condition['limit'] = array('from' => 0, 'size' => 1);
        $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($server['host'], $server['port'], $this->indexname, $type, 0, array($indexPrimaryKey), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
        $searchNum = $searchNumResult['total'];
        if($searchNum > 1000000 || $searchNum == 0) {
            $this->errorInfo = 'Current Update The Search Num Is '. $searchNum;
            return true;
        }
        
        $condition['limit'] = array('from' => 0, 'size' => 1000000);
        $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($server['host'], $server['port'], $this->indexname, $type, 0, array($indexPrimaryKey), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 120));
        if(count($searchResult['data']) < 1) {
            $this->errorInfo = 'Get Search Data Failure';
            return false;
        }
        $updateData = $this->processObj->dealUp($msg);
        if($updateData === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        foreach($searchResult['data'] as $item) {
            $itemid = $item[$indexPrimaryKey];
            if(!$itemid) {
                $itemid = $item['id'];
                if(!$itemid) {
                    $this->errorInfo = "[ERROR]: the primary key has not get.";
                    return false;
                }
            }
            
            $result = ElasticSearchModel::updateDocument($server['host'], $server['port'], $this->indexname, $type, $itemid, $updateData);
            if($result && (isset($result['_version']) || (isset($result['status']) && $result['status'] == '404'))) {
                if(isset($result['status']) && $result['status'] == '404') {
                    $this->errorInfo = json_encode($result);
                }
                continue;
            } else {
                if(is_array($result)) {
                    $this->errorInfo = "[ERROR]: ". json_encode($result). "  |  ". json_encode($msg);
                } elseif (is_string($result)) {
                    $this->errorInfo = "[ERROR]: ". $result. "  |  ". json_encode($msg);
                } else {
                    $this->errorInfo = "[ERROR]: unknown => {msg=". json_encode($msg). "} , {host=". $server['host']. ",port=". $server['port']. ",indexname=". $this->indexname. ",type=". $type. ",itemid=". $itemid. ",updateData=". json_encode($updateData). "} .";
                }
                return false;
            }
        }
        return true;
    }
    
    public function custominsert($msg)
    {
        $result = $this->processObj->custominsert($this->indexconfig, $msg);
        if($result === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        return $result;
    }
    
    public function customupdate($msg)
    {
        $result = $this->processObj->customupdate($this->indexconfig, $msg);
        if($result === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        return $result;
    }
    
    public function customdeal($msg)
    {
        $result = $this->processObj->customdeal($this->indexconfig, $msg);
        if($result === false) {
            $this->errorInfo = $this->processObj->getErrorInfo();
            return false;
        }
        return $result;
    }
    
    //改为人工手动执行优化
    public function optimize($msg)
    {
        return false;
    }
    
    
}

?>
