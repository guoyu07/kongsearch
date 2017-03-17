<?php
    /*****************************************
     * author: xinde
     * 
     * 修复商品脚本(nohup php tool/repairProductES.php -t "all" -w "userId>12052" -m "50000" > /data/kongsearch_logs/res.log &)
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    require_once '/data/project/kongsearch/lib/sharding.php';
    require_once '/data/project/kongsearch/lib/gatherES.class.php';
    require_once '/data/project/kongsearch/lib/indexupdate.class.php';
    require_once '/data/project/kongsearch/lib/unihan.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('t:u:w:m:p:g:s:z:h');
    if(!$cmdopts || isset($cmdopts['h']) || !isset($cmdopts['t']) || !$cmdopts['t'] || !in_array($cmdopts['t'], array('single', 'multi', 'all', 'retry'))) {
        usage($argv[0]);
        exit;
    }
    $dealType = $cmdopts['t'];
    $userId = 0;
    if(isset($cmdopts['u']) && trim($cmdopts['u'])) {
        $userId = trim($cmdopts['u']);
    }
    if($dealType == 'single' && !$userId) {
        usage($argv[0]);
        exit;
    }
    $where = '1=1';
    if(isset($cmdopts['w']) && trim($cmdopts['w'])) {
        $where = trim($cmdopts['w']);
    }
    $maxFlag = 0;
    if(isset($cmdopts['m']) && intval($cmdopts['m']) > 0) {
        $maxFlag = intval($cmdopts['m']);
    }
    $printMaxFlag = 0;
    if(isset($cmdopts['p']) && intval($cmdopts['p']) == 1) {
        $printMaxFlag = 1;
    }
    $ignoreGatherFlag = 0;
    if(isset($cmdopts['g']) && intval($cmdopts['g']) == 1) {
        $ignoreGatherFlag = 1;
    }
    $isStrict = 0;
    if(isset($cmdopts['s']) && intval($cmdopts['s']) == 1) {
        $isStrict = 1;
    }
    $isRepairSpider = 0;
    if(isset($cmdopts['z']) && intval($cmdopts['z']) == 1) {
        $isRepairSpider = 1;
    }
    //最大可删除数量
    $maxDeleteNum = 100000;
    $singleMaxDeleteNum = 10000;
    
    if($isRepairSpider) {
        $gatherlogpath = '/data/kongsearch_logs/esSpider_product_indexupdate.log';
    } else {
        $gatherlogpath = '/data/kongsearch_logs/es_product_indexupdate.log';
    }
    $confpath = '/data/project/kongsearch/conf/indexupdate.ini';
    $config = IndexUpdate::getConfig($confpath);
    $indexkey = 'product';
    $indexconfig = $config[$indexkey];
    if($isRepairSpider) {
        $deltaconfpath = '/data/project/kongsearch/conf/productES_delta_spider.ini';
    } else {
        $deltaconfpath = '/data/project/kongsearch/conf/productES_delta.ini';
    }
    $gatherconfig = GatherES::getConfig($deltaconfpath);
    
    $productadb = '192.168.2.172';
    $productbdb = '192.168.2.173';
    $shopdb     = '192.168.1.67';
    $userdb     = '192.168.1.4';
    
    if($isRepairSpider) {
        $searchHost = '192.168.1.137';
        $searchPort = '9700';
    } else {
        $searchHost = '192.168.2.19';
        $searchPort = '9800';
    }
    $searchIndex = 'item';
    $searchType = 'product';
    $maxLoad    = '45.0';
    
    $redis = '192.168.1.137:6379';
    $repairKey = 'IndexUpdate:repairProductES';
    $expire    = 86400; //一天
    
    $link2 = mysql_pconnect($shopdb, 'shop20150720', 'x0qJq3yTCE'); //shop链接
    mysql_select_db('shop', $link2);
    mysql_query("SET NAMES 'utf8'", $link2);
    
    $userLink = mysql_pconnect($userdb, 'user20150720', 'lYCVa7Ljwm'); //user链接
    mysql_select_db('kongv2', $userLink);
    mysql_query("SET NAMES 'utf8'", $userLink);
    
    $getUnSearchIdSql   = "SELECT shopId FROM unsearchedShop";
    $getUnSearchIdQuery = mysql_query($getUnSearchIdSql, $link2);
    $unSearchIdArr = array();
    while($getUnSearchIdResult = mysql_fetch_assoc($getUnSearchIdQuery)) {
        $unSearchIdArr[] = $getUnSearchIdResult['shopId'];
    }
    
    $allTotal = 0;
    $allSuc   = 0;
    $allErr   = 0;
    $startTime = date("Y-m-d H:i:s");
    $startTimeStamp = time();
    
    $bigDiffUserArr = array();
    $bigDiffUserNum = 0;
    $bigDiffItemNum = 0;
    
    $delTotal = 0;
    
    if($dealType == 'single') { //处理单个用户
        $getMemSql    = "SELECT lastActive FROM member WHERE userId={$userId}";
        $getMemQuery  = mysql_query($getMemSql, $userLink);
        $getMemResult = mysql_fetch_assoc($getMemQuery);
        $lastActive = $getMemResult['lastActive'];
        if(empty($lastActive) || (time() - strtotime($lastActive) > 3600*24*30)) { //如果用户30天未登录则跳过
            echo "--------------------The UserId {$userId} 30 Days Not Login !!!--------------------\n";
            exit;
        }
        $result = repairSingle($userId, 0, $isStrict);
        if(is_array($result)) {
            $allTotal += $result['total'];
            $allSuc   += $result['suc'];
            $allErr   += $result['err'];
            if(isset($result['isModify'])) {
                repairSingle($userId, 1, $isStrict);
            }
        } elseif ($result < 0) {
            echo "The Process Is Exit !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
            exit;
        }
    } elseif ($dealType == 'multi') { //处理多个指定的用户
        $userArr = array(
            '1196600', 
            '21492', 
            '194234', 
            '2343030', 
            '1503792', 
            '115406', 
            '1457457', 
            '2709436', 
            '1897227', 
            '4530593', 
            '3068533',
            '2046125',
            '3849627',
            '2144100',
            '1874163',
            '1645335',
            '3193982',
            '3292176'
        );
        foreach($userArr as $userId) {
            $getMemSql    = "SELECT lastActive FROM member WHERE userId={$userId}";
            $getMemQuery  = mysql_query($getMemSql, $userLink);
            $getMemResult = mysql_fetch_assoc($getMemQuery);
            $lastActive = $getMemResult['lastActive'];
            if(empty($lastActive) || (time() - strtotime($lastActive) > 3600*24*30)) { //如果用户30天未登录则跳过
                echo "--------------------The UserId {$userId} 30 Days Not Login !!!--------------------\n";
                exit;
            }
            $result = repairSingle($userId, 0, $isStrict);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1, $isStrict);
                }
            } elseif ($result < 0) {
                echo "The Process Is Exit !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
                exit;
            }
        }
    } elseif ($dealType == 'all') { //处理所有用户
//        $getUserIdSql    = "SELECT userId FROM shopInfo WHERE {$where} AND shopStatus='onSale' ORDER BY userId ASC";
        $getUserIdSql    = "SELECT userId FROM shopInfo WHERE {$where} ORDER BY userId ASC";
        $getUserIdQuery  = mysql_query($getUserIdSql, $link2);
        while($getUserIdResult = mysql_fetch_assoc($getUserIdQuery)) {
            $userId = $getUserIdResult['userId'];
            $getMemSql    = "SELECT lastActive FROM member WHERE userId={$userId}";
            if(!mysql_ping($userLink)) {
                mysql_close($userLink);
                $userLink = mysql_pconnect($userdb, 'user20150720', 'lYCVa7Ljwm'); //user链接
                mysql_select_db('kongv2', $userLink);
                mysql_query("SET NAMES 'utf8'", $userLink);
            }
            $getMemQuery  = mysql_query($getMemSql, $userLink);
            if(!$getMemQuery) {
                $userLink = mysql_pconnect($userdb, 'user20150720', 'lYCVa7Ljwm'); //user链接
                mysql_select_db('kongv2', $userLink);
                mysql_query("SET NAMES 'utf8'", $userLink);
                $getMemQuery  = mysql_query($getMemSql, $userLink);
            }
            $getMemResult = mysql_fetch_assoc($getMemQuery);
            $lastActive = $getMemResult['lastActive'];
            if(empty($lastActive) || (time() - strtotime($lastActive) > 3600*24*30)) { //如果用户30天未登录则跳过
                echo "--------------------The UserId {$userId} 30 Days Not Login !!!--------------------\n";
                continue;
            }
            
            $result = repairSingle($userId, 0, $isStrict);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1, $isStrict);
                }
            } elseif ($result < 0) {
                echo "The Process Is Exit !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
                exit;
            }
        }
    } elseif ($dealType == 'retry') { //失败重试
        $redisConf = explode(':', $redis);
        $redisLink  = new Redis();
        if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1]) === false) {
            echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
            exit;
        }
        while(($userId = $redisLink->lPop($repairKey)) !== false) {
            $result = repairSingle($userId, 0, $isStrict);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1, $isStrict);
                }
            } elseif ($result < 0) {
                echo "The Process Is Exit !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
                exit;
            }
        }
    }
    $endTime = date("Y-m-d H:i:s");
    $endTimeStamp = time();
    $timeDiff = $endTimeStamp - $startTimeStamp;
    $timeDiff_H = floor($timeDiff / 3600);
    $timeDiff_I = floor(($timeDiff - $timeDiff_H * 3600) / 60);
    $timeDiff_S = $timeDiff % 60;
    
    echo "All Is Done !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
    if($maxFlag) {
        echo "The BigDiffUserNum Is {$bigDiffUserNum} . The BigDiffItemNum Is {$bigDiffItemNum} \n";
        if($printMaxFlag && !is_empty($bigDiffUserArr)) {
            echo "<pre>";
            print_r($bigDiffUserArr);
            echo "</pre>";
        }
    }
    echo "Start Time : $startTime . End Time : $endTime . Time-consuming : {$timeDiff_H}h:{$timeDiff_I}m:{$timeDiff_S}s.\n";
    
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
    
    // 此方法依赖于mbstring扩展。
    function fan2jian($value)
    {
        global $Unihan;

        if ($value === '')
            return '';
        $r = '';
        $len = mb_strlen($value, 'UTF-8');
        for ($i = 0; $i < $len; $i++) {
            $c = mb_substr($value, $i, 1, 'UTF-8');
            if (isset($Unihan[$c]))
                $c = $Unihan[$c];
            $r .= $c;
        }

        return $r;
    }
    
    /**
     * repairSingle
     * 
     * @global array  $config
     * @global array  $indexconfig
     * @global array  $gatherconfig
     * @global string $gatherlogpath
     * @global string $shopdb
     * @global string $productadb
     * @global string $productbdb
     * @global string $searchHost
     * @global string $searchPort
     * @global string $searchIndex
     * @global string $searchType
     * @global float  $maxLoad
     * @global string $redis
     * @global string $repairKey
     * @global int    $expire
     * @global array  $unSearchIdArr
     * @global array  $bigDiffUserArr
     * @global int    $bigDiffUserNum
     * @global int    $bigDiffItemNum
     * @global int    $maxFlag
     * @global int    $delTotal
     * @global int    $maxDeleteNum
     * @global int    $singleMaxDeleteNum
     * @param  int    $userId
     * @param  int    $isModify
     * @param  int    $isStrict
     * @return int
     */
    function repairSingle($userId, $isModify=0, $isStrict=0)
    {
        global $config;
        global $indexconfig;
        global $gatherconfig;
        global $gatherlogpath;
        global $shopdb;
        global $productadb;
        global $productbdb;
        global $searchHost;
        global $searchPort;
        global $searchIndex;
        global $searchType;
        global $maxLoad;
        global $redis;
        global $repairKey;
        global $expire;
        global $unSearchIdArr;
        global $bigDiffUserArr;
        global $bigDiffUserNum;
        global $bigDiffItemNum;
        global $maxFlag;
        global $ignoreGatherFlag;
        global $delTotal;
        global $maxDeleteNum;
        global $singleMaxDeleteNum;
        
        if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while(true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if($loadStatus) {
                    break;
                }
            }
        }
        
        $type = 'shop';
        
        echo "--------------------Now Repairing UserId : {$userId} [". date('Y-m-d H:i:s', time()). "]-----------------------\n";
        
        $redisConf = explode(':', $redis);
        $redisLink  = new Redis();
        if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1])) {
            echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
            return -1;
        }
        
        $link2 = mysql_pconnect($shopdb, 'shop20150720', 'x0qJq3yTCE'); //shop链接
        mysql_select_db('shop', $link2);
        mysql_query("SET NAMES 'utf8'", $link2);
        
        $getTableSql    = "SELECT * FROM userMap WHERE userId='$userId'"; //跟据用户查得分表ID
        $getTableQuery  = mysql_query($getTableSql, $link2);
        $getTableResult = mysql_fetch_assoc($getTableQuery);
        $tableId = $getTableResult['tableId'];
        if(!$tableId) {
            echo "Has Not Get TableId !!! \n";
            $redisLink->rPush($repairKey, $userId);
            if($redisLink->ttl($repairKey) < 0) {
                $redisLink->expire($repairKey, $expire);
            }
            return 0;
        }
        if(!$ignoreGatherFlag && $tableId > 50000) {
            echo "--------------------The Table Id Is Greater Then 50000 !!!--------------------\n";
            return 0;
        }
        
        $getDbSql    = "SELECT * FROM tableMap WHERE tableId=$tableId"; //跟据分表ID查得slave和db
        $getDbQuery  = mysql_query($getDbSql, $link2);
        $getDbResult = mysql_fetch_assoc($getDbQuery);
        $slaveHost = $getDbResult['slaveHost'];
        $dbName = $getDbResult['dbName'];
        if(!$slaveHost || !$dbName) {
            echo "Has Not Get SlaveHost Or DbName !!! \n";
            $redisLink->rPush($repairKey, $userId);
            if($redisLink->ttl($repairKey) < 0) {
                $redisLink->expire($repairKey, $expire);
            }
            return 0;
        }
        if($dbName == 'product_a1' || $dbName == 'product_a2') {
            $slaveHost = $productadb;
            $slaveUser = 'producta20150720';
            $slavePass = 'Pqp5YACzO7';
        } elseif ($dbName == 'product_b1' || $dbName == 'product_b2') {
            $slaveHost = $productbdb;
            $slaveUser = 'productb20150720';
            $slavePass = 'guDvP39EZn';
        }
        
        $getTypeSql    = "SELECT * FROM shopInfo WHERE userId='$userId'"; //查得店铺类型
        $getTypeQuery  = mysql_query($getTypeSql, $link2);
        $getTypeResult = mysql_fetch_assoc($getTypeQuery);
        $shopType = $getTypeResult['shopType'] == 'shop' ? 1 : 2;
        $shopStatus = $getTypeResult['shopStatus'];
        if(!$shopType) {
            echo "Has Not Get ShopType !!! \n";
            $redisLink->rPush($repairKey, $userId);
            if($redisLink->ttl($repairKey) < 0) {
                $redisLink->expire($repairKey, $expire);
            }
            return 0;
        }
        $shopId = $getTypeResult['shopId'];
        $shopName = $getTypeResult['shopName'];
        if(in_array($shopId, $unSearchIdArr)) {
            echo "--------------------The UserId {$userId} In The Unsearch List !!!--------------------\n";
            return 0;
        }
        
        $link3 = mysql_pconnect($slaveHost, $slaveUser, $slavePass); //product链接
        if(!$link3) {
            echo "Count Not Connect Mysql Host {$slaveHost}  -----  Current UserId {$userId}\n";
            return -1;
        }
        mysql_select_db($dbName, $link3);
        mysql_query("SET NAMES 'utf8'", $link3);
        
        echo "Current Host $slaveHost\n";
        echo "Current DB $dbName\n";
        echo "Current Table item_{$tableId}\n";
        
        $condition = array();
        $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
        $condition['filter']['must'][] = array('field' => 'isdeleted', 'value' => 0);
        $condition['filter']['must'][] = array('field' => 'certifystatus', 'value' => 1);
        $condition['filter']['must'][] = array('field' => 'shopstatus', 'value' => 1);
        $condition['filter']['must'][] = array('field' => 'salestatus', 'value' => 0);
        $condition['query']['type'] = 'bool';
        $condition['query']['must'][] = array('field' => '_shopname', 'value' => fan2jian($shopName));
        $condition['limit'] = array('from' => 0, 'size' => 1);
        $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
        $searchNum = $searchNumResult['total'];
        
        $now = time();
        $dbItemNumSql    = "SELECT count(*) AS num FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //在mysql中数量
        $dbItemNumQuery  = mysql_query($dbItemNumSql, $link3);
        $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
        $dbItemNum = $dbItemNumResult['num'];
        if(mysql_errno($link3)) {
            echo mysql_errno($link3) . ": " . mysql_error($link3) . "\n";
            if(mysql_errno($link3) == '2006') { //2006: MySQL server has gone away
                mysql_close($link3);
                unset($link3);
                $link3 = mysql_pconnect($slaveHost, $slaveUser, $slavePass); //product链接
                if(!$link3) {
                    echo "Count Not Connect Mysql Host {$slaveHost}  -----  Current UserId {$userId}\n";
                    exit;
                }
                $dbItemNumSql    = "SELECT count(*) AS num FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //在mysql中数量
                $dbItemNumQuery  = mysql_query($dbItemNumSql, $link3);
                $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
                $dbItemNum = $dbItemNumResult['num'];
                if($dbItemNum < 1  && $dbItemNum !== 0) {
                    echo "The DbItemNum Is Error. \n";
                    return 0;
                }
            } else {
                exit;
            }
        }
        
        if($isStrict == 0 && $searchNum == $dbItemNum && ($shopStatus !== 'pause' || $shopStatus !== 'close')) { //在不严格检测下数量相等则认为数据一致
            echo "The DB Has Num : $dbItemNum \n";
            echo "The Search Has Num : $searchNum \n";
            echo "Current Table item_{$tableId} Is All Right !!! \n";
            return 0;
        }
        
        if($dbItemNum > 0 && $searchNum == 0) {
            $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit']), array(), array(), 60); //在搜索中数量
            $searchNum = $searchNumResult['total'];
            echo "The DB Has Num > 0 AND The Search Has Num = 0 , Get The Search Num Again : $searchNum \n";
        }
        
        if($dbItemNum - $searchNum > 10000) {
            $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit']), array(), array(), 60); //在搜索中数量
            $lastSearchNum = $searchNum;
            $searchNum = $searchNumResult['total'];
            echo "[The DB Has Num] - [The Search Has Num] > 10000 , Get The Search Num Again : $searchNum \n";
            if(abs($lastSearchNum - $searchNum) > 500) {
                $searchNum = $lastSearchNum > $searchNum ? $lastSearchNum : $searchNum;
            }
        }
        
        $getItemIdSql    = "SELECT itemId FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //从mysql中取得符合条件的商品ID
        $getItemIdQuery  = mysql_query($getItemIdSql, $link3);
        if(mysql_errno($link3)) {
            echo mysql_errno($link3) . ": " . mysql_error($link3) . "\n";
            return 0;
        }
        $dbItemIdArr = array();
        while($getItemIdResult = mysql_fetch_assoc($getItemIdQuery)) {
            $dbItemIdArr[] = $getItemIdResult['itemId'];
        }
        
        $searchTimes = 0;
        while(true) {
            $searchIdArr = array();
//            if($searchNum < 10000) { //从搜索中取得符合条件的商品ID
//                $condition['limit'] = array('from' => 0, 'size' => 500000);
//                $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit']), array(), array(), 10);
//                foreach($searchResult['data'] as $item) {
//                    $searchIdArr[] = $item['itemid'];
//                }
//            } else {
//                $condition['limit'] = array('from' => 0, 'size' => 500000);
//                $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit']), array(), array(), 10);
//                foreach($searchResult['data'] as $item) {
//                    $searchIdArr[] = $item['itemid'];
//                }
//            }
            $condition['limit'] = array('from' => 0, 'size' => 500000);
            $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60));
            foreach($searchResult['data'] as $item) {
                $searchIdArr[] = $item['itemid'];
            }
            ++$searchTimes;
            if($searchTimes > 3) {
                break;
            }
            if($searchNum > 0 && count($searchIdArr) == 0) {
                sleep(15);
            } else {
                break;
            }
        }
        
        if(count($searchIdArr) == 0) {
            $searchNumResult2 = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
            $searchNum = $searchNumResult2['total'];
            if($searchNum > 0) {
                echo "Notice : The SearchNum Is $searchNum . But Select None .\n";
                return 0;
            }
        }
        
        $dbHasOnly = array_diff($dbItemIdArr, $searchIdArr); //只存在于mysql中
        $searchHasOnly = array_diff($searchIdArr, $dbItemIdArr); //只存在于搜索中
        $dbSearchDiff = array_merge($dbHasOnly, $searchHasOnly); //差集
        $dbHasOnlyNum = count($dbHasOnly);
        $searchHasOnlyNum = count($searchHasOnly);
        echo "The DB Has Num : $dbItemNum \n";
        echo "The DB Has Only : $dbHasOnlyNum \n";
        echo "The Search Has Num : $searchNum \n";
        echo "The Search Has Only : $searchHasOnlyNum \n";
        
        $diffNum = count($dbSearchDiff);
        $diffNum_1 = $diffNum;
        echo "The DB And Search Has Diff Count: $diffNum \n";
