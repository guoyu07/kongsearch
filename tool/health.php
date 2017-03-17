<?php
    /*****************************************
     * author: xinde
     * 
     * 搜索集群健康状态查看脚本
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $isRepairSpider = 0;
    if(isset($cmdopts['z']) && intval($cmdopts['z']) == 1) {
        $isRepairSpider = 1;
    }
    
    if($isRepairSpider) {
        $log_path = '/data/kongsearch_logs/health_spider/';
        $log = $log_path. 'health_'. date('Y_m_d');
        $lastLog = $log_path. 'health_last'. date('Y_m_d');
        $noticeLog = $log_path. 'health_notice'. date('Y_m_d');
    } else {
        $log_path = '/data/kongsearch_logs/health/';
        $log = $log_path. 'health_'. date('Y_m_d');
        $lastLog = $log_path. 'health_last'. date('Y_m_d');
        $noticeLog = $log_path. 'health_notice'. date('Y_m_d');
    }
    
    if(!is_dir($log_path)) {
        mkdir($log_path, 0777, true);
    }
    
    $currentTime = date('Y-m-d H:i:s');
//    echo "---------------------------------------------------- {$currentTime} ----------------------------------------------------\n";
    file_put_contents($log, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
    
    //取搜索集群信息
    if($isRepairSpider) {
        $searchServers = array(
            '192.168.1.137:9700'
        );
    } else {
        $searchServers = array(
            '192.168.1.103:9800'
        );
    }
    
    $server = ElasticSearchModel::getServer($searchServers);
    $threadPoolInfo_s = ElasticSearchModel::getThreadPool($server['host'], $server['port']);
    $nodesInfo_s = ElasticSearchModel::getNodesInfo($server['host'], $server['port']);
    $threadPoolInfo_a = ElasticSearchModel::getThreadPool($server['host'], $server['port'], true);
    $nodesInfo_a = ElasticSearchModel::getNodesInfo($server['host'], $server['port'], true);
    if(!$threadPoolInfo_s || !$threadPoolInfo_a || !$nodesInfo_s || !$nodesInfo_a) {
//        echo "Error : Can Not Connect To The Search Host . \n";
        file_put_contents($log, "Error : Can Not Connect To The Search Host . \n", FILE_APPEND);
        file_put_contents($noticeLog, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
        if(!$threadPoolInfo_s) {
            file_put_contents($noticeLog, '$threadPoolInfo_s = ElasticSearchModel::getThreadPool($server[\'host\'], $server[\'port\'])'. "\n", FILE_APPEND);
        } elseif (!$threadPoolInfo_a) { 
            file_put_contents($noticeLog, '$threadPoolInfo_a = ElasticSearchModel::getThreadPool($server[\'host\'], $server[\'port\'], true)'. "\n", FILE_APPEND);
        } elseif (!$nodesInfo_s) {
            file_put_contents($noticeLog, '$nodesInfo_s = ElasticSearchModel::getNodesInfo($server[\'host\'], $server[\'port\'])'. "\n", FILE_APPEND);
        } elseif (!$nodesInfo_a) {
            file_put_contents($noticeLog, '$nodesInfo_a = ElasticSearchModel::getNodesInfo($server[\'host\'], $server[\'port\'], true)'. "\n", FILE_APPEND);
        }
        file_put_contents($noticeLog, "Error : Can Not Connect To The Search Host . \n", FILE_APPEND);
//        exit;
    }
    file_put_contents($log, "\n*** Current Thread Pool Info : \n", FILE_APPEND);
    file_put_contents($log, "{$threadPoolInfo_s}\n", FILE_APPEND);
    file_put_contents($log, "*** Current Nodes Info : \n", FILE_APPEND);
    file_put_contents($log, "{$nodesInfo_s}\n", FILE_APPEND);
//    echo "\n*** Current Thread Pool Info : \n";
//    echo "{$threadPoolInfo_s}\n";
//    echo "*** Current Nodes Info : \n";
//    echo "{$nodesInfo_s}\n";
    
    //取搜索调用信息
    $redis_host = '192.168.1.137';
    $redis_port = '6379';
    $statisticsLink  = new Redis();
    if ($statisticsLink->connect($redis_host, $redis_port) === false) {
//        echo "Count Not Connect Redis {$redis_host}:{$redis_port}. \n";
        file_put_contents($log, "Count Not Connect Redis {$redis_host}:{$redis_port}. \n", FILE_APPEND);
        exit;
    }
    $dateStr = date("Ymd");
    $key = 'kfzsearch_'. $dateStr. '*';
    $resultAll = $statisticsLink->keys($key);
    if(!$resultAll) {
        file_put_contents($log, "The Redis Has Null. \n", FILE_APPEND);
//        echo "The Redis Has Null. \n";
        exit;
    }
//    echo "*** Current Statistics : \n";
    file_put_contents($log, "*** Current Statistics : \n", FILE_APPEND);
    $totalNum = 0;
    $statisticsArr = array();
    $orderArr = array();
    foreach($resultAll as $key) {
        $num = $statisticsLink->get($key);
        $statistics = array();
        $statistics['key'] = $key;
        $statistics['num'] = $num;
        $statisticsArr[] = $statistics;
        $orderArr[] = $num;
        $totalNum += $num;
    }
    array_multisort($orderArr, SORT_DESC, $statisticsArr);
    foreach($statisticsArr as $value) {
//        echo "    ". $value['key']. ' => '. $value['num']. "\n";
        file_put_contents($log, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
//    echo "    Total => ". $totalNum. "\n";
    file_put_contents($log, "    Total => ". $totalNum. "\n", FILE_APPEND);
    
    if(!file_exists($lastLog)) {
        //存当前各信息
        file_put_contents($lastLog, "<?php \n\t\$lastStatisticsArr = ". var_export($statisticsArr, true). ";\n\t\$lastThreadPoolInfo_s = \"{$threadPoolInfo_s}\";\n\t\$lastNodesInfo_s = \"{$nodesInfo_s}\";\n\t\$lastThreadPoolInfo_a = ". var_export($threadPoolInfo_a, true). ";\n\t\$lastNodesInfo_a = ". var_export($nodesInfo_a, true). ";\n?>");
        exit;
    }
    if(!$threadPoolInfo_s || !$threadPoolInfo_a || !$nodesInfo_s || !$nodesInfo_a) {
        exit;
    }
    
    //加载上一次执行结果保存文件
    require_once $lastLog;
    global $lastStatisticsArr;
    global $lastThreadPoolInfo_s;
    global $lastNodesInfo_s;
    global $lastThreadPoolInfo_a;
    global $lastNodesInfo_a;
//    echo "*** Last Statistics : \n";
    file_put_contents($log, "*** Last Statistics : \n", FILE_APPEND);
    $lastTotal = 0;
    foreach($lastStatisticsArr as $value) {
//        echo "    ". $value['key']. ' => '. $value['num']. "\n";
        $lastTotal += $value['num'];
        file_put_contents($log, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
//    echo "    Total => ". $lastTotal. "\n";
    file_put_contents($log, "    Total => ". $lastTotal. "\n", FILE_APPEND);
    
    //对比搜索调用
//    echo "*** Compare Statistics : \n";
    file_put_contents($log, "*** Compare Statistics : \n", FILE_APPEND);
    $compareStatisticsArr = array();
    $compareOrderArr = array();
    foreach ($statisticsArr as $v1) {
        $k1 = $v1['key'];
        $n1 = $v1['num'];
        foreach ($lastStatisticsArr as $v2) {
            $k2 = $v2['key'];
            $n2 = $v2['num'];
            if ($k1 == $k2) {
                $tmpArr = array();
                $tmpArr['key'] = $k1;
                $tmpArr['num'] = $n1 - $n2;
                $compareOrderArr[] = $n1 - $n2;
                $compareStatisticsArr[] = $tmpArr;
                break;
            }
        }
    }
    array_multisort($compareOrderArr, SORT_DESC, $compareStatisticsArr);
    $compareTotal = $totalNum - $lastTotal;
    foreach($compareStatisticsArr as $value) {
//        echo "    ". $value['key']. ' => '. $value['num']. "\n";
        file_put_contents($log, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
//    echo "    Total => ". $compareTotal. "\n";
    file_put_contents($log, "    Total => ". $compareTotal. "\n", FILE_APPEND);
    
    //存当前各信息
    file_put_contents($lastLog, "<?php \n\t\$lastStatisticsArr = ". var_export($statisticsArr, true). ";\n\t\$lastThreadPoolInfo_s = \"{$threadPoolInfo_s}\";\n\t\$lastNodesInfo_s = \"{$nodesInfo_s}\";\n\t\$lastThreadPoolInfo_a = ". var_export($threadPoolInfo_a, true). ";\n\t\$lastNodesInfo_a = ". var_export($nodesInfo_a, true). ";\n?>");
    
    //同上一次状态比对
    $noticeFlag = false;
    foreach($threadPoolInfo_a as $k => $v) {
        if($k == 0) {
            continue;
        }
        $searchRejected = $v['search.rejected'];
        $lastSearchRejected = $lastThreadPoolInfo_a[$k]['search.rejected'];
        if($searchRejected > $lastSearchRejected) {
            $noticeFlag = true;
            break;
        }
    }
    
    //记录问题信息
    if(!$noticeFlag) {
        exit;
    }
    file_put_contents($noticeLog, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Last Thread Pool Info : \n", FILE_APPEND);
    file_put_contents($noticeLog, "{$lastThreadPoolInfo_s}\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Current Thread Pool Info : \n", FILE_APPEND);
    file_put_contents($noticeLog, "{$threadPoolInfo_s}\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Last Nodes Info : \n", FILE_APPEND);
    file_put_contents($noticeLog, "{$lastNodesInfo_s}\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Current Nodes Info : \n", FILE_APPEND);
    file_put_contents($noticeLog, "{$nodesInfo_s}\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Last Statistics : \n", FILE_APPEND);
    foreach($lastStatisticsArr as $value) {
        file_put_contents($noticeLog, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
    file_put_contents($noticeLog, "    Total => ". $lastTotal. "\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Current Statistics : \n", FILE_APPEND);
    foreach($statisticsArr as $value) {
        file_put_contents($noticeLog, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
    file_put_contents($noticeLog, "    Total => ". $totalNum. "\n", FILE_APPEND);
    file_put_contents($noticeLog, "\n*** Compare Statistics : \n", FILE_APPEND);
    foreach($compareStatisticsArr as $value) {
        file_put_contents($noticeLog, "    ". $value['key']. ' => '. $value['num']. "\n", FILE_APPEND);
    }
    file_put_contents($noticeLog, "    Total => ". $compareTotal. "\n", FILE_APPEND);
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
?>