<?php

require_once 'lib/searchclient.php';

$cmdopts = getopt('h:p:s:');
if ($cmdopts === false || !isset($cmdopts['s']) || empty($cmdopts['s'])) {
    echo "usage: $argv[0] [-h host] [-p port] -s \"sql\"\n";
    exit(1);
}

$host = 'localhost';
if(isset($cmdopts['h']) && !empty($cmdopts['h']))
    $host = $cmdopts['h'];

$port = 9306;
if(isset($cmdopts['p']) && !empty($cmdopts['p']))
    $port = intval($cmdopts['p']);

$stmt = $cmdopts['s'];

try {
    $search = new SearchClient($host . ':' . $port);
    $starttime = microtime(true);
    $result = $search->execute($stmt);
    $endtime = microtime(true);
    $elapse = sprintf("%01.2f", $endtime - $starttime);
    echo "elapse: $elapse\n";
    if($result === false)
        echo $search->getErrorInfo() . "\n";
    else
        print_r($result);
} catch (Exception $e) {
    echo $e->getMessage();
    exit;
}
?>
