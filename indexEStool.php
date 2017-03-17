<?php

$cmdopts = getopt('i:o:t:l:q:k:a:j:r:u:p:s:h');
if (   $cmdopts === false || isset($cmdopts['h'])    || 
    !isset($cmdopts['i']) || empty($cmdopts['i']) ||
    !isset($cmdopts['o']) || empty($cmdopts['o']) ||
    !isset($cmdopts['t']) || empty($cmdopts['t'])){
    usage($argv[0]);
    exit;
}

$index = $cmdopts['i'];
$type = $cmdopts['t'];
$action = $cmdopts['o'];

$redis = '127.0.0.1:6379';
if(isset($cmdopts['r']) && !empty($cmdopts['r'])) {
    $redis = $cmdopts['r'];
}

$user = '';
if(isset($cmdopts['u']) && !empty($cmdopts['u'])) {
    $user = $cmdopts['u'];
}

$redisInfo = explode(':', $redis);
if(!isset($redisInfo[0])) {
    echo "Redis Set Error.\n";
    exit;
}
if(!isset($redisInfo[1])) {
    $redisInfo[1] = 6379;
}
$redisObj = new Redis();
if($redisObj->pconnect($redisInfo[0], $redisInfo[1]) === false && $redisObj->pconnect($redisInfo[0], $redisInfo[1]) === false) {
    echo "redis connect error \n";
    exit;
}

$indexQueue = "IndexUpdateES:". $index;
$indexInfo = array(
    'index' => $index,
    'type' => $type,
    'user' => $user,
    'time' => date("Y-m-d H:i:s")
    );

switch ($action) {
    case 'retry':
        $indexInfo['action'] = 'retry';
        break;
    case 'redo':
        $indexInfo['action'] = 'redo';
        break;
    case 'start-rebuild': 
        $indexInfo['action'] = 'rebuild-start';
        break;
    case 'stop-rebuild':
        $indexInfo['action'] = 'rebuild-stopped';
        break;
    default:
        echo "illegal action.\n";
        exit;
 }
 
$indexData = json_encode($indexInfo);
if($redisObj->rPush($indexQueue, $indexData) === false) {
    echo "Index Update failure.\n";
} else {
    echo "Index Update success.\n";
}

function usage($program)
{
    echo "usage: php $program options \n";
    echo "mandatory:
            -i index
            -o action, support: 
               insert, delete, modify, update, softdelete, recovery
               truncate, flush, attach, optimize, flushattrs
               retry, redo, rebuild-start, rebuild-stopped
            -t data type, default as same as the index
            -r redis, default: 127.0.0.1:6379
            -u user
            -h help\n";
}
?>
