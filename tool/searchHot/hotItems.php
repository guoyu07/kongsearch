<?php
    /*****************************************
     * author: xinde
     * 
     * 获取热门商品
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/hotItems';
    if(!is_dir($path)) {
        mkdir($path, 0777, true);
    }
    $searchServers = array(
        '192.168.2.200:9400'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    //书店 民国旧书 热门商品
    echo "书店-民国旧书...\r\n";
    $queryStr = '{
				"size": 0,
				"aggs": {
					"group_by_itemid": {
					  "filter":{"bool":{"must":[{"range":{"catid":{"from":"9000000000000000","to":"9022000000000000","include_lower": true,"include_upper": true}}}]}},
					  "aggs": {
						"itemid_return": {
						  "terms": {
							"field": "itemid",
							"size":"10000"
						  }
						}
					  }
					}
				},
				"sort":[{"count":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $queryStr, 60, true);
    if(isset($result['aggregations']) && isset($result['aggregations']['group_by_itemid']) && isset($result['aggregations']['group_by_itemid']['itemid_return']) && isset($result['aggregations']['group_by_itemid']['itemid_return']['buckets'])) {
        $fhandle = fopen($path. '/书店-民国旧书.txt', 'w+');
        foreach($result['aggregations']['group_by_itemid']['itemid_return']['buckets'] as $row) {
            $itemid = $row['key'];
            $num = $row['doc_count'];
            $getItemQuery = '{"query":{"bool":{"must":[{"term":{"itemid":"'. $itemid. '"}}]}},"size":"1"}';
            $itemResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $getItemQuery, 60, true);
            if(isset($itemResult['hits']) && isset($itemResult['hits']['hits']) && isset($itemResult['hits']['hits'][0]) && !empty($itemResult['hits']['hits'][0]) && isset($itemResult['hits']['hits'][0]['_source']) && isset($itemResult['hits']['hits'][0]['_source']['itemname'])) {
                fwrite($fhandle, $itemResult['hits']['hits'][0]['_source']['itemname']. "      【". $num. "】\n");
            }
        }
        fclose($handle);
    }
    
    //书店 解放前期刊 热门商品
    echo "书店-解放前期刊...\r\n";
    $queryStr = '{
				"size": 0,
				"aggs": {
					"group_by_itemid": {
					  "filter":{"bool":{"must":[{"range":{"catid":{"from":"10001000000000000","to":"10001015006000000","include_lower": true,"include_upper": true}}}]}},
					  "aggs": {
						"itemid_return": {
						  "terms": {
							"field": "itemid",
							"size":"10000"
						  }
						}
					  }
					}
				},
				"sort":[{"count":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $queryStr, 60, true);
    if(isset($result['aggregations']) && isset($result['aggregations']['group_by_itemid']) && isset($result['aggregations']['group_by_itemid']['itemid_return']) && isset($result['aggregations']['group_by_itemid']['itemid_return']['buckets'])) {
        $fhandle = fopen($path. '/书店-解放前期刊.txt', 'w+');
        foreach($result['aggregations']['group_by_itemid']['itemid_return']['buckets'] as $row) {
            $itemid = $row['key'];
            $num = $row['doc_count'];
            $getItemQuery = '{"query":{"bool":{"must":[{"term":{"itemid":"'. $itemid. '"}}]}},"size":"1"}';
            $itemResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $getItemQuery, 60, true);
            if(isset($itemResult['hits']) && isset($itemResult['hits']['hits']) && isset($itemResult['hits']['hits'][0]) && !empty($itemResult['hits']['hits'][0]) && isset($itemResult['hits']['hits'][0]['_source']) && isset($itemResult['hits']['hits'][0]['_source']['itemname'])) {
                fwrite($fhandle, $itemResult['hits']['hits'][0]['_source']['itemname']. "      【". $num. "】\n");
            }
        }
        fclose($handle);
    }
    
    //拍卖 民国旧书 热门商品
    echo "拍卖-民国旧书...\r\n";
    $queryStr = '{
				"size": 0,
				"aggs": {
					"group_by_itemid": {
					  "filter":{"bool":{"must":[{"range":{"catid":{"from":"9000000000000000","to":"9022000000000000","include_lower": true,"include_upper": true}}}]}},
					  "aggs": {
						"itemid_return": {
						  "terms": {
							"field": "itemid",
							"size":"10000"
						  }
						}
					  }
					}
				},
				"sort":[{"count":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_pm', 'footprint', $queryStr, 60, true);
    if(isset($result['aggregations']) && isset($result['aggregations']['group_by_itemid']) && isset($result['aggregations']['group_by_itemid']['itemid_return']) && isset($result['aggregations']['group_by_itemid']['itemid_return']['buckets'])) {
        $fhandle = fopen($path. '/拍卖-民国旧书.txt', 'w+');
        foreach($result['aggregations']['group_by_itemid']['itemid_return']['buckets'] as $row) {
            $itemid = $row['key'];
            $num = $row['doc_count'];
            $getItemQuery = '{"query":{"bool":{"must":[{"term":{"itemid":"'. $itemid. '"}}]}},"size":"1"}';
            $itemResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_pm', 'footprint', $getItemQuery, 60, true);
            if(isset($itemResult['hits']) && isset($itemResult['hits']['hits']) && isset($itemResult['hits']['hits'][0]) && !empty($itemResult['hits']['hits'][0]) && isset($itemResult['hits']['hits'][0]['_source']) && isset($itemResult['hits']['hits'][0]['_source']['itemname'])) {
                fwrite($fhandle, $itemResult['hits']['hits'][0]['_source']['itemname']. "      【". $num. "】\n");
            }
        }
        fclose($handle);
    }
    //拍卖 解放前期刊 热门商品
    echo "拍卖-解放前期刊...\r\n";
    $queryStr = '{
				"size": 0,
				"aggs": {
					"group_by_itemid": {
					  "filter":{"bool":{"must":[{"range":{"catid":{"from":"10001000000000000","to":"10001015006000000","include_lower": true,"include_upper": true}}}]}},
					  "aggs": {
						"itemid_return": {
						  "terms": {
							"field": "itemid",
							"size":"10000"
						  }
						}
					  }
					}
				},
				"sort":[{"count":{"order":"desc"}}]
				}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_pm', 'footprint', $queryStr, 60, true);
    if(isset($result['aggregations']) && isset($result['aggregations']['group_by_itemid']) && isset($result['aggregations']['group_by_itemid']['itemid_return']) && isset($result['aggregations']['group_by_itemid']['itemid_return']['buckets'])) {
        $fhandle = fopen($path. '/拍卖-解放前期刊.txt', 'w+');
        foreach($result['aggregations']['group_by_itemid']['itemid_return']['buckets'] as $row) {
            $itemid = $row['key'];
            $num = $row['doc_count'];
            $getItemQuery = '{"query":{"bool":{"must":[{"term":{"itemid":"'. $itemid. '"}}]}},"size":"1"}';
            $itemResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_pm', 'footprint', $getItemQuery, 60, true);
            if(isset($itemResult['hits']) && isset($itemResult['hits']['hits']) && isset($itemResult['hits']['hits'][0]) && !empty($itemResult['hits']['hits'][0]) && isset($itemResult['hits']['hits'][0]['_source']) && isset($itemResult['hits']['hits'][0]['_source']['itemname'])) {
                fwrite($fhandle, $itemResult['hits']['hits'][0]['_source']['itemname']. "      【". $num. "】\n");
            }
        }
        fclose($handle);
    }
?>