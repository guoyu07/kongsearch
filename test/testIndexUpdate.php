<?php

/**
 * Created by diao.
 * Date: 16-9-19
 * Time: 下午2:36
 */
$host = '192.168.2.152';
$port = 6369;
$key = 'IndexUpdateES:auctioncom';
$value = '{"index":"auctioncom","type":"auctioncom","action":"update","user":"auctioncom","time":"2015-08-2500:00:00","data":{"speid":"367","viewednum":"1386","ishidden":"0","bigimg":"1\/1\/017.jpg","bargainprice":"0.00","endrefprice":"0.00","beginrefprice":"0.00","beginprice":"4000.00","decade":"清末民初写本","author":"李盛钟等撰并书","catid":"1","begintime":"20060604","itemname":"test","cusid":"17","userid":"107063","comname":"TEST","comid":"1","itemid":"1105","isdeleted":"0","begintime2":"20060604","comshortname":"test"}}
';

$redis = new Redis();
if ($redis->pconnect($host, $port) === false) {
    echo "redis connect error \n";
    exit;
}

echo $redis->rPush($key, $value);