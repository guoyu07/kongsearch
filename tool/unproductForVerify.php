<?php

/* * ***************************************
 * author: xinde
 * 
 * 30天未登录图书的搜索增量脚本
 * *************************************** */

require_once ('/data/project/kongsearch/lib/indexupdateclient.php');
set_time_limit(0);
ini_set('memory_limit', -1);
date_default_timezone_set("PRC");

$cmdopts = getopt('t:u:w:h');
if (!$cmdopts || isset($cmdopts['h']) || !isset($cmdopts['t']) || !$cmdopts['t'] || !in_array($cmdopts['t'], array('single', 'all'))) {
    usage($argv[0]);
    exit;
}
$dealType = $cmdopts['t'];
$userId = 0;
if (isset($cmdopts['u']) && trim($cmdopts['u'])) {
    $userId = trim($cmdopts['u']);
}
if ($dealType == 'single' && !$userId) {
    usage($argv[0]);
    exit;
}
$where = '1=1';
if (isset($cmdopts['w']) && trim($cmdopts['w'])) {
    $where = trim($cmdopts['w']);
}

$jobservers = '192.168.1.124:4730';
$redis = '192.168.1.137:6379';
$user = 'repair';
$password = '';
$verifyKey = 'IndexUpdate:unproductForVerify';
$expire = 86400; //一天

$indexUpdateObj = new IndexUpdateClient($jobservers, $redis, $user, $password);

$link2 = mysql_pconnect('192.168.1.67', 'sunyutian', 'sun100112'); //shop链接
mysql_select_db('shop', $link2);
mysql_query("SET NAMES 'utf8'", $link2);

$userLink = mysql_pconnect('192.168.1.4', 'sunyutian', 'sun100112'); //user链接
mysql_select_db('kongv2', $userLink);
mysql_query("SET NAMES 'utf8'", $userLink);

$allTotal = 0;
$allSuc = 0;
$allErr = 0;
if ($dealType == 'single') { //处理单个用户
    $getMemSql = "SELECT lastActive FROM member WHERE userId={$userId}";
    $getMemQuery = mysql_query($getMemSql, $userLink);
    $getMemResult = mysql_fetch_assoc($getMemQuery);
    $lastActive = $getMemResult['lastActive'];
    $isLogin30 = false;
    if ($lastActive && (time() - strtotime($lastActive) < 3600 * 24 * 30)) { //如果用户30天登录过则跳过
        $isLogin30 = true;
    }
    $result = VerifyDelta($userId, $isLogin30);
    if (is_array($result)) {
        $allTotal += $result['total'];
        $allSuc += $result['suc'];
        $allErr += $result['err'];
    } elseif ($result < 0) {
        echo "Connect Redis Error !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
        exit;
    }
} elseif ($dealType == 'all') { //处理所有用户
    $getUserIdSql = "SELECT userId FROM shopInfo WHERE {$where} AND shopStatus='onSale' ORDER BY userId ASC";
    $getUserIdQuery = mysql_query($getUserIdSql, $link2);
    while ($getUserIdResult = mysql_fetch_assoc($getUserIdQuery)) {
        $userId = $getUserIdResult['userId'];
        $getMemSql = "SELECT lastActive FROM member WHERE userId={$userId}";
        $getMemQuery = mysql_query($getMemSql, $userLink);
        $getMemResult = mysql_fetch_assoc($getMemQuery);
        $lastActive = $getMemResult['lastActive'];
        $isLogin30 = false;
        if ($lastActive && (time() - strtotime($lastActive) < 3600 * 24 * 30)) { //如果用户30天登录过则跳过
            $isLogin30 = true;
        }
        $result = VerifyDelta($userId, $isLogin30);
        if (is_array($result)) {
            $allTotal += $result['total'];
            $allSuc += $result['suc'];
            $allErr += $result['err'];
        } elseif ($result < 0) {
            echo "Connect Redis Error !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";
            exit;
        }
    }
}

echo "All Is Done !!! All Total : $allTotal ; All Suc : $allSuc ; All Err : $allErr \n";

