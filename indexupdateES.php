<?php

require_once 'lib/indexupdateES.class.php';
require_once 'lib/utils.php';

ini_set('memory_limit','-1');

/**
 * 索引更新服务
 * @author      zhangxinde
 * @date        2015年6月15日
 * 
 * 索引更新服务会产生下面三个日志(存放在redis中)：
 * (1) IndexUpdateES:indexname                     不断从此队列中取消息
 * (2) IndexUpdateES:YYMMDD                        每天生成一个，有效期7天，记录所有更新消息。
 * (3) IndexUpdateES:indexname:FailureQueue        记录所有更新失败的消息，包括客户端和服务器端的。
 * (4) IndexUpdateES:indexname:UpdateLog           记录重建索引期间所有索引更新消息。
 * 索引更新控制消息：
 * (1) retry: 把IndexUpdateES:indexname:FailureQueue里消息重试一次。
 * (2) redo:  把IndexUpdateES:indexname:UpdateLog里的消息重做一次。
 * (3) rebuild-start: 在redis中设置索引rebuild mode。
 * (4) rebuild-stopped: 在redis中重置索引rebuild mode，并redo。
 * 索引重建模式:
 * IndexUpdateES:indexname:rebuild
 * 索引更新消息来源：
 * (1) redis
 * rebuild:
 * rebuild期间不能恢复。
 */

$cmdopts = getopt('c:i:h');
if ($cmdopts === false || isset($cmdopts['h'])){
    echo "usage: $argv[0] [-c configuration] [-i active index] [-h help]\n";
    exit;
}

if(!isset($cmdopts['c']) || empty($cmdopts['c']))
    $confpath = dirname(__FILE__) . '/conf/indexupdateES.ini';
else
    $confpath = $cmdopts['c'];

$config = IndexUpdateES::getConfig($confpath);
if($config === false) exit;

if(isset($cmdopts['i']) && !empty($cmdopts['i'])) {
    if(!isset($config[$cmdopts['i']])) {
        echo "invalid index.\n";
        exit;
    } else {
        $config['activeindex'] = $cmdopts['i'];
    }
} else {
    echo "empty active index.\n";
    exit;
}

echo "Staring indexupdate service for {$confpath}...\n";
runIndexUpdateService($config);
echo "indexupdate service done.\n";
exit;

function runIndexUpdateService($config)
{
    $index = $config['activeindex'];
    $logfile = $config[$index]['logpath'];
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false) {
        echo "redis connect error \n";
        exit;
    }
    $redis->select(0);

    $indexQueue = "IndexUpdateES:". $index;
    while (true) {
        $m = $redis->lPop($indexQueue);
        if($m === false) {
            sleep(1);
            continue;
        }
        $msg = json_decode($m, true);
        writeUpdateLog($config, $index, $m);
        $checkInfo = checkMsg($config, $msg);
        if ($checkInfo !== true) {
            writeLog("[ERROR] checkMsg error: $checkInfo", $logfile);
            continue;
        }
        switch ($msg['action']) {
            case 'insert':
            case 'custominsert':
            case 'delete':
            case 'modify':
            case 'update':
            case 'customupdate':
            case 'customdeal':
            case 'multiupdate':
                if(($r = doUpdateIndex($config, $msg)) !== true) {              // 错误则记录到失败队列
                    if(pushFailureQueue($config, $index, $m) === false) {       // 失败则记录到日志
                        writeLog("[ERROR] Update Failure: $m", $logfile);
                    }
                }
                break;
            case 'optimize':
                $r = doManageIndex($config, $msg);
                saveAsyncResult($config, $index, $msg['action'], $r);
                break;
            case 'retry':
                $r = retryFailureQueue($config, $index);
                saveAsyncResult($config, $index, 'retry', $r);
                break;
            case 'redo':
                $r = redoUpdateLog($config, $index);
                saveAsyncResult($config, $index, 'redo', $r);
                break;;
            case 'rebuild-start': 
                $r = setRebuildMode($config, $index, 1);
                saveAsyncResult($config, $index, 'rebuild-start', $r);
                break;
            case 'rebuild-stopped':
                $r = doCleanAfterRebuild($config, $index);
                saveAsyncResult($config, $index, 'rebuild-stopped', $r);
                break;
            default:
                $r = "illegal action [{$msg['action']}].";
                break;
        }

        if($r !== true) {
            //writeLog($workload, $logfile);
            writeLog($r, $logfile);
            $result['status'] = false;
            $result['result'] = $r;
        } else {
            $result['status'] = true;
            $result['result'] = "success";
        }
//        if (doUpdateIndex($config, $msg) !== true) {
//            if (pushFailureQueue($config, $index, $m) === false) {//现在不能更新，放入失败队列
//                $redis->lpush($indexQueue, $m);  //现在不能更新，重新插入到队列头部，停止更新。
//                return false;
//            }
//        }
    }

    $redis->close();
}


