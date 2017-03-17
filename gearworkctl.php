<?php

/**
 * gearman worker的控制脚本
 * @author liuxingzhi @2013.11
 */

$cmdopts = getopt('w:c:n:o:p:s:h');
if (   $cmdopts === false || isset($cmdopts['h']) ||
    !isset($cmdopts['w']) || empty($cmdopts['w']) ||
    !isset($cmdopts['c']) || empty($cmdopts['c'])){
    usage($argv[0]);
    exit;
}

$program = $argv[0];
$worker = $cmdopts['w'];
$workernum = 1;
if(isset($cmdopts['n']) && !empty($cmdopts['n']))
    $workernum = intval($cmdopts['n']);
if(empty($workernum)) $workernum = 1;
$workeropts='';
if(isset($cmdopts['o']) && !empty($cmdopts['o']))
    $workeropts = $cmdopts['o'];

$phpbin = 'php';
if(isset($cmdopts['p']) && !empty($cmdopts['p']))
    $phpbin = $cmdopts['p'];
$stopwithopts = 0;
if(isset($cmdopts['s']) && !empty($cmdopts['s']))
    $stopwithopts = $cmdopts['s'];

$cmd = strtolower($cmdopts['c']);
switch ($cmd) {
    case 'start':
        startWorker($worker,$workeropts,$workernum);
        break;
    case 'stop':
        if($stopwithopts) {
            stopWorker($worker, $workeropts);
        } else {
            stopWorker($worker);
        }
        break;
    case 'restart':
        if($stopwithopts) {
            restartWorker($worker, $workeropts, $workernum, $stopwithopts);
        } else {
            restartWorker($worker, $workeropts, $workernum);
        }
        break;
    default:
        usage($argv[0]);
        break;
}
exit;

function usage($program)
{
    echo "usage: php $program options \n";
    echo "mandatory:
            -w worker
            -o \"worker options\"
            -c start|stop|restart
optional:
            -n worker num, default:1
            -p php-bin
            -h help\n";
}

/**
 * 启动指定个数的worker
 */
function startWorker($worker, $workeropts, $workernum)
{
    for ($i=0; $i < $workernum; $i++) {
        runWorkerProcess($worker, $workeropts);
        sleep(1);
    }
    return true;
}

/**
 * 停止所有Worker
 */
function stopWorker($worker, $workeropts = '')
{
    $procList = getWorkerProcess($worker, $workeropts);
    if ($procList === false)
        return false;
    
    foreach($procList as $pid) {
        echo "Stopping worker#$pid\t";
        shell_exec ("kill -9 $pid");
        echo "Done.\n";
        //等待1秒，避免瞬间杀掉全部Worker进程而无法工作
        sleep(1);
    }
    
    return true;
}

/**
 * 重启指定个数的Worker。
 * 如果$workerNum小于已经启动的Worker进程，则多余进程会被停止。
 * 如果不足指定数量$workerNum的Worker进程，则会启动新的Worker进程。
 * 依次杀死运行中的Worker进程，并重启指定个数的Worker进程,
 * 杀掉一个运行中的Worker进程，接着启动一个新的Worker进程，
 * 避免没有Worker进程执行Gearmand分发的任务，实行平滑重启
 */
function restartWorker($worker, $workeropts, $workernum, $stopwithopts = 0)
{
    $runCount = 0;
    if($stopwithopts) {
        $procList = getWorkerProcess($worker, $workeropts);
    } else {
        $procList = getWorkerProcess($worker);
    }
    if ($procList === false) {
        // 没有worker则启动指定数量的worker
        for ($i=$runCount; $runCount < $workernum; $runCount++) {
            runWorkerProcess($worker, $workeropts);
        }
        return true;
    }
    
    foreach($procList as $pid) {
        echo "Stopping worker#$pid\t";
        shell_exec ("kill -9 $pid");
        echo "done.\n";
        //等待1秒，避免瞬间杀掉全部Worker进程而无法工作
        sleep(1);
        if ($runCount < $workernum) {
            runWorkerProcess($worker, $workeropts);
            $runCount++;
        }
    }

    //补足Worker进程数
    if ($runCount < $workernum) {
        for ($i=$runCount; $runCount < $workernum; $runCount++) 
            runWorkerProcess($worker, $workeropts);
    }

    return true;
}

/**
 * 以后台方式运行一个Worker进程
 */
function runWorkerProcess($worker, $workeropts)
{
    global $phpbin;
    $cmd = sprintf('%s %s %s > /dev/null &', $phpbin, $worker, $workeropts);
    echo "Starting $cmd\t";
    shell_exec($cmd);
    echo "Done.\n";
}

/**
 * 取得运行的Worker进程
 */
function getWorkerProcess($worker, $workeropts = '')
{
    global $program;
    if($workeropts) {
        $cmd = sprintf ("ps aux | grep '%s %s' | grep -v 'grep' | grep -v '{$program}' | awk '{print $2}'", $worker, $workeropts);
    } else {
        $cmd = sprintf ("ps aux | grep '%s' | grep -v 'grep' | grep -v '{$program}' | awk '{print $2}'", $worker);
    }
    $content = shell_exec ($cmd);
    if(empty($content)) return false;
    $procList = explode("\n", trim($content));
    return $procList;
}

?>
