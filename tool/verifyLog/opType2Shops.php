<?php
    /*****************************************
     * author: xinde
     * 
     * 获取30天内人工审核最多的前200家店铺
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/verifyLog';
    if(!is_dir($path)) {
        mkdir($path, 0777, true);
    }
    $searchServers = array(
        '192.168.1.105:9900'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    
    $startTime = time() - 30 * 86400;
    $endTime = time();
    $queryStr = '{
	"size": 0,
	"aggs": {
		"group_by_inserttime": {
			"filter":{"bool":{"must":[{"term":{"optype":"1"}},{"range": {"optime": {"from": '. $startTime. ',"to":  '. $endTime. ',"include_lower": true,"include_upper": true}}}]}},
			"aggs": {
				"group_by_shopname": {
					"terms": {
						"field": "shopid",
						"order": {"sum_count": "desc"},
						"size": 200
					},
					"aggs": {
						"sum_count": {
							"sum": {
								"field": "optype"
							}
						}
					}
				}
			}
		}
	}
}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'booklog', 'verify', $queryStr, 120, true);
    
    if(isset($result['aggregations'])) {
        $fhandle = fopen($path. '/30人工审核店铺.txt', 'w+');
        foreach($result['aggregations']['group_by_inserttime']['group_by_shopname']['buckets'] as $row) {
            $shopId = $row['key'];
            $num = $row['doc_count'];
            $queryShopName = '{"query":{"bool":{"must":[{"term":{"shopid":"'. $shopId. '"}}]}},"size":"1"}';
            $shopNameResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'booklog', 'verify', $queryShopName, 120, true);
            if(isset($shopNameResult['hits']) && isset($shopNameResult['hits']['hits'])) {
                $shopName = $shopNameResult['hits']['hits'][0]['_source']['shopname'];
            }
            fwrite($fhandle, $shopId. "=>". $shopName. "      【". $num. "】\n");
        }
        fclose($handle);
    }
    
?>