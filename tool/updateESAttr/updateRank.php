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
    $log = $log_path. 'updateRank_'. date('Y_m_d');
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
    
    $redis = '192.168.2.130:6379';
    $key = "IndexUpdateES:". date("Ymd", strtotime("-1 day"));
    echo "Current Time : ". date("Y-m-d H:i:s"). "\n";
    echo "RepairKey : ". $key. "\n";
    file_put_contents($log, "Current Time : ". date("Y-m-d H:i:s"). "\n", FILE_APPEND);
    file_put_contents($log, "RepairKey : ". $key. "\n", FILE_APPEND);
    $redisConf = explode(':', $redis);
    $redisLink  = new Redis();
    if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1]) === false) {
        echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
        file_put_contents($log, "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n", FILE_APPEND);
        exit;
    }
    $allTotal = $redisLink->llen($key);
    $once = 100;
    $times = ceil($allTotal / $once);
    $repairShopNum = 0;
    $repairItemNum = 0;
    for($i = 0; $i < $times; $i++) {
        $start = $i * $once;
        $end = $i * $once + ($once - 1);
        echo "Times : {$times} , Once : {$once} , Current : {$i} , Start : {$start} , End : {$end}  ... \n";
        file_put_contents($log, "Times : {$times} , Once : {$once} , Current : {$i} , Start : {$start} , End : {$end}  ... \n", FILE_APPEND);
        $getData = $redisLink->lrange($key, $start, $end);
        if(empty($getData)) {
            break;
        }
        $printFlag = 1;
        foreach($getData as $dataJ) {
            $dataA = json_decode($dataJ, TRUE);
            if($printFlag) {
                echo $dataA['time']. "\n";
                file_put_contents($log, $dataA['time']. "\n", FILE_APPEND);
                $printFlag = 0;
            }
            if($dataA['index'] == 'item' && $dataA['type'] == 'product' && $dataA['action'] == 'multiupdate' && isset($dataA['data']['class'])) {
                if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
                    while(true) {
                        sleep(60);
                        $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                        if($loadStatus) {
                            break;
                        }
                    }
                }
                ++$repairShopNum;
                $userId = $dataA['where']['userId'];
                $condition = array();
                $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
                $condition['limit'] = array('from' => 0, 'size' => 500000);
                $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid','class','hasimg','addtime','salestatus','rank'), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 60));
                if(empty($searchResult['data'])) {
                    echo "----- The UserId {$userId} Has Null.\n";
                    file_put_contents($log, "----- The UserId {$userId} Has Null.\n", FILE_APPEND);
                    continue;
                }
                echo "----- The UserId {$userId} Has {$searchResult['total']}.\n";
                file_put_contents($log, "----- The UserId {$userId} Has {$searchResult['total']}.\n", FILE_APPEND);
                foreach($searchResult['data'] as $item) {
                    $itemid = $item['itemid'];
                    $class = $item['class'];
                    $hasimg = $item['hasimg'];
                    $addtime = $item['addtime'];
                    $salestatus = $item['salestatus'];
                    $oldrank = $item['rank'];
                    $rank = rank($hasimg, $class, $addtime);
                    echo "itemid : {$itemid} , class : {$class} , hasimg : {$hasimg} , addtime : {$addtime} , salestatus : {$salestatus} , oldrank : {$oldrank}   =>   rank : {$rank} \n";
                    file_put_contents($log, "itemid : {$itemid} , class : {$class} , hasimg : {$hasimg} , addtime : {$addtime} , salestatus : {$salestatus} , oldrank : {$oldrank}   =>   rank : {$rank} \n", FILE_APPEND);
                    if($oldrank == $rank) {
                        continue;
                    }
                    ++$repairItemNum;
                    if($salestatus) {
                        ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexSold, $searchType, $itemid, array('rank' => $rank));
                        ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexSold, $searchType, $itemid, array('rank' => $rank));
                    } else {
                        ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexUnSold, $searchType, $itemid, array('rank' => $rank));
                        ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexUnSold, $searchType, $itemid, array('rank' => $rank));
                    }
                }
            }
        }
    }
    echo "End Time : ". date("Y-m-d H:i:s"). "   . RepairShopNum : {$repairShopNum} , RepairItemNum : {$repairItemNum} . \n";
    file_put_contents($log, "End Time : ". date("Y-m-d H:i:s"). "   . RepairShopNum : {$repairShopNum} , RepairItemNum : {$repairItemNum} . \n", FILE_APPEND);
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
    
    // 计算商品的rank，rank factors: hasImg class addTime 
    function rank($R_hasimg, $R_class, $R_addtime) 
    {
        $hasImg = intval($R_hasimg);

        $class = intval($R_class);
        if($R_class < 0) {
            $class = 0;
        }
        if($R_class > 9) {
            $class = 9;
        }
        
        $months = 0;
        if(!empty($R_addtime)) {
            $addTime = $R_addtime;
            $curyear = intval(date("Y"));
            $startyear = $curyear - 7; // 有效上书时间是今年到前七年
            $otime = strtotime($startyear.'-01-01');
            $months = (int)floor(($addTime - $otime)/(86400*30));
            if($months < 0) $months = 0;
            if($months >= 99) $months = 99;
        }
        
        $rank = $hasImg * 1000 + $class * 100 + $months;
        return $rank;
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>