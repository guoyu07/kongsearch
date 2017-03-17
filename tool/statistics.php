<?php
    /*****************************************
     * author: xinde
     * 
     * 统计搜索调用
     *****************************************/

    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('d:h');
//    if(!$cmdopts || isset($cmdopts['d'])) {
//        usage($argv[0]);
//        exit;
//    }
    
    $redis_host = '192.168.1.137';
    $redis_port = '6379';
    $redisLink  = new Redis();
    if ($redisLink->connect($redis_host, $redis_port) === false) {
        echo "Count Not Connect Redis {$redis_host}:{$redis_port}\n";
        exit;
    }
    
    if(isset($cmdopts['d']) && intval($cmdopts['d']) > 0) {
        $dateStr = $cmdopts['d'];
    } else {
        $dateStr = date("Ymd");
    }
    $key = 'kfzsearch_'. $dateStr. '*';
    
    $resultAll = $redisLink->keys($key);
    if(!$resultAll) {
        echo "NULL";
        exit;
    }
    
    $totalNum = 0;
    $statisticsArr = array();
    $orderArr = array();
    foreach($resultAll as $key) {
        $num = $redisLink->get($key);
        $statistics = array();
        $statistics['key'] = $key;
        $statistics['num'] = $num;
        $statisticsArr[] = $statistics;
        $orderArr[] = $num;
        $totalNum += $num;
    }
    array_multisort($orderArr, SORT_DESC, $statisticsArr);
    
    foreach($statisticsArr as $value) {
        echo $value['key']. ' => '. $value['num']. "\n";
    }
    
    echo "Total => ". $totalNum. "\n";
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -d Date
                 -h Help\n";
    }
?>