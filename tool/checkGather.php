<?php

set_time_limit(0);
$gatherArr = array(
    'tslj' => 'shop[88-107] shopsold_a[1-13]',
    'ybq' => 'shop[66-87] bookstall_a[1-10] shop47 shop48 shop51 shop52',
    'zgkm' => 'shop[1-20] shop[61-65] bookstallsold_b[1-2] bookstallsold_a[1-2] shop57',
    'swk' => 'shop46 shop[49-50] shop[53-56] shop[58-60] shopsold_b[1-10] bookstall_b[1-8]',
    'dy' => 'shop[21-45]',
    'ts' => 'enditem[1-24]',
//    'ts' => 'shop46 shop[49-50] shop[53-56] shop[58-60] shopsold_b[1-10] bookstall_b[1-8]',
    'qf' => 'enditem[25-40]'
);

$sphinx_node = getenv('SPHINX_NODE');
$logHome = '/data/kongsearch_logs/';
if (!array_key_exists($sphinx_node, $gatherArr)) {
    echo "Not In The Gather Nodes !\r\n";
    exit;
}

$currentGatherStr = $gatherArr[$sphinx_node];
$tmpArr = explode(' ', $currentGatherStr);
$curGatherArr = array();
foreach ($tmpArr as $t) {
    $r = sscanf($t, "%[^[][%[^-]-%[^]]]", $n, $b, $e);
    if ($r == 3) {
        for ($i = $b; $i <= $e; $i++) {
            $curGatherArr[] = $n. $i;
        }
    } else {
        $curGatherArr[] = $t;
    }
}

$endFlag = true;
foreach($curGatherArr as $t) {
    echo "--------------------------------Current Log $t----------------------------------\r\n";
    $log = $logHome. $t. '.log';
    if(file_exists($log)) {
        $result = exec('tail -n 1 '. $log);
        if(strpos($result, 'totalTime') === false) {
            $endFlag = false;
        }
        var_dump($result);
    } else {
        echo "!!! Log File Not Exists !!!\r\n";
    }
}
$num = count($curGatherArr);
echo "All The Gather Tables $num\r\n";
if($endFlag) {
    echo "The Gather Work Is Done !\r\n";
} else {
    echo "The Gather Work Is Continue...\r\n";
}


?>