<?php

require_once '/data/project/kongsearch/lib/deltaTool.class.php';
require_once '/data/project/kongsearch/lib/delta.class.php';
require_once '/data/project/kongsearch/lib/utils.php';

ini_set('memory_limit','-1');
set_time_limit(0);

$cmdopts = getopt('a:c:t:l:h');
if ($cmdopts === false || isset($cmdopts['h']) || !isset($cmdopts['c']) || empty($cmdopts['c'])) {
    echo "usage: $argv[0] -c configuration [-t data type] [-p primary tables] [-l log path] [-h help]\n";
    exit(1);
}

$inifile = '';
if(isset($cmdopts['c']) && !empty($cmdopts['c']))
    $inifile = $cmdopts['c'];

$action = '';
if(isset($cmdopts['a']) && !empty($cmdopts['a']))
    $action = $cmdopts['a'];

$datatype = '';
if(isset($cmdopts['t']) && !empty($cmdopts['t']))
    $datatype = $cmdopts['t'];

$logpath = '';
if(isset($cmdopts['l']) && !empty($cmdopts['l']))
    $logpath = $cmdopts['l'];

$tmp = explode(DIRECTORY_SEPARATOR, __FILE__);
$file = $tmp[count($tmp) - 1];
$processCount = `ps -ef|grep '$file'|grep -v grep|grep -v '/bin/bash'|wc -l`;
if ($processCount > 1) {
    exit;
}

function truncateMin($inifile, $datatype, $logpath)
{
    $nodes = deltaTool::getDistNodes($inifile);
    $curNode = deltaTool::getCurNode($nodes);
    $deltaToolObj = new deltaTool($curNode, $logpath);
    
    $key = $datatype. '_mindelta.index';
    $shards = $deltaToolObj->getTableIds($curNode, $key);
    $deltaToolObj->writeLog("Start Truncate {$datatype}_mindelta Tables !!!");
    if($deltaToolObj->truncateMinTables($datatype, $shards)) {
        $deltaToolObj->writeLog('Truncate All Tables Success !!!');
    } else {
        $deltaToolObj->writeLog($deltaToolObj->errorinfo);
    }
}

function updateIsBuildIndex($inifile, $logpath)
{
    $config = Delta::getConfig($inifile);
    $deltaToolObj = new deltaTool($config, $logpath);
    $deltaToolObj->writeLog("Start Update IsBuildIndex Feild !!!");
    if($deltaToolObj->updateIBI()) {
        $deltaToolObj->writeLog('Update IsBuildIndex Feild Success !!!');
    } else {
        $deltaToolObj->writeLog($deltaToolObj->errorinfo);
    }
}

switch($action) {
    case 'truncateMin':
        truncateMin($inifile, $datatype, $logpath);
        break;
    case 'updateIsBuildIndex':
        updateIsBuildIndex($inifile, $logpath);
        break;
    default:
        usage($argv[0]);
        break;
}

function usage($program)
{
    echo "usage: php $program options \n";
    echo "mandatory:
            -a action
            -c config file
            -t data type
            -l log
            -h help\n";
}


?>