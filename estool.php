<?php
require_once '/data/project/kongsearch/lib/ElasticSearch.php';

set_time_limit(0);
$cmdopts = getopt('i:o:t:x:y:h');
if (   $cmdopts === false || isset($cmdopts['h'])    || 
    !isset($cmdopts['i']) || empty($cmdopts['i']) ||
    !isset($cmdopts['o']) || empty($cmdopts['o']) ||
    !isset($cmdopts['x']) || empty($cmdopts['x']) ||
    !isset($cmdopts['y']) || empty($cmdopts['y'])){
    usage($argv[0]);
    exit;
}

$index = $cmdopts['i'];
$type = isset($cmdopts['t']) ? $cmdopts['t'] : '';
$action = $cmdopts['o'];
$ip = $cmdopts['x'];
$port = $cmdopts['y'];

if($action == 'optimize') {
    ElasticSearchModel::optimize($ip, $port, $index, 'o');
    ElasticSearchModel::optimize($ip, $port, $index, 'd');
    ElasticSearchModel::optimize($ip, $port, $index, 's');
} elseif ($action == 'refresh') {
    ElasticSearchModel::refresh($ip, $port, $index);
}
echo "estool success.\n";

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
            -x IP
            -y PORT
            -h help\n";
}
?>
