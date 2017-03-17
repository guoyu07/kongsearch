<?php
    /*****************************************
     * author: xinde
     * 
     * 修复已售商品脚本
     *****************************************/

    require_once ('/data/project/kongsearch/lib/indexupdateclient.php');
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('t:u:w:h');
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
    
    $productadb = '192.168.2.172';
    $productbdb = '192.168.2.173';
    $shopdb     = '192.168.1.67';
    $userdb     = '192.168.1.4';
    
    $searchHost = '192.168.1.68';
    $searchPort = '9307';
    
    $jobservers = '192.168.1.105:4730,192.168.1.132:4730';
    $redis = '192.168.1.137:6379';
    $user = 'repair';
    $password = '';
    $repairKey = 'IndexUpdate:repairProductSold';
    $expire    = 86400; //一天
    
    $indexUpdateObj = new IndexUpdateClient($jobservers, $redis, $user, $password);
    
    $link2 = mysql_pconnect($shopdb, 'shop20150720', 'x0qJq3yTCE'); //shop链接
    mysql_select_db('shop', $link2);
    mysql_query("SET NAMES 'utf8'", $link2);
    
    $userLink = mysql_pconnect($userdb, 'user20150720', 'lYCVa7Ljwm'); //user链接
    mysql_select_db('kongv2', $userLink);
    mysql_query("SET NAMES 'utf8'", $userLink);
    
    $allTotal = 0;
    $allSuc   = 0;
    $allErr   = 0;
    $startTime = date("Y-m-d H:i:s");
    $startTimeStamp = time();
    if($dealType == 'single') { //处理单个用户
        $getMemSql    = "SELECT lastActive FROM member WHERE userId={$userId}";
        $getMemQuery  = mysql_query($getMemSql, $userLink);
        $getMemResult = mysql_fetch_assoc($getMemQuery);
        $lastActive = $getMemResult['lastActive'];
        if(empty($lastActive) || (time() - strtotime($lastActive) > 3600*24*30)) { //如果用户30天未登录则跳过
            echo "--------------------The UserId {$userId} 30 Days Not Login !!!--------------------\n";
            exit;
        }
        $result = repairSingle($userId);
        if(is_array($result)) {
            $allTotal += $result['total'];
            $allSuc   += $result['suc'];
            $allErr   += $result['err'];
            if(isset($result['isModify'])) {
                repairSingle($userId, 1);
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
            $result = repairSingle($userId);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1);
                }
            } elseif ($result < 0) {
                echo "The Process Is Exit !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
                exit;
            }
        }
    } elseif ($dealType == 'all') { //处理所有用户
        $getUserIdSql    = "SELECT userId FROM shopInfo WHERE {$where} AND shopStatus='onSale' ORDER BY userId ASC";
        $getUserIdQuery  = mysql_query($getUserIdSql, $link2);
        while($getUserIdResult = mysql_fetch_assoc($getUserIdQuery)) {
            $userId = $getUserIdResult['userId'];
            $getMemSql    = "SELECT lastActive FROM member WHERE userId={$userId}";
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
            
            $result = repairSingle($userId);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1);
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
            $result = repairSingle($userId);
            if(is_array($result)) {
                $allTotal += $result['total'];
                $allSuc   += $result['suc'];
                $allErr   += $result['err'];
                if(isset($result['isModify'])) {
                    repairSingle($userId, 1);
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
    echo "Start Time : $startTime . End Time : $endTime . Time-consuming : {$timeDiff_H}h:{$timeDiff_I}m:{$timeDiff_S}s.\n";
    
    
    
    function repairSingle($userId, $isModify=0, $isStrict=0)
    {
        global $shopdb;
        global $productadb;
        global $productbdb;
        global $searchHost;
        global $searchPort;
        global $indexUpdateObj;
        global $redis;
        global $repairKey;
        global $expire;
        
        $index = 'product_sold';
        $type = 'shopsold';
        $shardkey = $userId;
        $isAsync = 0;
        
        echo "--------------------Now Repairing UserId : $userId -----------------------\n";
        
        $redisConf = explode(':', $redis);
        $redisLink  = new Redis();
        if($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1])) {
            echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
            return -1;
        }
        
        $link1 = mysql_pconnect($searchHost. ':'. $searchPort, '', ''); //搜索链接
        
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
        if(!$shopType) {
            echo "Has Not Get ShopType !!! \n";
            $redisLink->rPush($repairKey, $userId);
            if($redisLink->ttl($repairKey) < 0) {
                $redisLink->expire($repairKey, $expire);
            }
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
        echo "Current Table saledItem_{$tableId}\n";
        
        $searchNumSql    = "SELECT count(*) AS num FROM product_sold WHERE userid=$userId AND isdeleted=0 AND certifystatus=1 AND shopstatus=1"; //在搜索中数量
        $searchNumQuery  = mysql_query($searchNumSql, $link1);
        $searchNumResult = mysql_fetch_assoc($searchNumQuery);
        $searchNum = $searchNumResult['num'];
        
        $dbItemNumSql    = "SELECT count(*) AS num FROM saledItem_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND bizType=$shopType"; //在mysql中数量
        $dbItemNumQuery  = mysql_query($dbItemNumSql, $link3);
        $dbItemNumResult = mysql_fetch_assoc($dbItemNumQuery);
        $dbItemNum = $dbItemNumResult['num'];
        
        if($isStrict == 0 && $searchNum == $dbItemNum) { //在不严格检测下数量相等则认为数据一致
            echo "Current Table item_{$tableId} Is All Right !!! \n";
            return 0;
        }
        
        $getItemIdSql    = "SELECT itemId FROM saledItem_{$tableId} WHERE userId='$userId' AND certifyStatus='certified' AND isDelete=0 AND bizType=$shopType"; //从mysql中取得符合条件的商品ID
        $getItemIdQuery  = mysql_query($getItemIdSql, $link3);
        $dbItemIdArr = array();
        while($getItemIdResult = mysql_fetch_assoc($getItemIdQuery)) {
            $dbItemIdArr[] = $getItemIdResult['itemId'];
        }
        
        $searchIdArr = array();
        if($searchNum < 10000) { //从搜索中取得符合条件的商品ID
            $getSearchIdSql    = "SELECT id FROM product_sold WHERE userid=$userId AND isdeleted=0 AND certifystatus=1 AND shopstatus=1 LIMIT 10000 OPTION max_matches=10000";
            $getSearchIdQuery  = mysql_query($getSearchIdSql, $link1);
            while($getSearchIdResult = mysql_fetch_assoc($getSearchIdQuery)) {
                $searchIdArr[] = $getSearchIdResult['id'];
            }
        } else {
            $times = ceil($searchNum / 10000);
            $startId = 0;
            for($i = 1; $i <= $times; $i++) {
                $getSearchIdSql    = "SELECT id FROM product_sold WHERE userid=$userId AND isdeleted=0 AND certifystatus=1 AND shopstatus=1 AND id>$startId ORDER BY id ASC LIMIT 10000 OPTION max_matches=10000";
                $getSearchIdQuery  = mysql_query($getSearchIdSql, $link1);
                while($getSearchIdResult = mysql_fetch_assoc($getSearchIdQuery)) {
                    $searchIdArr[] = $getSearchIdResult['id'];
                }
                $searchIdArrNum = count($searchIdArr);
                if($searchIdArrNum < $i * 10000) {
                    break;
                }
                $startId = $searchIdArr[$searchIdArrNum-1];
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
        echo "The DB And Search Has Diff Count: $diffNum \n";
//        echo '<pre>';
//        print_r($dbSearchDiff);exit;
        
        $errRow = 0;
        $sucRow = 0;
        echo "Now Dealing The Diff !!! \n";
        
//        if($searchHasOnlyNum > 0) { //将只有搜索有的数据删除掉
        if(false) {
            $delTimes = ceil($searchHasOnlyNum / 100);
            for($d = 1; $d <= $delTimes; $d++) {
                $sliceStart = ($d - 1) * 100;
                $sliceArr = array_slice($searchHasOnly, $sliceStart, 100);
                $sliceNum = count($sliceArr);
//                $delIdStr = implode(',', $sliceArr);
                $r = $indexUpdateObj->delete($index, $type, $sliceArr, '', $isAsync);
                if($r === false) {
                    $errRow += $sliceNum;
                    echo "(delete)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
                } else {
                    $sucRow += $sliceNum;
                    echo "(delete)Index Update success.\n";
                }
            }
        }
        
        $returnArr = array();
        if($dbHasOnlyNum > 0) { //处理只有DB有的数据
            $returnArr['isModify'] = $isModify;
            if($isModify == 0) { //第一次处理update
                $updateTimes = ceil($dbHasOnlyNum / 100);
                for($u = 1; $u <= $updateTimes; $u++) {
                    $sliceStart = ($u - 1) * 100;
                    $sliceArr = array_slice($dbHasOnly, $sliceStart, 100);
                    $sliceNum = count($sliceArr);
//                    $updateIdStr = implode(',', $sliceArr);
                    $r = $indexUpdateObj->update($index, $type, 'isdeleted=0,certifystatus=1,shopstatus=1', $sliceArr, '', $isAsync);
                    if($r === false) {
                        $errRow += $sliceNum;
                        echo "(update)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
//                        $redisLink->rPush($repairKey, $userId);
//                        if($redisLink->ttl($repairKey) < 0) {
//                            $redisLink->expire($repairKey, $expire);
//                        }
//                        return 0;
                    } else {
                        $sucRow += $sliceNum;
                        echo "(update)Index Update success.\n";
                    }
                }
            } else { //第二次处理则modify
                foreach($dbHasOnly as $itemId) {
                    $r = $indexUpdateObj->insert($index, $type, $itemId, $shardkey, $isAsync);
                    if($r === false) {
                        ++$errRow;
                        echo "(insert)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
                    } else {
                        ++$sucRow;
                        echo "(insert)Index Update success.\n";
                    }
                }
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