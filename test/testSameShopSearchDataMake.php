<?php
    
    $link = mysql_pconnect('192.168.1.194', 'sunyutian', 'sun100112'); //orders链接
    mysql_select_db('orders', $link);
    mysql_query("SET NAMES 'utf8'", $link);
    
    $cmdopts = getopt('t:h');
    $tableId = isset($cmdopts['t']) && trim($cmdopts['t']) ? trim($cmdopts['t']) : 1;
    $dataStart = strtotime("2015-11-10");
    $dataEnd = strtotime("2015-11-11");
    
    $getUserIdSql   = "select userId,count(*) as num from buyerOrderInfo_{$tableId} where createdTime>{$dataStart} and createdTime<{$dataEnd} group by userId having num>=3 and num<=4 order by num desc limit 20";
    $getUserIdQuery = mysql_query($getUserIdSql, $link);
    $testData = array();
    echo "正在生成结果集......\n";
    while($getUserIdResult = mysql_fetch_assoc($getUserIdQuery)) {
        $tmpArr = array();
        $userId = $getUserIdResult['userId'];
        $num = $getUserIdResult['num'];
        $tmpArr['userId'] = $userId;
        $tmpArr['num'] = $num;
        $tmpArr['data'] = array();
        $getItemSql = "select userId,shopId,shopName,itemId,itemName from buyerOrderInfo_{$tableId} as a left join buyerOrderItems_{$tableId} as b on a.orderId=b.orderId where userId={$userId} and createdTime>{$dataStart} and createdTime<{$dataEnd}"; //取2015/11/10日数据
        $getItemQuery = mysql_query($getItemSql, $link);
        if(mysql_num_rows($getItemQuery) > 3) {
            continue;
        }
        while($getItemResult = mysql_fetch_assoc($getItemQuery)) {
            $tmpArr['data'][] = array(
                'shopId' => $getItemResult['shopId'],
                'shopName' => $getItemResult['shopName'],
                'itemId' => $getItemResult['itemId'],
                'itemName' => $getItemResult['itemName']
            );
        }
        $testData[] = $tmpArr;
    }
    echo "共生成". count($testData). "个结果.\n";
    file_put_contents('/data/project/kongsearch/test/testSameShopSearchData.php', "<?php \n\t/******由testSameShopSearchDataMake.php程序生成*******/\n\n\t\$testData = ". var_export($testData, true). ";\n?>");
?>