//        echo '<pre>';
//        print_r($dbSearchDiff);exit;
        
        
        //******************************** Second [Start] *****************************************
        if($diffNum > 5000) { //如果差异大于5000，则再次计算一次
            if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
                while(true) {
                    sleep(60);
                    $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                    if($loadStatus) {
                        break;
                    }
                }
            }

            $condition = array();
            $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
            $condition['filter']['must'][] = array('field' => 'isdeleted', 'value' => 0);
            $condition['filter']['must'][] = array('field' => 'certifystatus', 'value' => 1);
            $condition['filter']['must'][] = array('field' => 'shopstatus', 'value' => 1);
            $condition['filter']['must'][] = array('field' => 'salestatus', 'value' => 0);
            $condition['query']['type'] = 'bool';
            $condition['query']['must'][] = array('field' => '_shopname', 'value' => fan2jian($shopName));
            $condition['limit'] = array('from' => 0, 'size' => 1);
            $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
            $searchNum = $searchNumResult['total'];

            $now = time();
            $dbItemNumSql    = "SELECT count(*) AS num FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //在mysql中数量
            $dbItemNumQuery  = mysql_query($dbItemNumSql, $link3);
            $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
            $dbItemNum = $dbItemNumResult['num'];
            if(mysql_errno($link3)) {
                echo mysql_errno($link3) . ": " . mysql_error($link3) . "\n";
                if(mysql_errno($link3) == '2006') { //2006: MySQL server has gone away
                    mysql_close($link3);
                    unset($link3);
                    $link3 = mysql_pconnect($slaveHost, $slaveUser, $slavePass); //product链接
                    if(!$link3) {
                        echo "Count Not Connect Mysql Host {$slaveHost}  -----  Current UserId {$userId}\n";
                        exit;
                    }
                    $dbItemNumSql    = "SELECT count(*) AS num FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //在mysql中数量
                    $dbItemNumQuery  = mysql_query($dbItemNumSql, $link3);
                    $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
                    $dbItemNum = $dbItemNumResult['num'];
                    if($dbItemNum < 1  && $dbItemNum !== 0) {
                        echo "The DbItemNum Is Error. \n";
                        return 0;
                    }
                } else {
                    exit;
                }
            }

            if($isStrict == 0 && $searchNum == $dbItemNum && ($shopStatus !== 'pause' || $shopStatus !== 'close')) { //在不严格检测下数量相等则认为数据一致
                echo "***The DB Has Num : $dbItemNum \n";
                echo "***The Search Has Num : $searchNum \n";
                echo "***Current Table item_{$tableId} Is All Right !!! \n";
                return 0;
            }

            if($dbItemNum > 0 && $searchNum == 0) {
                $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
                $searchNum = $searchNumResult['total'];
            }

            if($dbItemNum - $searchNum > 10000) {
                $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
                $searchNum = $searchNumResult['total'];
            }

            $getItemIdSql    = "SELECT itemId FROM item_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND beginSaleTime< $now AND endSaleTime> $now AND bizType=$shopType"; //从mysql中取得符合条件的商品ID
            $getItemIdQuery  = mysql_query($getItemIdSql, $link3);
            if(mysql_errno($link3)) {
                echo mysql_errno($link3) . ": " . mysql_error($link3) . "\n";
                return 0;
            }
            $dbItemIdArr = array();
            while($getItemIdResult = mysql_fetch_assoc($getItemIdQuery)) {
                $dbItemIdArr[] = $getItemIdResult['itemId'];
            }

            $searchTimes = 0;
            while(true) {
                $searchIdArr = array();
                $condition['limit'] = array('from' => 0, 'size' => 500000);
                $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60));
                foreach($searchResult['data'] as $item) {
                    $searchIdArr[] = $item['itemid'];
                }
                ++$searchTimes;
                if($searchTimes > 3) {
                    break;
                }
                if($searchNum > 0 && count($searchIdArr) == 0) {
                    sleep(15);
                } else {
                    break;
                }
            }

            if(count($searchIdArr) == 0) {
                $searchNumResult2 = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
                $searchNum = $searchNumResult2['total'];
                if($searchNum > 0) {
                    echo "***Notice : The SearchNum Is $searchNum . But Select None .\n";
                    return 0;
                }
            }

            $dbHasOnly = array_diff($dbItemIdArr, $searchIdArr); //只存在于mysql中
            $searchHasOnly = array_diff($searchIdArr, $dbItemIdArr); //只存在于搜索中
            $dbSearchDiff = array_merge($dbHasOnly, $searchHasOnly); //差集
            $dbHasOnlyNum = count($dbHasOnly);
            $searchHasOnlyNum = count($searchHasOnly);
            echo "***The DB Has Num : $dbItemNum \n";
            echo "***The DB Has Only : $dbHasOnlyNum \n";
            echo "***The Search Has Num : $searchNum \n";
            echo "***The Search Has Only : $searchHasOnlyNum \n";

            $diffNum = count($dbSearchDiff);
            echo "***The DB And Search Has Diff Count: $diffNum \n";
            $diffNum_2 = $diffNum;
            $dif = abs($diffNum_2 - $diffNum_1);
            if($dif > 100) {
                echo "******The First Different Num Is $diffNum_1 , The Second Different Num Is $diffNum_2 , ABS = $dif , Ignore !\n";
                return 0;
            }
        }
        //******************************** Second [End] *****************************************
        
        
        $errRow = 0;
        $sucRow = 0;
        echo "Now Dealing The Diff !!! \n";
        
        if(($shopStatus == 'pause' || $shopStatus == 'close') && $searchNum > 0) { //暂停关闭店铺
//            ElasticSearchModel::deleteDocument($searchHost, $searchPort, $searchIndex, $searchType, array('key' => 'userid', 'value' => $userId), 2);
            echo "The Shop Status Is '$shopStatus' , Has Terms Num Is $searchNum , All Search Terms Will Be Deleted !\n";
            $tmp = 0;
            foreach($searchIdArr as $itemid) {
                echo "(update)itemid => $itemid .      ";
                ++$tmp;
                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndex, $searchType, $itemid, array('shopstatus' => 0));
                ++$sucRow;
                if($tmp == 3) {
                    echo "\n";
                    $tmp = 0;
                }
            }
            if(count($searchIdArr) % 3 !== 0) {
                echo "\n";
            }
        }

