<?php
    /*****************************************
     * author: xinde
     * 
     * 获取最多商品
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $path = '/data/kongsearch_logs/TopItems';
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
    $queryStr = '{"filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"catid1":"9000000000000000"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}},"sort":[{"addtime":{"order":"desc"}}],"size":"0","from":"0","facets":{"itemname_facet":{"terms":[{"field":"itemname","size":"100"}],"global":false,"facet_filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"catid1":"9000000000000000"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}}}}}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'item,item_sold', 'product', $queryStr, 60, true);
    
    if(isset($result['facets']) && isset($result['facets']['itemname_facet']) && isset($result['facets']['itemname_facet']['terms']) && !empty($result['facets']['itemname_facet']['terms'])) {
        $fhandle = fopen($path. '/书店最多-民国旧书.txt', 'w+');
        foreach($result['facets']['itemname_facet']['terms'] as $row) {
            $itemname = $row['term'];
            $num = $row['count'];
            fwrite($fhandle, $itemname. "      【". $num. "】\n");
        }
        fclose($handle);
    }
    
    //书店 解放前期刊 热门商品
    echo "书店-解放前期刊...\r\n";
    $queryStr = '{"filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"catid2":"10001000000000000"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}},"sort":[{"addtime":{"order":"desc"}}],"size":"0","from":"0","facets":{"itemname_facet":{"terms":[{"field":"itemname","size":"100"}],"global":false,"facet_filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"shopstatus":"1"}},{"term":{"catid2":"10001000000000000"}},{"term":{"certifystatus":"1"}},{"term":{"salestatus":"0"}}]}}}}}';
    $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'item,item_sold', 'product', $queryStr, 60, true);
    if(isset($result['facets']) && isset($result['facets']['itemname_facet']) && isset($result['facets']['itemname_facet']['terms']) && !empty($result['facets']['itemname_facet']['terms'])) {
        $fhandle = fopen($path. '/书店最多-解放前期刊.txt', 'w+');
        foreach($result['facets']['itemname_facet']['terms'] as $row) {
            $itemname = $row['term'];
            $num = $row['count'];
            fwrite($fhandle, $itemname. "      【". $num. "】\n");
        }
        fclose($handle);
    }
    
    //拍卖 民国旧书 热门商品
    echo "拍卖-民国旧书...\r\n";
    $queryStr = '{"filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"catid1":"9000000000000000"}}]}},"sort":[{"addtime":{"order":"desc"}}],"size":"0","from":"0","facets":{"itemname_facet":{"terms":[{"field":"itemname","size":"100"}],"global":false,"facet_filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"catid1":"9000000000000000"}}]}}}}}';
    $result = ElasticSearchModel::findDocumentByJson($endauctionServer['host'], $endauctionServer['port'], 'endauction', 'endauction', $queryStr, 60, true);
    if(isset($result['facets']) && isset($result['facets']['itemname_facet']) && isset($result['facets']['itemname_facet']['terms']) && !empty($result['facets']['itemname_facet']['terms'])) {
        $fhandle = fopen($path. '/拍卖最多-民国旧书.txt', 'w+');
        foreach($result['facets']['itemname_facet']['terms'] as $row) {
            $itemname = $row['term'];
            $num = $row['count'];
            fwrite($fhandle, $itemname. "      【". $num. "】\n");
        }
        fclose($handle);
    }
    
    //拍卖 解放前期刊 热门商品
    echo "拍卖-解放前期刊...\r\n";
    $queryStr = '{"filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"catid2":"10001000000000000"}}]}},"sort":[{"addtime":{"order":"desc"}}],"size":"0","from":"0","facets":{"itemname_facet":{"terms":[{"field":"itemname","size":"100"}],"global":false,"facet_filter":{"bool":{"must":[{"term":{"isdeleted":"0"}},{"term":{"catid2":"10001000000000000"}}]}}}}}';
    $result = ElasticSearchModel::findDocumentByJson($endauctionServer['host'], $endauctionServer['port'], 'endauction', 'endauction', $queryStr, 60, true);
    if(isset($result['facets']) && isset($result['facets']['itemname_facet']) && isset($result['facets']['itemname_facet']['terms']) && !empty($result['facets']['itemname_facet']['terms'])) {
        $fhandle = fopen($path. '/拍卖最多-解放前期刊.txt', 'w+');
        foreach($result['facets']['itemname_facet']['terms'] as $row) {
            $itemname = $row['term'];
            $num = $row['count'];
            fwrite($fhandle, $itemname. "      【". $num. "】\n");
        }
        fclose($handle);
    }
    
?>