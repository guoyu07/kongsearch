<?php
    /*****************************************
     * author: xinde
     * 
     * 删除6个月前消息
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    $logName = 'delMessage_' . date("Y_m_d");
    $logDir = '/data/kongsearch_logs/deleteIndexData';
    $logFile = $logDir . '/' . $logName . '.log';
    is_dir($logDir) || mkdir($logDir, 0755, true);

    $processCount = `ps -ef | grep 'delMessage' | grep -v grep | grep -v '/bin/sh' | grep -v 'vi' | grep -v 'tail' | wc -l`;
    if ($processCount > 1) {
        noticeLog("已经有正在运行的程序:delMessage !!!");
        exit;
    }

    ini_set('memory_limit', '1024M');
    set_time_limit(0);

    noticeLog("============================start[" . date('Y-m-d H:i:s', time()) . "]===========================");
    
    $ip = '192.168.1.105';
    $port = '9500';
    $indexName = 'message';
    $indexType = 'message';

    $limitTime = strtotime(date('Y-m-d H:i:s', strtotime("-6 month")));
    $noneGetTimes = 0;
    $deleteLine = 0;
    while(true) {
        $queryStr = '{"filter":{"bool":{"must":[{"range":{"sendtime":{"to":"'. $limitTime. '"}}}]}},"size":"10000","from":"0"}';
        $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($ip, $port, $indexName, $indexType, $queryStr));
        if(!isset($result['status']) || !$result['status'] || empty($result['data'])) {
            sleep(100);
            ++$noneGetTimes;
            continue;
        }
        $noneGetTimes = 0;
        foreach($result['data'] as $data) {
            $messageid = $data['messageid'];
            if(!trim($messageid)) {
                noticeLog("Get Error!");
                continue;
            }
            ElasticSearchModel::deleteDocument($ip, $port, $indexName, $indexType, $messageid);
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