// 检查消息是否正确
function checkMsg($config, $msg)
{
    $actionlist = array('insert','delete','modify','update','multiupdate','custominsert','customupdate','customdeal',
                        'optimize', 'redo', 'retry', 'rebuild-start', 'rebuild-stopped');
    
    // 检查索引更新动作是否设置
    if(!isset($msg['action']) || empty($msg['action'])) {
        return "[ERROR]: action isn't set.";
    } else if(array_search($msg['action'], $actionlist) === false) {
        return "[ERROR]: illegal action.";
    }
    
    if(!isset($msg['index']) || empty($msg['index'])) {
        return "[ERROR]: index isn't set.";
    }
    
    if(!isset($msg['type']) || empty($msg['type'])) {
        return "[ERROR]: type isn't set.";
    }
    
    return true;
}

// 对索引进行更新操作
function doUpdateIndex($config, $msg)
{
    $index = $msg['index'];
    $logfile = $config[$index]['logpath'];
    $msgPrimaryKey = isset($config[$index]['msgPrimaryKey']) && !empty($config[$index]['msgPrimaryKey']) ? $config[$index]['msgPrimaryKey'] : 'itemId';
    
    try {
        $indexObj = new IndexUpdateES($index, $config);
    } catch (Exception $e) {
        return $e->getMessage();
    }
    
    switch ($msg['action']) {
        case 'insert':
            $r = $indexObj->insert($msg);
            break;
        case 'delete':
            $r = $indexObj->delete($msg);
            break;
        case 'modify':
            $r = $indexObj->modify($msg);
            break;
        case 'update':
            $r = $indexObj->update($msg);
            break;
        case 'multiupdate':
            $r = $indexObj->multiupdate($msg);
            break;
        case 'custominsert':
            $r = $indexObj->custominsert($msg);
            break;
        case 'customupdate':
            $r = $indexObj->customupdate($msg);
            break;
        case 'customdeal':
            $r = $indexObj->customdeal($msg);
            break;
        default:
            return true;
    }
    
    if ($r === false) {
        return $indexObj->getErrorInfo();
    } else {
        if($msg['action'] == 'insert' || $msg['action'] == 'modify') { //insert或modify
            
            if($index == 'item' || $index == 'item_sold') {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data']['itemId']} , userId:{$msg['data']['userId']} , shopId:{$msg['data']['shopId']} }", $logfile);
            } elseif ($index == 'endauction') {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data']['itemId']} , userId:{$msg['data']['userId']} }", $logfile);
            } else {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , id:{$msg['data'][$msgPrimaryKey]} }", $logfile);
            }
            
        } elseif ($msg['action'] == 'multiupdate') { //multiupdate
            
            writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , where:". json_encode($msg['where']). " , data:". json_encode($msg['data']). " }", $logfile);
            
        } elseif ($msg['action'] == 'update' || $msg['action'] == 'customupdate') { //update或customupdate
            
            if($indexObj->getErrorInfo()) {
                writeLog("[NOTICE] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} , notice:". $indexObj->getErrorInfo(). "}", $logfile);
            } else {
                if(count($msg['data']) < 5) {
                    writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} , data:". json_encode($msg['data']). " }", $logfile);
                } else {
                    writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} }", $logfile);
                }
            }
            
        } elseif ($msg['action'] == 'delete') { //delete
            
            if($indexObj->getErrorInfo()) {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} , notice:". $indexObj->getErrorInfo(). "}", $logfile);
            } else {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} }", $logfile);
            }
            
        } elseif ($msg['action'] == 'custominsert') { //custominsert
            
            if($indexObj->getErrorInfo()) {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} , notice:". $indexObj->getErrorInfo(). "}", $logfile);
            } else {
                writeLog("[SUCCESS] => { index:{$msg['index']} , type:{$msg['type']} , action:{$msg['action']} , user:{$msg['user']} , time:{$msg['time']} , itemId:{$msg['data'][$msgPrimaryKey]} }", $logfile);
            }
            
        } elseif ($msg['action'] == 'customdeal') { //customdeal
            writeLog("[SUCCESS] => ". json_encode($msg), $logfile);
        }
        
        return true;
    }
}

