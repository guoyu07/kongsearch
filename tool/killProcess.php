<?php
$program = $argv[0];
$worker = $argv[1];
if(!trim($worker)) {
    echo "None.\n";
}

function getWorkerProcess($worker)
{
    global $program;
    $cmd = sprintf ("ps aux | grep '%s' | grep -v 'grep' | grep -v '{$program}' | awk '{print $2}'", $worker);
    $content = shell_exec ($cmd);
    if(empty($content)) return false;
    $procList = explode("\n", trim($content));
    return $procList;
}

function stopWorker($worker)
{
    $procList = getWorkerProcess($worker);
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

stopWorker($worker);
?>