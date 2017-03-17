<?php
    /**
     * 统计审核驳回情况
     */
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/verifylog';
    if(!is_dir($path)) {
        mkdir($path, 0777, true);
    }
    
    /*
    $searchServers = array(
        '192.168.1.105:9900'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    
    $queryStr = '{"size":"0","facets":{"shop_facet":{"terms":[{"field":"shopid","size":"100"}],"global":false,"facet_filter":{"bool":{"must":[{"term":{"optype":"1"}},{"term":{"op":"2"}},{"range": {"optime": {"from": 1420070400,"to": 1451520000,"include_lower": false}}}]}}}}}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'booklog', 'verify', $queryStr, 60, true);
    if(isset($result['facets']) && isset($result['facets']['shop_facet']) && isset($result['facets']['shop_facet']['terms']) && !empty($result['facets']['shop_facet']['terms'])) {
        $fhandle = fopen($path. '/2015.txt', 'w+');
        foreach($result['facets']['shop_facet']['terms'] as $row) {
            $shopid = $row['term'];
            $num = intval($row['count']);
            $shopQueryStr = '{"query":{"bool":{"must":[{"term":{"shopid":"'. $shopid. '"}}]}},"size":"1"}';
            $shopResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'booklog', 'verify', $shopQueryStr, 60, true));
            if($shopResult['total'] <= 0) {
                break;
            }
            $shopName = $shopResult['data'][0]['shopname'];
            fwrite($fhandle, $shopName. '     【'. $num. "】\n");
        }
        fclose($handle);
    }
     * 
     */
    
    $shopDb_Host = '192.168.1.67';
    $shopDb_User = 'sunyutian';
    $shopDb_Pawd = 'sun100112';
    $shopDb_Name = 'shop';
    
    $productA1Db_Host = '192.168.1.125';
    $productA1Db_User = 'sunyutian';
    $productA1Db_Pawd = 'sun100112';
    $productA1Db_Name = 'product_a1';
    
    $productA2Db_Host = '192.168.1.125';
    $productA2Db_User = 'sunyutian';
    $productA2Db_Pawd = 'sun100112';
    $productA2Db_Name = 'product_a2';
    
    $productB1Db_Host = '192.168.1.186';
    $productB1Db_User = 'sunyutian';
    $productB1Db_Pawd = 'sun100112';
    $productB1Db_Name = 'product_b1';
    
    $productB2Db_Host = '192.168.1.186';
    $productB2Db_User = 'sunyutian';
    $productB2Db_Pawd = 'sun100112';
    $productB2Db_Name = 'product_b2';
    
    $link_shop = mysql_pconnect($shopDb_Host, $shopDb_User, $shopDb_Pawd);
    mysql_select_db($shopDb_Name, $link_shop);
    mysql_query("SET NAMES 'utf8'", $link_shop);
    
    $link_product_a1 = mysql_pconnect($productA1Db_Host, $productA1Db_User, $productA1Db_Pawd);
    mysql_select_db($productA1Db_Name, $link_product_a1);
    mysql_query("SET NAMES 'utf8'", $link_product_a1);
    
    $link_product_a2 = mysql_pconnect($productA2Db_Host, $productA2Db_User, $productA2Db_Pawd);
    mysql_select_db($shopDb_Name, $link_product_a2);
    mysql_query("SET NAMES 'utf8'", $link_product_a2);
    
    $link_product_b1 = mysql_pconnect($productB1Db_Host, $productB1Db_User, $productB1Db_Pawd);
    mysql_select_db($productB1Db_Name, $link_product_b1);
    mysql_query("SET NAMES 'utf8'", $link_product_b1);
    
    $link_product_b2 = mysql_pconnect($productB2Db_Host, $productB2Db_User, $productB2Db_Pawd);
    mysql_select_db($shopDb_Name, $link_product_b2);
    mysql_query("SET NAMES 'utf8'", $link_product_b2);
    
    $tables_get_sql = "SELECT * FROM tableMap";
    $tables_get_query = mysql_query($tables_get_sql, $link_shop);
    
    $num_2013 = 0;
    $num_2014 = 0;
    $num_2015 = 0;
    
    while($tables_get_result = mysql_fetch_assoc($tables_get_query)) {
        $tableId = $tables_get_result['tableId'];
        $dbName = $tables_get_result['dbName'];
        if($dbName == 'product_a1') {
            $link = $link_product_a1;
        } elseif ($dbName == 'product_a2') {
            $link = $link_product_a2;
        } elseif ($dbName == 'product_b1') {
            $link = $link_product_b1;
        } elseif ($dbName == 'product_b2') {
            $link = $link_product_b2;
        }
        
        if($tableId >= 50000) {
            break;
        }
        $tableName = 'item_'. $tableId;
        $num_sql_2013 = "select count(*) as num from {$tableName} where certifyStatus='failed' and addTime >= ". strtotime("2013-01-01"). " and addTime <= ". strtotime("2013-12-31 23:59:59");
        $num_query_2013 = mysql_query($num_sql_2013, $link);
        $num_result_2013 = mysql_fetch_assoc($num_query_2013);
        $num_2013 += $num_result_2013['num'];
        
        $num_sql_2014 = "select count(*) as num from {$tableName} where certifyStatus='failed' and addTime >= ". strtotime("2014-01-01"). " and addTime <= ". strtotime("2014-12-31 23:59:59");
        $num_query_2014 = mysql_query($num_sql_2014, $link);
        $num_result_2014 = mysql_fetch_assoc($num_query_2014);
        $num_2014 += $num_result_2014['num'];
        
        $num_sql_2015 = "select count(*) as num from {$tableName} where certifyStatus='failed' and addTime >= ". strtotime("2015-01-01"). " and addTime <= ". strtotime("2015-12-31 23:59:59");
        $num_query_2015 = mysql_query($num_sql_2015, $link);
        $num_result_2015 = mysql_fetch_assoc($num_query_2015);
        $num_2015 += $num_result_2015['num'];
        
        echo "Now : Table {$tableName} , Total_2013 : {$num_2013}, Total_2014 : {$num_2014}, Total_2015 : {$num_2015}\n";
    }
    
    
    
?>