// 索引更新管理
function doManageIndex($config, $msg)
{
    $index = $msg['index'];
    $type  = $msg['type'];
    
    try {
        $indexObj = new IndexUpdateES($index, $config);
    } catch (Exception $e) {
        return $e->getMessage();
    }
    
    switch ($msg['action']) {
        case 'optimize':
            $r = $indexObj->optimize($msg);
            break;
        default:
            return true;
    }
    
    if ($r === false) {
        return $indexObj->getErrorInfo();
    } else {
        return true;
    }
}

// 记录所有更新消息，如果处于重建期间则记录updatelog。
function writeUpdateLog($config, $index, $msg)
{
    $today = date("Ymd");
    $logqueue = 'IndexUpdateES:'.$today;
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    $expire = 259200; //3天过期
    if(isset($config[$index]['redis'][2]))
        $expire = $config[$index]['redis'][2];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    
    $redis->select(0);
    // 检查是否处于重建索引期间并且排除索引修复脚本产生的消息(即user为repair的消息，不记录在重建队列里)
    $rebuild = 'IndexUpdateES:'.$index.':rebuild';
    if($redis->get($rebuild) == 1) {
        $msgArr = json_decode($msg, true);
        if($msgArr['user'] != 'repair') {
            $updatelog = 'IndexUpdateES:'.$index.':UpdateLog';
            if($redis->rPush($updatelog, $msg) === false)
                return false;
        }
    }

    if($redis->rPush($logqueue, $msg) === false)
        return false;
    
    if(!empty($expire) && $redis->ttl($logqueue) < 0)
        $redis->expire($logqueue, $expire);
    
    $redis->close();
    return true;
}

// 设置索引是否正在rebuild...
function setRebuildMode($config, $index, $mode)
{
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    $rebuild = 'IndexUpdateES:'.$index.':rebuild';
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    $redis->select(0);
    $r = $redis->set($rebuild, $mode);
    $redis->close();          
    return $r;
}

// 索引rebuild完毕之后需要做一下清理工作。
function doCleanAfterRebuild($config, $index)
{
    // 重置索引rebuid模式
    if(setRebuildMode($config, $index, 0) === false)
        return '[ERROR]: reset rebuild mode failure.';
         
    // redo updatelog
    if(redoUpdateLog($config, $index) === false)
        return '[ERROR]: redo updatelog failure.';
    
    return true;
}

// 从updatelog取出更新消息再更新一次，一旦发生错误则停止。
function redoUpdateLog($config, $index)
{
    $queue = 'IndexUpdateES:'.$index.':UpdateLog';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    
    $redis->select(0);
    while(($msg = $redis->lPop($queue)) !== false) {
        $m = json_decode($msg, true);
        if(checkMsg($config, $m) !== true) //放到updatelog的消息是没有检查过的。
            continue;
        if(doUpdateIndex($config, $m) !== true) {
            if(pushFailureQueue($config, $index, $msg) === false) {//现在不能更新，放入失败队列
                $redis->lpush($queue, $msg);  //现在不能更新，重新插入到队列头部，停止更新。
                return false;
            }
        }
    }
    
    $redis->close();
    return true;
}

// 把更新失败的消息插入到失败队列
function pushFailureQueue($config, $index, $msg)
{
    $queue = 'IndexUpdateES:'.$index.':FailureQueue';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;

    $redis->select(0);
    if($redis->rPush($queue, $msg) === false)
        return false;
    
    $redis->close();
    return true;
}

// 从失败队列中取出消息重试，一旦发生错误则停止重试，记录错误日志。
function retryFailureQueue($config, $index)
{
    $queue = 'IndexUpdateES:'.$index.':FailureQueue';
    $FFqueue = 'IndexUpdateES:'.$index.':FailureQueue:NoMoreTry';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false) {
        return '[ERROR]: connect redis failure for retry';
    }
    
    $redis->select(0);
    while(($msg = $redis->lPop($queue)) !== false) {
        $m = json_decode($msg, true);
        if(checkMsg($config, $m) !== true) //客户端存放到失败队列的消息是没有检查过的。
            continue;
        if(($r = doUpdateIndex($config, $m)) !== true) {
            $redis->rpush($FFqueue, $msg);  //现在不能更新，重新插入到队列头部，停止更新。
//            return $r;
            continue;
        }
    }
    
    $redis->close();
    return true;
}

// 保存异步索引管理操作的结果。
function saveAsyncResult($config, $index, $action, $result)
{
    $key = 'IndexUpdateES:'.$index.':Async:'.$action;
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false) {
        return false;
    }
    
    $redis->select(0);
    if($result !== true) { // 操作失败，则记录失败的原因。
        $redis->set($key, $result);
    } else { // 操作成功，则清除之前可能存在的结果
        $redis->delete($key);
    }
    
    $redis->close();
    return true;
}

?>
