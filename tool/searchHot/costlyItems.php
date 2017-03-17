<?php
    /*****************************************
     * author: xinde
     * 
     * 获取最贵商品
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/costlyItems';
    if(!is_dir($path)) {
        mkdir($path, 0777, true);
    }
    $searchServers = array(
        '192.168.2.19:9800'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    $endauctionServers = array(
        '192.168.1.239:9600'
    );
    $endauctionServer = ElasticSearchModel::getServer($endauctionServers);
    //书店 民国旧书 热门商品
    echo "书店-民国旧书...\r\n";
    $queryStr = '{
				"_source":["itemname","price"],
				"filter":{"bool":{"must":[{"range":{"catid":{"from":"9000000000000000","to":"9022000000000000","include_lower": true,"include_upper": true}}}]}},
				"size": 100,
				"sort":[{"price":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'item_sold', 'product', $queryStr, 60, true));
    
    if($result['total'] > 0) {
        $fhandle = fopen($path. '/书店最贵-民国旧书.txt', 'w+');
        foreach($result['data'] as $row) {
            $itemname = $row['itemname'];
            $price = $row['price'];
            fwrite($fhandle, $itemname. "      【". $price. "】\n");
        }
        fclose($handle);
    }
    
    //书店 解放前期刊 热门商品
    echo "书店-解放前期刊...\r\n";
    $queryStr = '{
				"_source":["itemname","price"],
				"filter":{"bool":{"must":[{"range":{"catid":{"from":"10001000000000000","to":"10001015006000000","include_lower": true,"include_upper": true}}}]}},
				"size": 100,
				"sort":[{"price":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'item_sold', 'product', $queryStr, 60, true));
    if($result['total'] > 0) {
        $fhandle = fopen($path. '/书店最贵-解放前期刊.txt', 'w+');
        foreach($result['data'] as $row) {
            $itemname = $row['itemname'];
            $price = $row['price'];
            fwrite($fhandle, $itemname. "      【". $price. "】\n");
        }
        fclose($handle);
    }
    
    //拍卖 民国旧书 热门商品
    echo "拍卖-民国旧书...\r\n";
    $queryStr = '{
				"_source":["itemname","maxprice"],
				"filter":{"bool":{"must":[{"range":{"catid":{"from":"9000000000000000","to":"9022000000000000","include_lower": true,"include_upper": true}}}]}},
				"size": 100,
				"sort":[{"maxprice":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($endauctionServer['host'], $endauctionServer['port'], 'endauction', 'endauction', $queryStr, 60, true));
    if($result['total'] > 0) {
        $fhandle = fopen($path. '/拍卖最贵-民国旧书.txt', 'w+');
        foreach($result['data'] as $row) {
            $itemname = $row['itemname'];
            $price = $row['maxprice'];
            fwrite($fhandle, $itemname. "      【". $price. "】\n");
        }
        fclose($handle);
    }
    
    //拍卖 解放前期刊 热门商品
    echo "拍卖-解放前期刊...\r\n";
    $queryStr = '{
				"_source":["itemname","maxprice"],
				"filter":{"bool":{"must":[{"range":{"catid":{"from":"10001000000000000","to":"10001015006000000","include_lower": true,"include_upper": true}}}]}},
				"size": 100,
				"sort":[{"maxprice":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocumentByJson($endauctionServer['host'], $endauctionServer['port'], 'endauction', 'endauction', $queryStr, 60, true));
    if($result['total'] > 0) {
        $fhandle = fopen($path. '/拍卖最贵-解放前期刊.txt', 'w+');
        foreach($result['data'] as $row) {
            $itemname = $row['itemname'];
            $price = $row['maxprice'];
            fwrite($fhandle, $itemname. "      【". $price. "】\n");
        }
        fclose($handle);
    }
?>