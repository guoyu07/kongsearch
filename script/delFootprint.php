<?php
    /*****************************************
     * author: xinde
     * 
     * 我的足迹只保留最近6个月
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    $logName = 'delFootprint_' . date("Y_m_d");
    $logDir = '/data/kongsearch_logs/deleteIndexData';
    $logFile = $logDir . '/' . $logName . '.log';
    is_dir($logDir) || mkdir($logDir, 0755, true);

    $processCount = `ps -ef | grep 'delFootprint' | grep -v grep | grep -v '/bin/sh' | grep -v 'vi' | grep -v 'tail' | wc -l`;
    if ($processCount > 1) {
        noticeLog("已经有正在运行的程序:delFootprint !!!");
        exit;
    }

    ini_set('memory_limit', '1024M');
    set_time_limit(0);

    noticeLog("============================start[" . date('Y-m-d H:i:s', time()) . "]===========================");
    
    $ip = '192.168.2.200';
    $port = '9400';
    $indexName = 'footprint_shop';
    $indexType = 'footprint';

    $limitTime = strtotime(date('Y-m-d H:i:s', strtotime("-6 month")));
    $noneGetTimes = 0;
    $deleteLine = 0;
    while(true) {
        $queryStr = '{"filter":{"bool":{"must":[{"range":{"inserttime":{"to":"'. $limitTime. '"}}}]}},"size":"10000","from":"0"}';
        $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($ip, $port, $indexName, $indexType, $queryStr));
        if(!isset($result['status']) || !$result['status'] || empty($result['data'])) {
            sleep(100);
            ++$noneGetTimes;
            continue;
        }
        $noneGetTimes = 0;
        foreach($result['data'] as $data) {
            $id = $data['id'];
            if(!trim($id)) {
                noticeLog("Get Error!");
                continue;
            }
            ElasticSearchModel::deleteDocument($ip, $port, $indexName, $indexType, $id);
            ++$deleteLine;
            if($deleteLine % 10000 == 0) {
                noticeLog("Current Delete Num : {$deleteLine}");
            }
        }
        
        if($deleteLine % 10000000 == 0) {
            sleep(18000);
        }
    }
    
    noticeLog("Total Delete Num : {$deleteLine}");
    noticeLog("============================end[" . date('Y-m-d H:i:s', time()) . "]===========================");
    
    
    
    function noticeLog($msg)
    {
        global $logFile;
        echo $msg. "\n";
        file_put_contents($logFile, "[". date('Y-m-d H:i:s', time()). "]". $msg. "\n", FILE_APPEND);
    }
?>