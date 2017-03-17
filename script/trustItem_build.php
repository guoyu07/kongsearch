<?php

    /*****************************************
     * author: xinde
     * 
     * 可信任图书库数据生成
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('i:h');
    
    //获取帮助提示
    if(isset($cmdopts['h'])) {
        usage($argv[0]);
        exit;
    }
    
    $index = 'trustItem';
    
    $logPath = '/data/kongsearch_logs/trustItem';
    if(!is_dir($logPath)) {
        mkdir($logPath, 0777, true);
    }
    $logFile = $logPath. '/'. $index. '-'. date("Y-m-d-H-i-s"). ".log";
    
    $processCount = `ps -ef | grep 'trustItem_build.php' | grep -v grep | grep -v '/bin/sh' | grep -v vi | wc -l`;
    if ($processCount > 1) {
        noticeLog(date("Y-m-d H:i:s"). " 已经有正在运行的程序:trustItem_build.php !!!\n");
        exit;
    }
    
    noticeLog("----------------------------------------------- Start [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    $index_host = '192.168.1.105';
    $index_port = '9500';
    $index_name = 'trustitem';
    $index_type = 'item';
    
    $mysql_host = '192.168.1.67';
    $mysql_port = '3306';
    $mysql_user = 'sunyutian';
    $mysql_pswd = 'sun100112';
    $mysql_db   = 'shop';
    
    $mysql_Link = mysql_pconnect($mysql_host.":".$mysql_port, $mysql_user, $mysql_pswd);
    mysql_select_db($mysql_db, $mysql_Link);
    mysql_query("SET NAMES 'utf8'", $mysql_Link);
    
    getItems();
    
    noticeLog("----------------------------------------------- End [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    /**
     * 创建索引
     */
    function getItems()
    {
        global $index_host;
        global $index_port;
        global $index_name;
        global $index_type;
        global $mysql_Link;
        
        //取主键范围
        $m_sql = "SELECT min(id) as start,max(id) as end FROM trustItem";
        $m_query = mysql_query($m_sql, $mysql_Link);
        $m_result = mysql_fetch_assoc($m_query);
        $minId = $m_result['start'];
        $maxId = $m_result['end'];
        $once = 30000;
        $startId = 0;
        $endId = 0;
        while($startId < $maxId) {
            $startId = $startId == 0 ? $minId : $startId;
            $endId = ($startId + $once - 1) > $maxId ? $maxId : ($startId + $once - 1);
            //取表数据
            $get_sql = "SELECT id,itemName,author,press,isbn FROM trustItem WHERE id BETWEEN {$startId} AND {$endId}";
            $get_query = mysql_query($get_sql, $mysql_Link);
            $insertNum = 0;
            while($get_result = mysql_fetch_assoc($get_query)) {
                $id = $get_result['id'];
                $itemname = $get_result['itemName'];
                $author = $get_result['author'];
                $press = $get_result['press'];
                $isbn = $get_result['isbn'];
                
                $doc = array();
                $doc['id'] = $id;
                $doc['itemname'] = $itemname;
                $doc['_itemname'] = $itemname;
                $doc['author'] = $author;
                $doc['_author'] = $author;
                $doc['press'] = $press;
                $doc['_press'] = $press;
                $doc['isbn'] = $isbn;
                $doc['isdeleted'] = 0;
//                echo '<pre>';
//                print_r($doc);
                ElasticSearchModel::indexDocument($index_host, $index_port, $index_name, $index_type, $doc, $id);
                ++$insertNum;
            }
            
            noticeLog("Process trustItem from {$startId} to {$endId}........................................[ OK ]  Add ". $insertNum. "\n");
            $startId += $once;
        }
    }
    
    function noticeLog($msg)
    {
        global $logFile;
        echo $msg;
        file_put_contents($logFile, $msg, FILE_APPEND);
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>