function VerifyDelta($userId, $isLogin30) {
    global $indexUpdateObj;
    global $redis;
    global $verifyKey;
    global $expire;

    $index = 'unproduct';
    $shardkey = $userId;
    $isAsync = 0;
    $recordTime = date("Y-m-d H:i:s");

    echo "--------------------({$recordTime}) Now VerifyDelta UserId : $userId -----------------------\n";

    $redisConf = explode(':', $redis);
    $redisLink = new Redis();
    if ($redisLink->pconnect($redisConf[0], $redisConf[1]) === false && $redisLink->pconnect($redisConf[0], $redisConf[1])) {
        echo "Count Not Connect Redis {$redisConf[0]}:{$redisConf[1]}  -----  Current UserId {$userId}\n";
        return -1;
    }
    $link1 = mysql_pconnect('192.168.1.68:9308', '', ''); //unproduct搜索链接

    $link2 = mysql_pconnect('192.168.1.67', 'sunyutian', 'sun100112'); //shop链接
    mysql_select_db('shop', $link2);
    mysql_query("SET NAMES 'utf8'", $link2);

    $getTableSql = "SELECT * FROM userMap WHERE userId='$userId'"; //跟据用户查得分表ID
    $getTableQuery = mysql_query($getTableSql, $link2);
    $getTableResult = mysql_fetch_assoc($getTableQuery);
    $tableId = $getTableResult['tableId'];
    if (!$tableId) {
        echo "Has Not Get TableId !!! \n";
        $redisLink->rPush($verifyKey, $userId);
        if ($redisLink->ttl($verifyKey) < 0) {
            $redisLink->expire($verifyKey, $expire);
        }
        return 0;
    }

    $getDbSql = "SELECT * FROM tableMap WHERE tableId=$tableId"; //跟据分表ID查得slave和db
    $getDbQuery = mysql_query($getDbSql, $link2);
    $getDbResult = mysql_fetch_assoc($getDbQuery);
    $slaveHost = $getDbResult['slaveHost'];
    $dbName = $getDbResult['dbName'];
    if (!$slaveHost || !$dbName) {
        echo "Has Not Get SlaveHost Or DbName !!! \n";
        $redisLink->rPush($verifyKey, $userId);
        if ($redisLink->ttl($verifyKey) < 0) {
            $redisLink->expire($verifyKey, $expire);
        }
        return 0;
    }

    $getTypeSql = "SELECT * FROM shopInfo WHERE userId='$userId'"; //查得店铺类型
    $getTypeQuery = mysql_query($getTypeSql, $link2);
    $getTypeResult = mysql_fetch_assoc($getTypeQuery);
    $shopType = $getTypeResult['shopType'] == 'shop' ? 1 : 2;
    if (!$shopType) {
        echo "Has Not Get ShopType !!! \n";
        $redisLink->rPush($verifyKey, $userId);
        if ($redisLink->ttl($verifyKey) < 0) {
            $redisLink->expire($verifyKey, $expire);
        }
        return 0;
    }

    $link3 = mysql_pconnect($slaveHost, 'sunyutian', 'sun100112'); //product链接
    mysql_select_db($dbName, $link3);
    mysql_query("SET NAMES 'utf8'", $link3);

    echo "Current Host $slaveHost\n";
    echo "Current DB $dbName\n";
    echo "Current Table item_{$tableId} And saledItem_{$tableId}\n";

    $errRow = 0;
    $sucRow = 0;
    if ($isLogin30) { //如果30天内登录过，则删除
        $searchNumSql = "SELECT count(*) AS num FROM unproduct WHERE userid=$userId"; //在搜索中数量
        $searchNumQuery = mysql_query($searchNumSql, $link1);
        $searchNumResult = mysql_fetch_assoc($searchNumQuery);
        $searchNum = $searchNumResult['num'];
        $r = $indexUpdateObj->softdelete($index, 'saleoutandisdeleteitem', '', 'userid=' . $userId, $isAsync);
        if ($r === false) {
            $errRow += $searchNum;
            echo "(softdelete)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
        } else {
            $sucRow += $searchNum;
            echo "(softdelete)Index Update success.\n";
        }
    } else { //如果30天未登录，则判断unproduct中是否有其数据，没有则添加，有则略过
        $searchNumSql = "SELECT count(*) AS num FROM unproduct WHERE userid=$userId AND bizType=$shopType AND isdeleted=0"; //在搜索中数量
        $searchNumQuery = mysql_query($searchNumSql, $link1);
        $searchNumResult = mysql_fetch_assoc($searchNumQuery);
        $searchNum = $searchNumResult['num'];
        if ($searchNum > 0) {
            return 0;
        }
        $itemNumSql = "SELECT count(*) AS num FROM item_{$tableId} WHERE userId=$userId AND bizType=$shopType"; //在item中数量
        $itemNumQuery = mysql_query($itemNumSql, $link3);
        $itemNumResult = mysql_fetch_assoc($itemNumQuery);
        $itemNum = $itemNumResult['num'];

        $saledItemNumSql = "SELECT count(*) AS num FROM saledItem_{$tableId} WHERE userId=$userId"; //在saledItem中数量
        $saledItemNumQuery = mysql_query($saledItemNumSql, $link3);
        $saledItemNumResult = mysql_fetch_assoc($saledItemNumQuery);
        $saledItemNum = $saledItemNumResult['num'];
        $diffNum = $itemNum + $saledItemNum;

        if ($itemNum == 0 && $saledItemNum == 0) {
            echo "Current Table item_{$tableId} AND saledItem_{$tableId} Has None Delta !!! \n";
            return 0;
        }
        if ($itemNum != 0) {
            echo "Current Table item_{$tableId} Is Dealing !!! \n";
            $getItemIdSql = "SELECT itemId FROM item_{$tableId} WHERE userId='$userId' AND bizType=$shopType"; //从item中取得符合条件的商品ID
            $getItemIdQuery = mysql_query($getItemIdSql, $link3);
            while ($getItemIdResult = mysql_fetch_assoc($getItemIdQuery)) {
                $itemId = $getItemIdResult['itemId'];
                $r = $indexUpdateObj->insert($index, 'saleoutandisdeleteitem', $itemId, $shardkey, $isAsync);
                if ($r === false) {
                    ++$errRow;
                    echo "(insert)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
                } else {
                    ++$sucRow;
                    echo "(insert)Index Update success.\n";
                }
            }
        }
        if ($saledItemNum != 0) {
            echo "Current Table saledItem_{$tableId} Is Dealing !!! \n";
            $getSaledItemIdSql = "SELECT itemId FROM saledItem_{$tableId} WHERE userId='$userId' AND bizType=$shopType"; //从saledItem中取得符合条件的商品ID
            $getSaledItemIdQuery = mysql_query($getSaledItemIdSql, $link3);
            while ($getSaledItemIdResult = mysql_fetch_assoc($getSaledItemIdQuery)) {
                $itemId = $getSaledItemIdResult['itemId'];
                $r = $indexUpdateObj->insert($index, 'saleoutandisdeletesaleditem', $itemId, $shardkey, $isAsync);
                if ($r === false) {
                    ++$errRow;
                    echo "(insert)Index Update failure: {$indexUpdateObj->getErrorInfo()}\n";
                } else {
                    ++$sucRow;
                    echo "(insert)Index Update success.\n";
                }
            }
        }
    }


    echo "The UserId $userId Dealing Done !!! All Diff : $diffNum ; Success : $sucRow ; Error : $errRow !!! \n";
    $returnArr['total'] = $diffNum;
    $returnArr['suc'] = $sucRow;
    $returnArr['err'] = $errRow;
    return $returnArr;
}

function usage($program) {
    echo "usage:php $program options \n";
    echo "mandatory:
                 -t Deal Type : all single retry
                 -u UserId , Use With -t \"single\"
                 -w Where , For Example : 1=1 , Use With -t \"all\" , non-required
                 -h Help\n";
}

?>