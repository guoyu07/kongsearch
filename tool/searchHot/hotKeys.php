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
    
    $searchServers = array(
        '192.168.1.239:9600'
    );
    $server = ElasticSearchModel::getServer($searchServers);
    $queryStr = '
    {
        "size": 0,
        "aggs": {
            "group_by_keyword": {
                "filter": {
                    "range": {
                        "inserttime": {
                            "from": "20151102",
                            "to": "20161102",
                            "include_lower": true,
                            "include_upper": true
                        }
                    }
                },
                "aggs": {
                    "group_by_keyword2": {
                        "terms": {
                            "field": "keyword",
                            "order": {
                                "sum_count": "desc"
                            },
                            "size": "1000"
                        },
                        "aggs": {
                            "sum_count": {
                                "sum": {
                                    "field": "count"
                                }
                            }
                        }
                    }
                }
            }
        },
        "sort": [
            {
                "count": {
                    "order": "desc"
                }
            }
        ]
    }';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'searchlog', 'searchlog', $queryStr, 60, true);
    if(isset($result['aggregations']) && isset($result['aggregations']['group_by_keyword']) && isset($result['aggregations']['group_by_keyword']['group_by_keyword2']) && isset($result['aggregations']['group_by_keyword']['group_by_keyword2']['buckets'])) {
        $fhandle = fopen('/data/kongsearch_logs/hotKeys.txt', 'w+');
        foreach($result['aggregations']['group_by_keyword']['group_by_keyword2']['buckets'] as $row) {
            $key = $row['key'];
            $num = intval($row['sum_count']['value']);
            fwrite($fhandle, $key. '     '. $num. "\n");
        }
        fclose($handle);
    }
?>