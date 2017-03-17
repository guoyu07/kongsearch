<?php

require_once 'lib/indexupdateclient.php';

$cmdopts = getopt('i:o:t:l:q:k:a:j:r:u:p:s:h');
if (   $cmdopts === false || isset($cmdopts['h'])    || 
    !isset($cmdopts['i']) || empty($cmdopts['i']) ||
    !isset($cmdopts['o']) || empty($cmdopts['o'])){
    usage($argv[0]);
    exit;
}

$index = $cmdopts['i'];
$action = $cmdopts['o'];
$type = $index;
if(isset($cmdopts['t']) && !empty($cmdopts['t']))
    $type = $cmdopts['t'];

$id='';
if(isset($cmdopts['l']) && !empty($cmdopts['l'])) {
    $id = explode (',', $cmdopts['l']);
    foreach ($id as $key => $value) {
        $id[$key] = trim($value);
    }
}

$where = '';
if($id === '' && isset($cmdopts['q']) && !empty($cmdopts['q'])) {
    $where = $cmdopts['q'];
}

$shardkey = '';
if(isset($cmdopts['k']) && !empty($cmdopts['k']))
    $shardkey = $cmdopts['k'];

$attr = '';
if(isset($cmdopts['a'])) $attr = $cmdopts['a'];
if($cmdopts['o'] == 'update' && empty($attr)) {
    echo "update attrbute isn't set\n";
    exit;
}

$jobservers = '127.0.0.1:4730';
if(isset($cmdopts['j']) && !empty($cmdopts['j']))
    $jobservers = $cmdopts['j'];

$redis = '127.0.0.1:6379';
if(isset($cmdopts['r']) && !empty($cmdopts['r']))
    $redis = $cmdopts['r'];

$user = '';
if(isset($cmdopts['u']) && !empty($cmdopts['u']))
    $user = $cmdopts['u'];

$password = '';
if(isset($cmdopts['p']) && !empty($cmdopts['p']))
    $password = $cmdopts['p'];

$isAsync = 0;
if(isset($cmdopts['s']) && !empty($cmdopts['s']))
    $isAsync = 1;

$indexObj = new IndexUpdateClient($jobservers, $redis, $user, $password);
switch ($action) {
    case 'insert':
        $r = $indexObj->insert($index, $type, $id, $shardkey, $isAsync);
        break;
    case 'delete':
        $r = $indexObj->delete($index, $type, $id, $where, $isAsync);
        break;
    case 'modify':
        $r = $indexObj->modify($index, $type, $id, $shardkey, $isAsync);
        break;
    case 'update':
        $r = $indexObj->update($index, $type, $attr, $id, $where, $isAsync);
        break;
    case 'softdelete':
        $r = $indexObj->softdelete($index, $type, $id, $where, $isAsync);
        break;
    case 'recovery':
        $r = $indexObj->recovery($index, $type, $id, $where, $isAsync);
        break;
    case 'truncate':
        $r = $indexObj->truncate($index, $type, $isAsync);
        break;
    case 'flush':
        $r = $indexObj->flush($index, $type, $isAsync);
        break;
    case 'attach':
        $r = $indexObj->attach($index, $type, $isAsync);
        break;
    case 'optimize':
        $r = $indexObj->optimize($index, $type, $isAsync);
        break;
    case 'flushattrs':
        $r = $indexObj->flushattrs($index, $type, $isAsync);
        break;
    case 'retry':
        $r = $indexObj->retry($index, $type, $isAsync);
        break;
    case 'redo':
        $r = $indexObj->redo($index, $type, $isAsync);
        break;;
    case 'rebuild-start': 
        $r = $indexObj->rebuild_start($index, $type, $isAsync);
        break;
    case 'rebuild-stopped':
        $r = $indexObj->rebuild_stopped($index, $type, $isAsync);
        break;
    default:
        echo "illegal action.\n";
        exit;
 }
 
if($r === false) {
    echo "Index Update failure: {$indexObj->getErrorInfo()}";
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
            -l query id list,format: \"id1,id2,...\"
            -q query where condition
            -k sharding key, used for insert,modify
            -a update attrbutes(int/float/mva), format: \"name1=value1, name2=value2\"
optional:
            -j jobservers, default: 127.0.0.1:4730
            -r redis, default: 127.0.0.1:6379
            -u user
            -p password
            -s async, default:0.
            -h help\n";
}
?>