//        if(false) {
        if($searchHasOnlyNum > 0 && $delTotal <= $maxDeleteNum && $searchHasOnlyNum < $singleMaxDeleteNum) { //将只有搜索有的数据删除掉
            $tmp = 0;
            foreach($searchHasOnly as $itemid) {
                echo "(delete)itemid => $itemid .      ";
                ++$tmp;
                ElasticSearchModel::deleteDocument($searchHost, $searchPort, $searchIndex, $searchType, $itemid, 1);
                ++$sucRow;
                ++$delTotal;
//                ElasticSearchModel::updateDocument($searchHost, $searchPort, $searchIndex, $searchType, $itemid, array('isdeleted' => 1));
                if($tmp == 3) {
                    echo "\n";
                    $tmp = 0;
                }
            }
            if(count($searchHasOnly) % 3 !== 0) {
                echo "\n";
            }
        } elseif ($delTotal > $maxDeleteNum) {
            echo "The Delete Num Is Gather Then $maxDeleteNum , Ignore.\n";
        }
        
        $returnArr = array();
//        if(false) {
        if($dbHasOnlyNum > 0) { //处理只有DB有的数据
            if($maxFlag && ($dbHasOnlyNum >= $maxFlag)) {
                $bigDiffUserArr[] = array('userId' => $userId, 'shopId' => $shopId, 'num' => $dbHasOnlyNum);
                ++$bigDiffUserNum;
                $bigDiffItemNum += $dbHasOnlyNum;
                echo "--------------------The Diff Num Is Gather Then {$maxFlag} !!!--------------------\n";
                return 0;
            }
            
            $shard = new Sharding($config['shard']);
            $dbinfo = $shard->getDBInfo($indexconfig['datatable'], $userId, 'master'); //主表在重建模式下从slave取，更新模式从master取数据。
            if($dbinfo === false) {
                echo "Insert Find DbInfo Failure !!! \n";
                return 0;
            }
            $gather = new GatherES($gatherconfig, $gatherlogpath, GatherES::MODE_UPDATE);
            if($gather->init($type, $dbinfo) === false) {
                echo "Insert Gather Init Failure ";
                echo $gather->getErrorInfo(). "\n";
                return 0;
            }

            $tmp = 0;
            foreach($dbHasOnly as $itemid) {
                echo "(insert)itemid => $itemid .      ";
                ++$tmp;
                $records = $gather->getRecord($dbinfo['table'], $itemid);
                if($records === false) {
                    echo "The UserId[ $userId ], The ItemId[ $itemid ] Gather Failure ";
                    echo $gather->getErrorInfo(). "\n";
                    return 0;
                }
                $record = array_change_key_case($records[0], CASE_LOWER);
                $result = ElasticSearchModel::indexDocument($searchHost, $searchPort, $searchIndex, $searchType, $record, $itemid);
//                if(!$result) {
//                    echo "The UserId[ $userId ], The ItemId[ $itemid ] Insert Error\n";
//                    return 0;
//                }
                ++$sucRow;
                if($tmp == 3) {
                    echo "\n";
                    $tmp = 0;
                }
            }
            if(count($dbHasOnly) % 3 !== 0) {
                echo "\n";
            }
        }

        unset($dbSearchDiff);
        unset($dbHasOnly);
        unset($searchHasOnly);
        unset($dbItemIdArr);
        unset($searchIdArr);
        echo "The UserId $userId Dealing Done !!! All Diff : $diffNum ; Success : $sucRow ; Error : $errRow !!! \n";
        $returnArr['total'] = $diffNum;
        $returnArr['suc']   = $sucRow;
        $returnArr['err']   = $errRow;
        return $returnArr;
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -t Deal Type : all single retry
                 -u UserId , Use With -t \"single\"
                 -w Where , For Example : 1=1 , Use With -t \"all\" , non-required
                 -h Help\n";
    }
    
?>