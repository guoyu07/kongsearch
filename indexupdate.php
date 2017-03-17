<?php

require_once 'lib/indexupdate.class.php';
require_once 'lib/utils.php';

ini_set('memory_limit','-1');

/**
 * 索引更新服务 for gearmand worker
 * @author      liuxingzhi
 * @date        2013-09
 */

$cmdopts = getopt('c:i:h');
if ($cmdopts === false || isset($cmdopts['h'])){
    echo "usage: $argv[0] [-c configuration] [-i active index] [-h help]\n";
    exit;
}

if(!isset($cmdopts['c']) || empty($cmdopts['c']))
    $confpath = dirname(__FILE__) . '/conf/indexupdate.ini';
else
    $confpath = $cmdopts['c'];

$config = IndexUpdate::getConfig($confpath);
if($config === false) exit;

if(isset($cmdopts['i']) && !empty($cmdopts['i'])) {
    if(!isset($config[$cmdopts['i']])) {
        echo "invalid index.\n";
        exit;
    } else {
        $config['activeindex'] = $cmdopts['i'];
    }
}

echo "Staring indexupdate service for {$confpath}...\n";
runIndexUpdateService($config);
echo "indexupdate service done.\n";
exit;

function runIndexUpdateService($config)
{
    if(isset($config['activeindex']) && !empty($config['activeindex'])) {
        $jobServers = $config[$config['activeindex']]['jobservers'];
    } else if(isset($config['jobservers'])){
        $jobServers = $config['jobservers'];
    } else {
        echo "global jobservers isn't set.\n";
        return false;
    }
    
    $worker = new GearmanWorker();
    $worker->addServers($jobServers);
    $worker->addFunction('updateIndex', 'updateIndex');
    while (@$worker->work()) {
        if ($worker->returnCode() != GEARMAN_SUCCESS) {
            echo "[ERROR] return_code: " . $worker->returnCode() . ":". $worker->error();
            break;
        }
    }
}

/**
 * 更新索引。
 * 索引更新服务会产生下面三个日志(存放在redis中)：
 * (1) IndexUpdate:YYMMDD                        每天生成一个，有效期30天，记录所有更新消息。
 * (2) IndexUpdate:indexname:FailureQueue        记录所有更新失败的消息，包括客户端和服务器端的。
 * (3) IndexUpdate:indexname:UpdateLog           记录重建索引期间所有索引更新消息。
 * 索引更新控制消息：
 * (1) retry: 把IndexUpdate:indexname:FailureQueue里消息重试一次。
 * (2) redo:  把IndexUpdate:indexname:UpdateLog里的消息重做一次。
 * (3) rebuild-start: 在redis中设置索引rebuild mode。
 * (4) rebuild-stopped: 在redis中重置索引rebuild mode，并truncate、 redo。
 * 索引重建模式:
 * IndexUpdate:indexname:rebuild
 * 索引更新消息来源：
 * (1) gearmand
 * (2) redis
 * rebuild:
 * rebuild期间不能恢复。
 */

