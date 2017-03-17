<?php

    /*****************************************
     * author: xinde
     * 
     * 推荐数据源生成程序
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('i:h');
    
    //是否将count=0的初始化，默认否
    $isInitCount = 0;
    if(isset($cmdopts['i']) && trim($cmdopts['i'])) {
        $isInitCount = trim($cmdopts['i']);
    }
    
    $logPath = '/data/kongsearch_logs/shop_recommend';
    if(!is_dir($logPath)) {
        mkdir($logPath, 0777, true);
    }
    $logFile = $logPath. '/'. date("Y-m-d-H-i-s"). ".log";
    
    $processCount = `ps -ef | grep 'shop_recommend.php' | grep -v grep | grep -v '/bin/sh' | grep -v 'vi' | wc -l`;
    if ($processCount > 1) {
        noticeLog(date("Y-m-d H:i:s"). " 已经有正在运行的程序:shop_recommend.php !!!\n");
        exit;
    }
    
    noticeLog("----------------------------------------------- Start [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    //推荐Redis
    $recommendRedisConf = array(
        '192.168.2.201',
        '6379'
    );
    $recommendRedisLink = new Redis();
    if ($recommendRedisLink->pconnect($recommendRedisConf[0], $recommendRedisConf[1]) === false && $recommendRedisLink->pconnect($recommendRedisConf[0], $recommendRedisConf[1])) {
        noticeLog("Count Not Connect Redis {$recommendRedisConf[0]}:{$recommendRedisConf[1]} .\n");
        exit;
    }
    
    //索引更新Redis
    $indexUpdateRedisConf = array(
        '192.168.2.201',
        '6379'
    );
    $indexUpdateRedisLink = new Redis();
    if ($indexUpdateRedisLink->pconnect($indexUpdateRedisConf[0], $indexUpdateRedisConf[1]) === false && $indexUpdateRedisLink->pconnect($indexUpdateRedisConf[0], $indexUpdateRedisConf[1])) {
        noticeLog("Count Not Connect Redis {$indexUpdateRedisConf[0]}:{$indexUpdateRedisConf[1]} .\n");
        exit;
    }
    
    //商品图书搜索
    $productServers = array(
        '192.168.1.68:9700'
    );
    $productServer = ElasticSearchModel::getServer($productServers);
    
    //推荐搜索
    $recommendServers = array(
        '192.168.2.200:9400'
    );
    $recommendServer = ElasticSearchModel::getServer($recommendServers);
    
    //最小可推荐图书总数
    $minRecommendTotal = 1500000;
    //判断推荐搜索中可推荐图书总数，如果总数小于$minRecommendTotal，则开启isInitCount = 1模式
    $itemTotalFromRecommendQuery = '{"query":{"bool":{"must":[{"range": {"count": {"from": 0,"include_lower": false}}},{"term":{"isdeleted":"0"}}]}},"size":"1"}';
    $itemTotalFromRecommendResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($recommendServer['host'], $recommendServer['port'], 'shop_recommend', 'item', $itemTotalFromRecommendQuery, 300, true));
    if(!$itemTotalFromRecommendResult['status'] || !$itemTotalFromRecommendResult['status']) {
        noticeLog("Get Total Filure \$itemTotalFromRecommendResult['status'] = {$itemTotalFromRecommendResult['status']} . Retry....\n");
        $itemTotalFromRecommendResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($recommendServer['host'], $recommendServer['port'], 'shop_recommend', 'item', $itemTotalFromRecommendQuery, 300, true));
        if(!$itemTotalFromRecommendResult['status'] || !$itemTotalFromRecommendResult['status']) {
            noticeLog("Get Total Filure \$itemTotalFromRecommendResult['status'] = {$itemTotalFromRecommendResult['status']} . Exit....\n");
            exit;
        }
    }
    $total = $itemTotalFromRecommendResult['total'];
    noticeLog("*** Current Recommend Total Num : {$total} .\n");
    if($total < $minRecommendTotal) {
        noticeLog("*** Current Recommend Total Num : {$total} < Min Recommend Total Num : {$minRecommendTotal} , isInitCount Set 1.\n");
        $isInitCount = 1;
    }
    
    //单商品最大展示次数
    $itemInitMaxCountNum = 15;
    //指定店铺单商品最大展示次数
    $specialShopInitMaxCountNumMapping = array(
        '19661' => 10000
    );
    
    //单店铺最大图书取值
    $itemMaxNumPerShop = 3000;
    
    //取好评书店
    $gs_hashTable = 'goodShopsHashTable';
    $shopKeys = $recommendRedisLink->hkeys($gs_hashTable);
    $shopVals = $recommendRedisLink->hvals($gs_hashTable);
    
    if(count($shopKeys) != count($shopVals)) {
        noticeLog("The Hash Table {$gs_hashTable} Keys Number != Vals Number .\n");
        exit;
    }
    
    //商品展示次数
    $ic_hashTable = 'itemCountHashTable';
    
    //索引更新队列
    $indexupdateQueue = 'IndexUpdateES:shop_recommend';
    
    //最后一个需索引更新insert店铺ID
    $lastShopId = 0;
    //最后一个需索引更新insert店铺的更新数量
    $lastShopIndexUpdateNum = 0;
    
    $n = 0;
    //根据好评书店取图书
    foreach($shopKeys as $key => $value) {
        ++$n;
        $shopId = $value;
        $shopTrust = $shopVals[$key];
        
        noticeLog("[". date("Y-m-d H:i:s"). "   - {$n}] Begin Deal With The Shop[{$shopId}][trust:{$shopTrust}] ...\n");
        //从推荐中取出该店数据并将其isdeleted更新为1
        $itemListFromRecommendQuery = '{"_source":["itemid","itemname"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"0"}}]}},"size":"'. $itemMaxNumPerShop . '","from":"0"}';
        $itemListFromRecommendResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($recommendServer['host'], $recommendServer['port'], 'shop_recommend', 'item', $itemListFromRecommendQuery, 300, true));
        
        //从商品搜索中取出该店数据
        $itemListFromProductQuery = '{"_source":["itemid","itemname","catid","imgurl","class","addtime","userid","shopid","price","author"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}},{"term":{"hasimg":"1"}}],"must_not":[{"term":{"number":"0"}},{"term":{"approach":"1"}},{"term":{"approach":"2"}},{"term":{"approach":"5"}}]}},"sort":[{"addtime":{"order":"desc"}}],"size":"'. $itemMaxNumPerShop. '","from":"0"}';
        $itemListFromProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($productServer['host'], $productServer['port'], 'item', 'product', $itemListFromProductQuery, 300, true));
        
        //取数据失败
        if(!$itemListFromRecommendResult['status'] || !$itemListFromProductResult['status']) {
            noticeLog("Get Shop Data Filure \$itemListFromRecommendResult['status'] = {$itemListFromRecommendResult['status']} , \$itemListFromProductResult['status'] = {$itemListFromProductResult['status']}.\n");
            continue;
        }
        
        //新老推荐数据记录
        $itemIdsFromRecommendResult = array();
        $itemIdsFromProductResult = array();
        
        noticeLog("itemListFromRecommendResult total : ". count($itemListFromRecommendResult['data']). " .\n");
        //从推荐中取出该店数据并将其isdeleted更新为1
        if($itemListFromRecommendResult['total'] != 0) {
            foreach($itemListFromRecommendResult['data'] as $row) {
                $itemId = $row['itemid'];
                if(!trim($itemId)) {
                    continue;
                }
                $itemIdsFromRecommendResult[] = $itemId;
                //update
                $pushArr = array(
                    'index' => 'shop_recommend',
                    'type' => 'item',
                    'action' => 'update',
                    'user' => 'search',
                    'time' => date("Y-m-d H:i:s"),
                    'data' => array(
                        'itemId' => $itemId,
                        'isDelete' => 1
                    )
                );
                $pushJson = json_encode($pushArr);
                try {
                    $indexUpdateRedisLink->rpush($indexupdateQueue, $pushJson);
                } catch (Exception $ex) {
                    noticeLog("[". date("Y-m-d H:i:s"). "][update] rpush data filure : itemId[{$itemId}].\n");
                }
            }
        }
        
        noticeLog("itemListFromProductResult total : ". count($itemListFromProductResult['data']). " .\n");
        //从商品搜索中取出该店数据
        if($itemListFromProductResult['total'] == 0) {
            $itemListFromProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($productServer['host'], $productServer['port'], 'item', 'product', $itemListFromProductQuery, 300, true));
            //取数据失败
            if(!$itemListFromProductResult['status']) {
                noticeLog("Get Shop Data Filure \$itemListFromProductResult['status'] = {$itemListFromProductResult['status']}.\n");
                continue;
            }
            noticeLog("itemListFromProductResult total : ". count($itemListFromProductResult['data']). "[second time] . \n");
            if($itemListFromProductResult['total'] == 0) {
                noticeLog("The Shop[{$shopId}] Has Get Null , Continue!\n");
                continue;
            }
        }
        
        //最后一个需索引更新insert店铺
        $lastShopId = $shopId;
        $lastShopIndexUpdateNum = count($itemListFromProductResult['data']);
        
        foreach($itemListFromProductResult['data'] as $row) {
            $msg = array();
            $msg['itemId'] = $row['itemid'];
            $msg['itemName'] = $row['itemname'];
            $msg['catId'] = $row['catid'];
            $msg['imgUrl'] = $row['imgurl'];
            $msg['shopClass'] = $row['class'];
            $msg['addTime'] = $row['addtime'];
            $msg['sellerId'] = $row['userid'];
            $msg['shopId'] = $row['shopid'];
            $msg['author'] = $row['author'];
            //获取商品展示次数
            if(array_key_exists($shopId, $specialShopInitMaxCountNumMapping)) {
                //更新次数为指定
                $msg['count'] = $specialShopInitMaxCountNumMapping[$shopId];
                $recommendRedisLink->hset($ic_hashTable, $msg['itemId'], $msg['count']);
            } else {
                $count = $recommendRedisLink->hget($ic_hashTable, $msg['itemId']);
                if(!$count && $count !== '0') { //redis中没有key
                    $msg['count'] = $itemInitMaxCountNum;
                    $recommendRedisLink->hset($ic_hashTable, $msg['itemId'], $itemInitMaxCountNum);
                } elseif ($count === '0' && $isInitCount == 0) { //如果count为0，并且不初始化
                    $msg['count'] = 0;
                } elseif ($count === '0' && $isInitCount == 1) { //如果count为0，并且要初始化
                    $msg['count'] = $itemInitMaxCountNum;
                    $recommendRedisLink->hset($ic_hashTable, $msg['itemId'], $itemInitMaxCountNum);
                } elseif ($count < 0) { //如果count小于0
                    $msg['count'] = $itemInitMaxCountNum;
                    $recommendRedisLink->hset($ic_hashTable, $msg['itemId'], $itemInitMaxCountNum);
                } elseif ($count > 0 && $isInitCount == 1) { //如果count大于0，并且要初始化
                    $msg['count'] = $itemInitMaxCountNum;
                    $recommendRedisLink->hset($ic_hashTable, $msg['itemId'], $itemInitMaxCountNum);
                } else {
                    $msg['count'] = intval($count);
                }
            }
            
            $msg['isDelete'] = 0;
            $msg['price'] = $row['price'];
            $msg['shopTrust'] = $shopTrust;
            $msg['ranker'] = 0;
            
            $itemIdsFromProductResult[] = $msg['itemId'];
            
            //insert
            $pushArr = array(
                'index' => 'shop_recommend',
                'type' => 'item',
                'action' => 'insert',
                'user' => 'search',
                'time' => date("Y-m-d H:i:s"),
                'data' => $msg
            );
            $pushJson = json_encode($pushArr);
            try {
                $indexUpdateRedisLink->rpush($indexupdateQueue, $pushJson);
            } catch (Exception $ex) {
                noticeLog("[". date("Y-m-d H:i:s"). "][insert] rpush data filure : itemId[{$itemId}].\n");
            }
        }
        
        //将老推荐有的而新推荐没有的数据itemCountHashTable删除
        foreach($itemIdsFromRecommendResult as $itemId) {
            if(!in_array($itemId, $itemIdsFromProductResult)) {
                $recommendRedisLink->hdel($ic_hashTable, $itemId);
            }
        }
        
    }
    
    noticeLog("Step 2 [". date("Y-m-d H:i:s"). "] .\n");
    
    //队列处理完成后
    while(true) {
        ElasticSearchModel::refresh($recommendServer['host'], $recommendServer['port'], 'shop_recommend');
        $itemListFromRecommendQuery = '{"_source":["itemid","itemname"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $lastShopId. '"}},{"term":{"isdeleted":"0"}}]}},"size":"1","from":"0"}';
        $itemListFromRecommendResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($recommendServer['host'], $recommendServer['port'], 'shop_recommend', 'item', $itemListFromRecommendQuery, 300, true));
        noticeLog("Last Shop[{$lastShopId}] Normal Num : {$lastShopIndexUpdateNum} . Now Num : {$itemListFromRecommendResult['total']} .\n");
        if($itemListFromRecommendResult['total'] > $lastShopIndexUpdateNum - 10) {
            sleep(3);
            break;
        }
//        $indexupdateQueueLen = $indexUpdateRedisLink->llen($indexupdateQueue);
//        echo "IndexUpdateQueueLength : {$indexupdateQueueLen} .\n";
//        if($indexupdateQueueLen < 500) {
//            break;
//        }
        sleep(10);
    }
    
    noticeLog("Step 3 [". date("Y-m-d H:i:s"). "] .\n");
    
    //将推荐中各店铺isdeleted为1的数据删除
    $n = 0;
    foreach($shopKeys as $shopId) {
        ++$n;
        ElasticSearchModel::refresh($recommendServer['host'], $recommendServer['port'], 'shop_recommend');
        $itemListFromRecommendDelQuery = '{"_source":["itemid"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"1"}}]}},"size":"10000","from":"0"}';
        $itemListFromRecommendDelResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($recommendServer['host'], $recommendServer['port'], 'shop_recommend', 'item', $itemListFromRecommendDelQuery, 300, true));
        //取数据失败
        if(!$itemListFromRecommendDelResult['status']) {
            noticeLog("Get Shop Data Filure : \$itemListFromRecommendDelResult['status'] : {$itemListFromRecommendDelResult['status']} .\n");
            continue;
        }
        noticeLog("[". date("Y-m-d H:i:s"). "   - {$n}] shopid[{$shopId}] itemListFromRecommendDelResult total : ". count($itemListFromRecommendDelResult['data']). " .\n");
        if($itemListFromRecommendDelResult['total'] != 0) {
            foreach($itemListFromRecommendDelResult['data'] as $row) {
                $itemId = $row['itemid'];
                if(!trim($itemId)) {
                    continue;
                }
                //delete
                $pushArr = array(
                    'index' => 'shop_recommend',
                    'type' => 'item',
                    'action' => 'delete',
                    'user' => 'search',
                    'time' => date("Y-m-d H:i:s"),
                    'data' => array(
                        'itemId' => $itemId
                    )
                );
                $pushJson = json_encode($pushArr);
                try {
                    $indexUpdateRedisLink->rpush($indexupdateQueue, $pushJson);
                } catch (Exception $ex) {
                    noticeLog("[". date("Y-m-d H:i:s"). "][delete] rpush data filure : itemId[{$itemId}].\n");
                }
            }
        }
    }
    
    noticeLog("----------------------------------------------- End [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    function noticeLog($msg)
    {
        global $logFile;
        echo $msg;
        file_put_contents($logFile, $msg, FILE_APPEND);
    }
    
?>