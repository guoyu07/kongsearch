<?php

    /*****************************************
     * author: xinde
     * 
     * 精品店铺图书数据搜索源生成程序
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('i:h');
    
    $logPath = '/data/kongsearch_logs/fine_product_search_build';
    if(!is_dir($logPath)) {
        mkdir($logPath, 0777, true);
    }
    $logFile = $logPath. '/'. date("Y-m-d-H-i-s"). ".log";
    
    $processCount = `ps -ef | grep 'fine_product_search_build.php' | grep -v grep | grep -v '/bin/sh' | grep -v 'vi' | wc -l`;
    if ($processCount > 1) {
        noticeLog(date("Y-m-d H:i:s"). " 已经有正在运行的程序:fine_product_search_build.php !!!\n");
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
    
    //商品图书搜索
    $productServers = array(
        '192.168.1.68:9700'
    );
    $productServer = ElasticSearchModel::getServer($productServers);
    
    //精品店铺图书搜索
    $fineProductServers = array(
        '192.168.2.200:9400'
    );
    $fineProductServer = ElasticSearchModel::getServer($fineProductServers);
    
    //取好评书店
    $gs_hashTable = 'goodShopsHashTable';
    $shopKeys = $recommendRedisLink->hkeys($gs_hashTable);
    $shopVals = $recommendRedisLink->hvals($gs_hashTable);
    
    if(count($shopKeys) != count($shopVals)) {
        noticeLog("The Hash Table {$gs_hashTable} Keys Number != Vals Number .\n");
        exit;
    }
    
    $n = 0;
    //根据好评书店取图书
    foreach($shopKeys as $key => $value) {
        ++$n;
        $shopId = $value;
        $shopTrust = $shopVals[$key];
        
        noticeLog("[". date("Y-m-d H:i:s"). "   - {$n}] Begin Deal With The Shop[{$shopId}][trust:{$shopTrust}] ...\n");
        
        //更新精品店铺图书数据isdeleted为1
        noticeLog("更新精品店铺图书数据isdeleted为1...\n");
        $itemNumFromFineProductQuery = '{"_source":["itemid"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}}]}},"size":"1","from":"0"}';
        $itemNumFromFineProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemNumFromFineProductQuery, 300, true));
        if(!$itemNumFromFineProductResult['status'] || $itemNumFromFineProductResult['total'] == 0) { //取数据失败
            noticeLog("Get Shop Data Filure \$itemNumFromFineProductResult['status'] = {$itemNumFromFineProductResult['status']}.\n");
        } else {
            noticeLog("更新精品店铺图书数据isdeleted为1，需更新图书总量为{$itemNumFromFineProductResult['total']}...\n");
            $once = 1000;
            $times = ceil($itemNumFromFineProductResult['total'] / $once);
            $startId = 0;
            for($i = 1; $i <= $times; $i++) {
                $itemListFromFineProductQuery = '{"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"0"}},{"range":{"itemid":{"from":"'. $startId. '"}}}]}},"sort":[{"itemid":{"order":"asc"}}],"size":"'. $once. '","from":"0"}';
                $itemListFromFineProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemListFromFineProductQuery, 300, true));
                foreach($itemListFromFineProductResult['data'] as $row) {
                    $itemid = $row['itemid'];
                    $updateData = array(
                        'isdeleted' => 1
                    );
                    ElasticSearchModel::updateDocument($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemid, $updateData);
                }
                $tmpNum = count($itemListFromFineProductResult['data']);
                if($tmpNum < $once) {
                    break;
                }
                $startId = $itemListFromFineProductResult['data'][$tmpNum-1]['id'];
            }
        }
        
        //从商品搜索中取出该店数据
        noticeLog("从商品搜索中取出该店数据...\n");
        $itemNumFromProductQuery = '{"_source":["itemid"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}},"size":"1","from":"0"}';
        $itemNumFromProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($productServer['host'], $productServer['port'], 'item', 'product', $itemNumFromProductQuery, 300, true));
        
        if(!$itemNumFromProductResult['status']) { //取数据失败
            noticeLog("Get Shop Data Filure \$itemNumFromProductResult['status'] = {$itemNumFromProductResult['status']}.\n");
        } elseif ($itemNumFromProductResult['total'] == 0) { //店铺数据为0
            noticeLog("The Shop[{$shopId}] Has Get Null , Continue!\n");
        } else {
            noticeLog("从商品搜索中取出该店数据，需加入到精品店铺图书搜索数据总量为{$itemNumFromProductResult['total']}...\n");
            $once = 1000;
            $times = ceil($itemNumFromProductResult['total'] / $once);
            $startId = 0;
            for($i = 1; $i <= $times; $i++) {
                $itemListFromProductQuery = '{"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}},{"range":{"itemid":{"from":"'. $startId. '"}}}]}},"sort":[{"itemid":{"order":"asc"}}],"size":"'. $once. '","from":"0"}';
                $itemListFromProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($productServer['host'], $productServer['port'], 'item', 'product', $itemListFromProductQuery, 300, true));

                //加入到精品店铺图书
                foreach($itemListFromProductResult['data'] as $row) {
                    $itemid = $row['itemid'];
                    ElasticSearchModel::indexDocument($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $row, $itemid);
                }

                $tmpNum = count($itemListFromProductResult['data']);
                if($tmpNum < $once) {
                    break;
                }
                $startId = $itemListFromProductResult['data'][$tmpNum-1]['id'];
            }
        }
        
        //删除精品店铺isdeleted为1的图书数据
        noticeLog("删除精品店铺isdeleted为1的图书数据...\n");
        $itemNumFromFineProductQueryDel = '{"_source":["itemid"],"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"1"}}]}},"size":"1","from":"0"}';
        $itemNumFromFineProductResultDel = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemNumFromFineProductQueryDel, 300, true));
        if(!$itemNumFromFineProductResultDel['status'] || $itemNumFromFineProductResultDel['total'] == 0) { //取数据失败
            noticeLog("Get Shop Data Filure \$itemNumFromFineProductResultDel['status'] = {$itemNumFromFineProductResultDel['status']}.\n");
        } else {
            noticeLog("删除精品店铺isdeleted为1的图书数据，需删除图书总量为{$itemNumFromFineProductResultDel['total']}...\n");
            $once = 1000;
            $times = ceil($itemNumFromFineProductResultDel['total'] / $once);
            $startId = 0;
            for($i = 1; $i <= $times; $i++) {
                $itemListFromFineProductQueryDel = '{"filter":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}},{"term":{"isdeleted":"1"}},{"range":{"itemid":{"from":"'. $startId. '"}}}]}},"sort":[{"itemid":{"order":"asc"}}],"size":"'. $once. '","from":"0"}';
                $itemListFromFineProductResultDel = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemListFromFineProductQueryDel, 300, true));
                foreach($itemListFromFineProductResultDel['data'] as $row) {
                    $itemid = $row['itemid'];
                    ElasticSearchModel::deleteDocument($fineProductServer['host'], $fineProductServer['port'], 'fine_item', 'fine_product', $itemid);
                }
                $tmpNum = count($itemListFromFineProductResultDel['data']);
                if($tmpNum < $once) {
                    break;
                }
                $startId = $itemListFromFineProductResultDel['data'][$tmpNum-1]['id'];
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