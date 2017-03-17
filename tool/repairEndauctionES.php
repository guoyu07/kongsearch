<?php
    /*****************************************
     * author: xinde
     * 
     * 修复商品脚本(nohup php tool/repairEndauctionES.php -t "all" -w "userId>12052" -m "50000" > /data/kongsearch_logs/endES.log &)
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    require_once '/data/project/kongsearch/lib/sharding.php';
    require_once '/data/project/kongsearch/lib/gatherES.class.php';
    require_once '/data/project/kongsearch/lib/indexupdate.class.php';
    require_once '/data/project/kongsearch/lib/unihan.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('t:u:w:m:p:s:y:z:h');
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
    $isStrict = 0;
    if(isset($cmdopts['s']) && intval($cmdopts['s']) == 1) {
        $isStrict = 1;
    }
    $isRepairSpider = 0;
    if(isset($cmdopts['z']) && intval($cmdopts['z']) == 1) {
        $isRepairSpider = 1;
    }
    $itemStatus = 0;
    if(isset($cmdopts['y']) && intval($cmdopts['y']) > 0) {
        $itemStatus = $cmdopts['y'];
    }
    //最大可删除数量
    $maxDeleteNum = 100000;
    $singleMaxDeleteNum = 10000;
    
    $gatherlogpath = '/data/kongsearch_logs/es_endauction_indexupdate.log';
    $confpath = '/data/project/kongsearch/conf/indexupdate.ini';
    $config = IndexUpdate::getConfig($confpath);
    $indexkey = 'endauction';
    $indexconfig = $config[$indexkey];
    $deltaconfpath = '/data/project/kongsearch/conf/endauctionES_delta.ini';
    $gatherconfig = GatherES::getConfig($deltaconfpath);
    
    $searchHost = '192.168.1.68';
    $searchPort = '9600';
    $searchIndex = 'endauction';
    $searchType = 'endauction';
    $maxLoad    = '45.0';
    
    $pmDbHost   = '192.168.2.225';
    $pmDbPort   = '3306';
    $pmDbUser   = 'pmv220150720';
    $pmDbPass   = 'S2wY2SS9hO';
    
    $redis = '192.168.1.137:6379';
    $repairKey = 'IndexUpdate:repairEndauctionES';
    $expire    = 86400; //一天
    
    $link2 = mysql_pconnect($pmDbHost, $pmDbUser, $pmDbPass); //pm链接
    mysql_select_db('pmv2', $link2);
    mysql_query("SET NAMES 'utf8'", $link2);
    
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
            '1'
        );
        foreach($userArr as $userId) {
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
        $getUserIdSql    = "SELECT userId FROM auctioneer WHERE {$where} ORDER BY userId ASC";
        $getUserIdQuery  = mysql_query($getUserIdSql, $link2);
        while($getUserIdResult = mysql_fetch_assoc($getUserIdQuery)) {
            $userId = $getUserIdResult['userId'];
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
     * @global string $searchHost
     * @global string $searchPort
     * @global string $searchIndex
     * @global string $searchType
     * @global string $pmDbHost
     * @global string $pmDbPort
     * @global string $pmDbUser
     * @global string $pmDbPass
     * @global float  $maxLoad
     * @global string $redis
     * @global string $repairKey
     * @global int    $expire
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
     * @param  int    $itemStatus
     * @return int
     */
    function repairSingle($userId, $isModify=0, $isStrict=0)
    {
        global $config;
        global $indexconfig;
        global $gatherconfig;
        global $gatherlogpath;
        global $searchHost;
        global $searchPort;
        global $searchIndex;
        global $searchType;
        global $pmDbHost;
        global $pmDbPort;
        global $pmDbUser;
        global $pmDbPass;
        global $maxLoad;
        global $redis;
        global $repairKey;
        global $expire;
        global $bigDiffUserArr;
        global $bigDiffUserNum;
        global $bigDiffItemNum;
        global $maxFlag;
        global $delTotal;
        global $maxDeleteNum;
        global $singleMaxDeleteNum;
        global $itemStatus;
        
        if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while(true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if($loadStatus) {
                    break;
                }
            }
        }
        
        $type = 'endauction';
        
        echo "--------------------Now Repairing UserId : {$userId} [". date('Y-m-d H:i:s', time()). "]-----------------------\n";
        
        $redisConf = explode(':', $redis);
        $redisLink  = new Redis();
        if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1])) {
            echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
            return -1;
        }
        
        $link2 = mysql_pconnect($pmDbHost, $pmDbUser, $pmDbPass); //pm链接
        mysql_select_db('pmv2', $link2);
        mysql_query("SET NAMES 'utf8'", $link2);
        
        $getTableSql    = "SELECT * FROM sellerTableMap WHERE userId='$userId'"; //跟据用户查得分表ID
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
        
        $condition = array();
        $condition['filter']['must'][] = array('field' => 'userid', 'value' => $userId);
        if($itemStatus) {
            $condition['filter']['must'][] = array('field' => 'itemstatus', 'value' => $itemStatus);
        }
        $condition['query'] = array();
        $condition['limit'] = array('from' => 0, 'size' => 1);
        $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
        $searchNum = $searchNumResult['total'];
        
        $now = time();
        if($itemStatus) {
            $dbItemNumSql    = "SELECT count(*) AS num FROM endItem_{$tableId} WHERE userId='$userId' AND itemStatus='$itemStatus'"; //在mysql中数量
        } else {
            $dbItemNumSql    = "SELECT count(*) AS num FROM endItem_{$tableId} WHERE userId='$userId'"; //在mysql中数量
        }
        $dbItemNumQuery  = mysql_query($dbItemNumSql, $link2);
        $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
        $dbItemNum = $dbItemNumResult['num'];
        if(mysql_errno($link2)) {
            echo mysql_errno($link2) . ": " . mysql_error($link2) . "\n";
            if(mysql_errno($link2) == '2006') { //2006: MySQL server has gone away
                mysql_close($link2);
                unset($link2);
                $link2 = mysql_pconnect($pmDbHost, $pmDbUser, $pmDbPass); //pm链接
                if(!$link2) {
                    echo "Count Not Connect Mysql Host {$pmDbHost}  -----  Current UserId {$userId}\n";
                    exit;
                }
                $dbItemNumQuery  = mysql_query($dbItemNumSql, $link2);
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
        
        if($isStrict == 0 && $searchNum == $dbItemNum) { //在不严格检测下数量相等则认为数据一致
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
        
        if($itemStatus) {
            $getItemIdSql    = "SELECT itemId FROM endItem_{$tableId} WHERE userId='$userId' AND itemStatus='$itemStatus'"; //从mysql中取得符合条件的商品ID
        } else {
            $getItemIdSql    = "SELECT itemId FROM endItem_{$tableId} WHERE userId='$userId'"; //从mysql中取得符合条件的商品ID
        }
        $getItemIdQuery  = mysql_query($getItemIdSql, $link2);
        if(mysql_errno($link2)) {
            echo mysql_errno($link2) . ": " . mysql_error($link2) . "\n";
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
            if($itemStatus) {
                $condition['filter']['must'][] = array('field' => 'itemstatus', 'value' => $itemStatus);
            }
            $condition['query'] = array();
            $condition['limit'] = array('from' => 0, 'size' => 1);
            $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, array('itemid'), $condition['query'], $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
            $searchNum = $searchNumResult['total'];

            $now = time();
            $dbItemNumQuery  = mysql_query($dbItemNumSql, $link2);
            $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
            $dbItemNum = $dbItemNumResult['num'];
            if(mysql_errno($link2)) {
                echo mysql_errno($link2) . ": " . mysql_error($link2) . "\n";
                if(mysql_errno($link2) == '2006') { //2006: MySQL server has gone away
                    mysql_close($link2);
                    unset($link2);
                    $link2 = mysql_pconnect($pmDbHost, $pmDbUser, $pmDbPass); //pm链接
                    if(!$link2) {
                        echo "Count Not Connect Mysql Host {$pmDbHost}  -----  Current UserId {$userId}\n";
                        exit;
                    }
                    $dbItemNumQuery  = mysql_query($dbItemNumSql, $link2);
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

            if($isStrict == 0 && $searchNum == $dbItemNum) { //在不严格检测下数量相等则认为数据一致
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

            $getItemIdQuery  = mysql_query($getItemIdSql, $link2);
            if(mysql_errno($link2)) {
                echo mysql_errno($link2) . ": " . mysql_error($link2) . "\n";
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
                $bigDiffUserArr[] = array('userId' => $userId, 'num' => $dbHasOnlyNum);
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