function updateIndex($job)
{
    global $config;
    $result = array();
   
    $workload = $job->workload();
    $msg = json_decode($workload, true);

    //检查索引是否有效
    if(!isset($msg['index']) || empty($msg['index']) || !isset($config[$msg['index']]) || 
       (isset($conifg['activeindex']) && !empty($config['activeindex']) && $config['activeindex'] != $msg['index'])) {
        $result['status'] = false;
        $result['result'] = "[ERROR]: invalid index [{$msg['index']}].";
        writeLog($workload, $config['logpath']);
        writeLog($result['result'], $config['logpath']);
        return json_encode($result);
    } else {
       $index = $msg['index'];
    }
    
    //记录日志，如果在rebuild期间则记录updatelog
    $logfile = $config[$index]['logpath'];
    writeLog("Received job: " . $job->handle(), $logfile);
    writeLog($workload, $logfile);
    writeUpdateLog($config, $index, $workload);
    
    //检查消息是否正确
    $r = checkMsg($config, $msg);
    if($r !== true) {
        //writeLog($workload, $logfile);
        writeLog($r, $logfile);
        $result['status'] = false;
        $result['result'] = $r;
        return json_encode($result);
    }
   
    switch ($msg['action']) {
        case 'insert':
        case 'delete':
        case 'modify':
        case 'update':
        case 'softdelete':
        case 'recovery':
            if(($r = doUpdateIndex($config, $msg)) !== true) {              // 错误则记录到失败队列
                if(pushFailureQueue($config, $index, $workload) === false) {// 失败则记录到日志
                    writeLog("[ERROR] Update Failure: $workload", $logfile);
                }
            }
            break;
        case 'truncate':
        case 'flush':
        case 'attach':
        case 'optimize':
        case 'flushattrs':
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
    
    unset($job);
    unset($workload);
    unset($msg);
    return json_encode($result);
}

// 检查消息是否正确
function checkMsg($config, $msg)
{
    $actionlist = array('insert','delete','modify','update','softdelete','recovery',
                        'truncate', 'flush', 'attach', 'optimize', 'flushattrs',
                        'redo', 'retry', 'rebuild-start', 'rebuild-stopped');
    
    // 检查索引是否有效
    if(!isset($msg['index']) || empty($msg['index']) || !isset($config[$msg['index']]) || 
       (isset($conifg['activeindex']) && !empty($config['activeindex']) && $config['activeindex'] != $msg['index'])) {
        return "[ERROR]: invalid index [{$msg['index']}].";
    } else {
       $index = $msg['index'];
    }
    
    // 检查索引数据类型是否正确
    if(isset($config[$index]['datatype']) && isset($msg['type']) && !empty($msg['type'])) {
        if(array_search($msg['type'], $config[$index]['datatype']) === false) {
            return "[ERROR]: invalid data type [{$msg['type']}].";
        }
    }
    
    // 身份认证
    if(isset($config[$index]['auth']) && !empty($config[$index]['auth'])) {
        $user = '';
        $password = '';
        if(isset($msg['user']))     $user = $msg['user'];
        if(isset($msg['password'])) $password = $msg['password'];
        if(empty($user) || !isset($config[$index]['auth'][$user]) || 
           ($password != $config[$index]['auth'][$user]['password'] && 
            $password != $config[$index]['auth'][$user]['old_password'])) {
            return "[ERROR]: illegal user.";
        }
    }
    
    // 检查索引更新动作是否设置
    if(!isset($msg['action']) || empty($msg['action'])) {
        return "[ERROR]: action isn't set.";
    } else if(array_search($msg['action'], $actionlist) === false) {
        return "[ERROR]: illegal action.";
    }
    
    return true;
}

// 对索引进行更新操作
function doUpdateIndex($config, $msg)
{
    $index = $msg['index'];
    
    try {
        $index = new IndexUpdate($index, $config);
    } catch (Exception $e) {
        return $e->getMessage();
    }
    
    switch ($msg['action']) {
        case 'insert':
            $r = $index->insert($msg['type'], $msg['id'], $msg['shardkey']);
            break;
        case 'delete':
            $r = $index->delete($msg['id'], $msg['where']);
            break;
        case 'modify':
            $r = $index->modify($msg['type'], $msg['id'], $msg['shardkey']);
            break;
        case 'update':
            $r = $index->update($msg['attr'], $msg['id'], $msg['where']);
            break;
        case 'softdelete':
            $r = $index->softdelete($msg['id'], $msg['where']);
            break;
        case 'recovery':
            $r = $index->recovery($msg['id'], $msg['where']);
            break;
        default:
            return true;
    }
    
    if ($r === false) {
        return $index->getErrorInfo();
    } else {
        return true;
    }
}

// 索引更新管理
function doManageIndex($config, $msg)
{
    $index = $msg['index'];
    
    try {
        $index = new IndexUpdate($index, $config);
    } catch (Exception $e) {
        return $e->getMessage();
    }
    
    switch ($msg['action']) {
        case 'truncate':
            $r = $index->truncate();
            break;
        case 'flush':
            $r = $index->flush();
            break;
        case 'attach':
            $r = $index->attach();
            break;
        case 'optimize':
            $r = $index->optimize();
            break;
        case 'flushattrs':
            $r = $index->flushattrs();
            break;
        default:
            return true;
    }
    
    if ($r === false) {
        return $index->getErrorInfo();
    } else {
        return true;
    }
}

// 记录所有更新消息，如果处于重建期间则记录updatelog。
function writeUpdateLog($config, $index, $msg)
{
    $today = date("Ymd");
    $logqueue = 'IndexUpdate:'.$today;
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    $expire = 604800; //30天过期
    if(isset($config[$index]['redis'][2]))
        $expire = $config[$index]['redis'][2];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    
    // 检查是否处于重建索引期间并且排除索引修复脚本产生的消息(即user为repair的消息，不记录在重建队列里)
    $rebuild = 'IndexUpdate:'.$index.':rebuild';
    if($redis->get($rebuild) == 1) {
        $msgArr = json_decode($msg, true);
        if($msgArr['user'] != 'repair') {
            $updatelog = 'IndexUpdate:'.$index.':UpdateLog';
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
    $rebuild = 'IndexUpdate:'.$index.':rebuild';
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    $r = $redis->set($rebuild, $mode);
    $redis->close();          
    return $r;
}

// 索引rebuild完毕之后需要做一下清理工作。
function doCleanAfterRebuild($config, $index)
{
    // 清空实时索引
    $msg['index'] = $index;
    $msg['action'] = 'truncate';
    if(($r = doManageIndex($config, $msg)) !== true) 
        return "[ERROR]: doCleanAfterRebuild: $r";

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
    $queue = 'IndexUpdate:'.$index.':UpdateLog';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;
    
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
    $queue = 'IndexUpdate:'.$index.':FailureQueue';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false)
        return false;

    if($redis->rPush($queue, $msg) === false)
        return false;
    
    $redis->close();
    return true;
}

// 从失败队列中取出消息重试，一旦发生错误则停止重试，记录错误日志。
function retryFailureQueue($config, $index)
{
    $queue = 'IndexUpdate:'.$index.':FailureQueue';
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false) {
        return '[ERROR]: connect redis failure for retry';
    }
    
    while(($msg = $redis->lPop($queue)) !== false) {
        $m = json_decode($msg, true);
        if(checkMsg($config, $m) !== true) //客户端存放到失败队列的消息是没有检查过的。
            continue;
        if(($r = doUpdateIndex($config, $m)) !== true) {
            $redis->lpush($queue, $msg);  //现在不能更新，重新插入到队列头部，停止更新。
            return $r;
        }
    }
    
    $redis->close();
    return true;
}

// 保存异步索引管理操作的结果。
function saveAsyncResult($config, $index, $action, $result)
{
    $key = 'IndexUpdate:'.$index.':Async:'.$action;
    $host = $config[$index]['redis'][0];
    $port = $config[$index]['redis'][1];
    
    $redis = new Redis();
    if($redis->pconnect($host, $port) === false && $redis->pconnect($host, $port) === false) {
        return false;
    }
    
    if($result !== true) { // 操作失败，则记录失败的原因。
        $redis->set($key, $result);
    } else { // 操作成功，则清除之前可能存在的结果
        $redis->delete($key);
    }
    
    $redis->close();
    return true;
}

?>