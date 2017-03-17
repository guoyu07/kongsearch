<?php
    /*****************************************
     * author: xinde
     * 
     * 获取热搜词
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/pointKeys';
    if(!is_dir($path)) {
        mkdir($path, 0777, true);
    }
    
    $searchServers = array(
        '192.168.1.239:9600'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    
    $keysList = array(
        '晚清',
        '清朝',
        '民国',
        '期刊',
        '杂志'
    );
    foreach($keysList as $key) {
        $queryStr = '{
				"query":{"bool":{"must":[{"match":{"_keyword":{"query":"'. $key. '","type":"phrase"}}}]}},
				  "size": 0,
				  "aggs": {
					"group_by_keyword": {
					  "terms": {
						"field": "keyword",
						"order": {
						  "sum_count": "desc"
						},
						"size": 100
					  },
					  "aggs": {
						"sum_count": {
						  "sum": {
							"field": "count"
						  }
						}
					  }
					}
				  },
				  "sort":[{"count":{"order":"desc"}}]
				}';
        $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'searchlog', 'searchlog', $queryStr, 60, true);
        if(isset($result['aggregations']) && isset($result['aggregations']['group_by_keyword']) && isset($result['aggregations']['group_by_keyword']['buckets']) && !empty($result['aggregations']['group_by_keyword']['buckets'])) {
            $fhandle = fopen($path. '/'. $key. '.txt', 'w+');
            foreach($result['aggregations']['group_by_keyword']['buckets'] as $row) {
                $word = $row['key'];
                $num = intval($row['sum_count']['value']);
                fwrite($fhandle, $word. '     【'. $num. "】\n");
            }
            fclose($handle);
        }
    }
    
?>