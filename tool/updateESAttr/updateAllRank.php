<?php
    /*****************************************
     * author: xinde
     * 
     * 商品数据更新脚本
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('h');
    
    $log_path = '/data/kongsearch_logs/updateESAttr/';
    $log = $log_path. 'updateAllRank_'. date('Y_m_d');
    if(!is_dir($log_path)) {
        mkdir($log_path, 0777, true);
    }
    
    $searchHost = '192.168.2.19';
    $searchPort = '9800';
    $searchHostSpider = '192.168.1.137';
    $searchPortSpider = '9700';
    $searchIndex = 'item,item_sold';
    $searchIndexUnSold = 'item';
    $searchIndexSold = 'item_sold';
    $searchType = 'product';
    $maxLoad    = '45.0';
    $indexupdateQueue = "IndexUpdateES:item";
    $redis = '192.168.2.130:6379';
    $redisConf = explode(':', $redis);
    $redisLink  = new Redis();
    if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1]) === false) {
        echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}\n";
        file_put_contents($log, "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}\n", FILE_APPEND);
        exit;
    }
    
    $redis_spider = '192.168.2.28:6379';
    $redisConf_spider = explode(':', $redis_spider);
    $redisLink_spider  = new Redis();
    if($redisLink_spider->pconnect($redisConf_spider[0], $redisConf_spider[1]) === false && $redisLink_spider->pconnect($redisConf_spider[0], $redisConf_spider[1]) === false) {
        echo "Count Not Connect Redis {$redisConf_spider[0]}:{$redisConf_spider[1]}\n";
        file_put_contents($log, "Count Not Connect Redis {$redisConf_spider[0]}:{$redisConf_spider[1]}\n", FILE_APPEND);
        exit;
    }
    
    echo "Current Time : ". date("Y-m-d H:i:s"). "\n";
    file_put_contents($log, "Current Time : ". date("Y-m-d H:i:s"). "\n", FILE_APPEND);
    
    $queryStrMax = '{"filter":{"bool":{"must_not":[{"term":{"rank10":"10"}}]}},"sort":[{"itemid":{"order":"desc"}}],"size":"1","from":"0"}';
    $searchResultMax = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($searchHost, $searchPort, $searchIndex, $searchType, $queryStrMax));
    $itemIdMax = $searchResultMax['data'][0]['itemid'];
    $totalFound = $searchResultMax['total'];
    file_put_contents($log, "Current Time : ". date("Y-m-d H:i:s"). " Total Is {$totalFound} , The Max ItemId Is {$itemIdMax}\n", FILE_APPEND);
    $limitId = 0;
    $tryTimes = 0;
    $curSendNum = 0;
    while(true) {
        if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while(true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if($loadStatus) {
                    break;
                }
            }
        }
        if(!checkLoad($searchHostSpider, $searchPortSpider, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while(true) {
                sleep(60);
                $loadStatus = checkLoad($searchHostSpider, $searchPortSpider, $maxLoad);
                if($loadStatus) {
                    break;
                }
            }
        }
        $queryStr = '{"filter":{"bool":{"must":[{"range":{"itemid":{"from":"'. $limitId. '"}}}],"must_not":[{"term":{"rank10":"10"}}]}},"sort":[{"itemid":{"order":"asc"}}],"size":"10000","from":"0"}';
        $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($searchHost, $searchPort, $searchIndex, $searchType, $queryStr));
        if($searchResult['total'] == 0) {
            ++$tryTimes;
            if($tryTimes > 10) {
                break;
            }
            sleep(30);
            continue;
        }
        $tryTimes = 0;
        foreach($searchResult['data'] as $item) {
            $itemid = $item['itemid'];
            $limitId = $itemid;
            if(!$itemid) {
                break;
            }
            $salestatus = $item['salestatus'];
            echo "Current Time : ". date("Y-m-d H:i:s"). " The Max ItemId Is {$itemIdMax} , itemid : {$itemid} , salestatus : {$salestatus} , tryTimes : {$tryTimes}\n";
            file_put_contents($log, "Current Time : ". date("Y-m-d H:i:s"). " The Max ItemId Is {$itemIdMax} , itemid : {$itemid} , salestatus : {$salestatus} , tryTimes : {$tryTimes}\n", FILE_APPEND);
            if(isset($item['rank10']) && $item['rank10'] == 10) {
                continue;
            }
            if($salestatus) {
                $redisLink->rpush($indexupdateQueue, json_encode(array('index' => $searchIndexSold, 'type' => $searchType, 'action' => 'update', 'user' => 'xde', 'time' => date("Y-m-d H:i:s"), 'data' => array('itemId' => $itemid, 'rank10' => 10, 'rank100' => 100))));
                $redisLink_spider->rpush($indexupdateQueue, json_encode(array('index' => $searchIndexSold, 'type' => $searchType, 'action' => 'update', 'user' => 'xde', 'time' => date("Y-m-d H:i:s"), 'data' => array('itemId' => $itemid, 'rank10' => 10, 'rank100' => 100))));
               
//                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexSold, $searchType, $itemid, array('rank10' => 10, 'rank100' => 100));
//                ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexSold, $searchType, $itemid, array('rank10' => 10, 'rank100' => 100));
            } else {
                $redisLink->rpush($indexupdateQueue, json_encode(array('index' => $searchIndexUnSold, 'type' => $searchType, 'action' => 'update', 'user' => 'xde', 'time' => date("Y-m-d H:i:s"), 'data' => array('itemId' => $itemid, 'rank10' => 10, 'rank100' => 100))));
                $redisLink_spider->rpush($indexupdateQueue, json_encode(array('index' => $searchIndexUnSold, 'type' => $searchType, 'action' => 'update', 'user' => 'xde', 'time' => date("Y-m-d H:i:s"), 'data' => array('itemId' => $itemid, 'rank10' => 10, 'rank100' => 100))));
//                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexUnSold, $searchType, $itemid, array('rank10' => 10, 'rank100' => 100));
//                ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexUnSold, $searchType, $itemid, array('rank10' => 10, 'rank100' => 100));
            }
            ++$curSendNum;
            if($curSendNum > 100000) {
                sleep(10);
                $curSendNum = 0;
            }
        }
    }
    
    exit;
    
    /**
     * 检测系统负载
     * 
     * @param string $ip
     * @param int    $port
     * @param int    $maxLoad
     * @return boolean
     */
    function checkLoad($ip, $port, $maxLoad)
    {
        $loadInfo = ElasticSearchModel::getLoadInfo($ip, $port);
        $loadInfoArr = explode(' ', trim($loadInfo));
        if(is_array($loadInfoArr) && !empty($loadInfoArr)) {
            foreach($loadInfoArr as $info) {
                $load = trim($info);
                if($load > $maxLoad) {
                    return false;
                }
            }
        }
        return true;
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>