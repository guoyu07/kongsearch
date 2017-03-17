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
    $log = $log_path. 'updateRank100_'. date('Y_m_d');
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
    $maxLoad    = '25.0';
    
    $fhandle = fopen('/data/project/kongsearch/tool/updateESAttr/rank100.txt', 'r');
    $userIdsArr = array();
    while(!feof($fhandle)) {
        $buffer_str = trim(fgets($fhandle));
        if(!$buffer_str) {
            continue;
        }
        $buffer_arr = explode("\t", $buffer_str);
        $userId = trim($buffer_arr[0]);
        $rank100 = trim($buffer_arr[1]) * 100;
        array_push($userIdsArr, array('userId' => $userId, 'rank100' => $rank100));
    }
    
    $repairShopNum = 0;
    $repairItemNum = 0;
    foreach ($userIdsArr as $user) 
    {
        if (!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while (true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if ($loadStatus) {
                    break;
                }
            }
        }
        ++$repairShopNum;
        $userId = intval($user['userId']);
        if(!$userId) {
            continue;
        }
        $rank100 = intval($user['rank100']);
        
        $condition = array();
        $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
        $condition['filter']['must_not'][] = array('field' => 'rank100', 'value' => $rank100);
        $condition['limit'] = array('from' => 0, 'size' => 500000);
        $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndexUnSold, $searchType, 0, array('itemid', 'rank100'), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 60));
        if (empty($searchResult['data'])) {
            echo "----- The UserId {$userId} Has Null.\n";
            file_put_contents($log, "----- The UserId {$userId} Has Null.\n", FILE_APPEND);
            continue;
        }
        echo "----- The UserId {$userId} Has {$searchResult['total']}.\n";
        file_put_contents($log, "----- The UserId {$userId} Has {$searchResult['total']}.\n", FILE_APPEND);
        foreach ($searchResult['data'] as $item) {
            $itemid = $item['itemid'];
            $oldrank100 = $item['rank100'];
            echo date("Y-m-d H:i:s"). "   shopNum : {$repairShopNum} , itemNum : {$repairItemNum} , userid : {$userId} , hasNum : {$searchResult['total']} , itemid : {$itemid} , oldrank100 : {$oldrank100}   =>   rank100 : {$rank100} \n";
            file_put_contents($log, date("Y-m-d H:i:s"). "   shopNum : {$repairShopNum} , itemNum : {$repairItemNum} , userid : {$userId} , hasNum : {$searchResult['total']} , itemid : {$itemid} , oldrank100 : {$oldrank100}   =>   rank100 : {$rank100} \n", FILE_APPEND);
//            if ($oldrank100 == $rank100) {
//                continue;
//            }
            ++$repairItemNum;
            ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndexUnSold, $searchType, $itemid, array('rank100' => $rank100));
            ElasticSearchModel::updateDocument($searchHostSpider, $searchPortSpider, $searchIndexUnSold, $searchType, $itemid, array('rank100' => $rank100));
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
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>