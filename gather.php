<?php

require_once 'lib/gather.class.php';
require_once 'lib/utils.php';

ini_set('memory_limit','-1');

$cmdopts = getopt('c:t:p:l:h');
if ($cmdopts === false || isset($cmdopts['h']) || !isset($cmdopts['c']) || empty($cmdopts['c'])) {
    echo "usage: $argv[0] -c configuration [-t data type] [-p primary tables] [-l log path] [-h help]\n";
    exit(1);
}

$inifile = '';
if(isset($cmdopts['c']) && !empty($cmdopts['c']))
    $inifile = $cmdopts['c'];

$datatype = '';
if(isset($cmdopts['t']) && !empty($cmdopts['t']))
    $datatype = $cmdopts['t'];

$tables = array();
if(isset($cmdopts['p']) && !empty($cmdopts['p']))
    $tables = parseTables($cmdopts['p']);

$logpath = '';
if(isset($cmdopts['l']) && !empty($cmdopts['l']))
    $logpath = $cmdopts['l'];

echo "Gather is starting for {$inifile}...\n";
runGather($inifile, $logpath, $datatype, $tables);
echo "Gather is done\n";

function runGather($inifile, $logpath='', $datatype='', $tables=array())
{
    $config = Gather::getConfig($inifile);
    if($config === false) return false;
    $gather = new Gather($config, $logpath);
    
    if($gather->init($datatype) === false) {
        echo $gather->getErrorInfo() . "\r\n";
        return false;
    }
    
    if($gather->getAllTables($tables) === false) {
        echo $gather->getErrorInfo() . "\r\n";
        return false;
    }
    
    $gather->free();
    return true;
}


?>

