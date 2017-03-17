<?php

    /*****************************************
     * author: xinde
     * 
     * 测试同店搜索（需先执行testSameShopSearchDataMake.php程序，生成数据文件）
     * 
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    require_once 'testSameShopSearchData.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    //商品图书搜索
    $productServers = array(
        '192.168.1.68:9700'
    );
    $productServer = ElasticSearchModel::getServer($productServers);
    
    if(!isset($testData)) {
        exit;
    }
    
    foreach($testData as $data) {
        $userId = $data['userId'];
        $num = $data['num'];
        if(count($data['data']) > 3) {
            continue;
        }
        echo "-----------------------------------------------------------------------------------\n";
        echo "userId : $userId \n";
        echo "num : $num \n";
        $tmpNameArr = array();
        foreach($data['data'] as $k => $row) {
            echo intval($k+1). " : \n";
            echo "\t shopId : {$row['shopId']}\n";
            echo "\t shopName : {$row['shopName']}\n";
            echo "\t itemId : {$row['itemId']}\n";
            echo "\t itemName : {$row['itemName']}\n";
            $tmpNameArr[] = $row['itemName'];
        }
        if(count($tmpNameArr) > 3) {
            echo "Result : 图书数量大于3，忽略. \n";
            continue;
        }
        
        $searchDataArr = array();
        $searchShopData = array();
        foreach($tmpNameArr as $k => $itemname) {
            $itemListFromProductQuery = '{"_source":["itemid","itemname","shopid","shopname"],"query":{"bool":{"should":[{"match":{"_itemname":{"query":"'. $itemname. '","type" : "phrase","slop":"2"}}}],"must":[{"dis_max":{"queries":[{"multi_match":{"query":"'. $itemname. '","fields":["_author^60","_press^50","_itemname^300","isbn^30"],"minimum_should_match":"100%","type":"cross_fields"}}]}}]}},"filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}},"sort":["_score",{"rank":{"order":"desc"}}],"size":"1000","from":"0"}';
            $itemListFromProductResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($productServer['host'], $productServer['port'], 'item', 'product', $itemListFromProductQuery, 300, true));
            if($itemListFromProductResult['total'] == 0) {
                echo "Result : 无任何结果匹配. \n";
                break;
            }
            $searchShopData[$k] = array();
            foreach($itemListFromProductResult['data'] as $r) {
                $shopid = $r['shopid'];
                if(!in_array($shopid, $searchShopData[$k])) {
                    $searchShopData[$k][] = $shopid;
                }
                $searchDataArr[$k][$shopid][] = $r['itemname'];
//                if(!array_key_exists($shopid, $searchDataArr[$k])) {
//                    $searchShopData[$k][$shopid][] = $r['itemname'];
//                } else {
//                    
//                }
            }
        }
        $interStr = "\$inter = array_intersect(";
        for($i = 0; $i <= $k ; $i++) {
            $interStr .= "\$searchShopData[{$i}],";
        }
        $interStr = trim($interStr, ',');
        $interStr .= ");";
        eval($interStr);
        if(empty($inter)) {
            echo "Result : 无交集书店. \n";
            continue;
        }
        echo "Result : 结果如下 : \n";
        foreach($inter as $shopid) {
            echo "\tshopId : {$shopid} : \n";
            foreach($searchDataArr as $k => $shopData) {
                foreach($shopData[$shopid] as $name) {
                    echo "\t\t itemName : ". $name. "\n";
                }
            }
        }
    }
    
    
    
?>