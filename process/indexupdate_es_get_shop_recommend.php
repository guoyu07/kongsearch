<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_get_shop_recommend
{
    private $errorInfo;
    private $record;
    
    public function __construct($config) 
    {
        $this->errorInfo = '';
        $this->record = array();
        
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    public function customdeal($indexconfig, $msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $msg = $msg['data'];
        if(!isset($msg['userId']) || empty($msg['userId'])) {
            $this->errorInfo = "[ERROR]: userId isn't set.";
            return false;
        }
        $userId = $msg['userId'];
        
        $redisInfo = $indexconfig['redis'];
        if(!isset($redisInfo[0]) && !isset($redisInfo[1])) {
            $this->errorInfo = "Redis Set Error.";
            return false;
        }
        $redisObj = new Redis();
        if($redisObj->connect($redisInfo[0], $redisInfo[1]) === false && $redisObj->connect($redisInfo[0], $redisInfo[1]) === false) {
            $this->errorInfo = "redis connect error .";
            return false;
        }
        $itemListCacheKey = 'shopRecommend_'. $userId;
        $userExistsFlag   = 'get_shopRecommend_'. $userId;
        
        if($redisObj->llen($itemListCacheKey) >= 480) {
            return true;
        }
        $redisObj->delete($userExistsFlag);
        
        //一次用户取得
        $perUserNum = 240;

        $server = ElasticSearchModel::getServer($indexconfig['servers']);
        //取用户浏览最多的5个分类
        $queryStr = '
        {
            "size": 0,
            "aggs": {
                "group_by_catid": {
                    "filter": {
                        "bool": {
                            "must": [
                                {
                                    "term": {
                                        "viewerid": "'. $userId. '"
                                    }
                                }
                            ]
                        }
                    },
                    "aggs": {
                        "catid_return": {
                            "terms": {
                                "field": "catid"
                            }
                        }
                    }
                }
            }
        }
        ';
        $result = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $queryStr, 10, true);
        if(!isset($result['aggregations']) || !isset($result['aggregations']['group_by_catid']) || !isset($result['aggregations']['group_by_catid']['catid_return']) || !isset($result['aggregations']['group_by_catid']['catid_return']['buckets']) || empty($result['aggregations']['group_by_catid']['catid_return']['buckets'])) {
            return true;
        }
        $idStr = '';
        $i = 0;
        foreach($result['aggregations']['group_by_catid']['catid_return']['buckets'] as $row) {
            if($i >= 5) { //取5个分类
                break;
            }
            ++$i;
            $idStr .= '{"term":{"catid":"' . $row['key'] . '"}},';
        }
        $catItemSize = 100;
        //按分类取书$catItemSize~5*$catItemSize加入按权重随机取样中
        $idsQueryStr = '
        {
            "size": 0,
            "aggs": {
                "group_by_catid": {
                    "filter": {
                        "bool": {
                            "must": [
                                {"term": {"isdeleted": "0"}},
                                {
                                    "or": [
                                        '. trim($idStr, ','). '
                                    ]
                                },
                                {"range": {"count": {"from": 0,"include_lower": false}}}
                            ]
                        }
                    },
                    "aggs": {
                        "catid_return": {
                            "terms": {
                                "field": "catid",
                                "size": "5"
                            },
                            "aggs": {
                                "itemid_return": {
                                    "terms": {
                                        "field": "itemid",
                                        "size": '. $catItemSize. '
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        ';
        $idsResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'shop_recommend', 'item', $idsQueryStr, 10, true);
        if (!isset($idsResult['aggregations']) || !isset($idsResult['aggregations']['group_by_catid']) || !isset($idsResult['aggregations']['group_by_catid']['catid_return']) || !isset($idsResult['aggregations']['group_by_catid']['catid_return']['buckets']) || count($idsResult['aggregations']['group_by_catid']['catid_return']['buckets']) < 1) {
            return true;
        }
        //组合图书并分配权重
        $booksArr = array();
        $curWeight = 5;
        foreach($idsResult['aggregations']['group_by_catid']['catid_return']['buckets'] as $row) {
            if(!isset($row['itemid_return']) || !isset($row['itemid_return']['buckets']) || empty($row['itemid_return']['buckets'])) {
                continue;
            }
            foreach($row['itemid_return']['buckets'] as $r) {
                $itemid = $r['key'];
                $booksArr[$itemid] = $curWeight < 1 ? 1 : $curWeight; //itemid => weight
            }
            --$curWeight;
        }
        
        
        //添加足迹作者推荐因素
        $authorItemWeight = 10; //通过作者获取的图书权重
        $authorItemSize = 50;    //通过作者获取的最大图书数量加入按权重随机取样中
//        if($userId == '201253') {
        if($userId > 0) {  //控制是否添加作者推荐因素
            //取用户浏览最多的3个作者
            $queryAuthorStr = '
            {
                "size": "0",
                "facets": {
                    "author_facet": {
                        "terms": [
                            {
                                "field": "author2",
                                "size": "3"
                            }
                        ],
                        "global": false,
                        "facet_filter": {
                            "bool": {
                                "must": [
                                    {
                                        "term": {
                                            "isdeleted": "0"
                                        }
                                    },
                                    {
                                        "term": {
                                            "viewerid": "'. $userId. '"
                                        }
                                    },
                                    {
                                        "range": {
                                            "count": {
                                                "from": 0,
                                                "include_lower": false
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            ';
//            file_put_contents('/tmp/kfzsearch.log', $queryAuthorStr. "\n", FILE_APPEND);
            $authorResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'footprint_shop', 'footprint', $queryAuthorStr, 10, true);
            if(isset($authorResult['facets']) && isset($authorResult['facets']['author_facet']) && isset($authorResult['facets']['author_facet']['terms']) && !empty($authorResult['facets']['author_facet']['terms'])) {
                $authorStrTmp = '';
                foreach($authorResult['facets']['author_facet']['terms'] as $term) {
                    if($term['term'] == '其他') {
                        continue;
                    }
                    $authorStrTmp .= '{"match":{"author2":{"query":"'. $term['term']. '","type":"phrase"}}},';
                }
                if($authorStrTmp != '') {
                    $authorStr = trim($authorStrTmp, ',');
                    $getIdsByAuthorQuery = '
                    {
                        "_source": [
                            "itemid"
                        ],
                        "query": {
                            "bool": {
                                "must": [
                                    {
                                        "dis_max": {
                                            "queries": [
                                                '. $authorStr. '
                                            ]
                                        }
                                    }
                                ]
                            }
                        },
                        "filter": {
                            "bool": {
                                "must": [
                                    {
                                        "term": {
                                            "isdeleted": "0"
                                        }
                                    },
                                    {
                                        "range": {
                                            "count": {
                                                "from": 0,
                                                "include_lower": false
                                            }
                                        }
                                    }
                                ]
                            }
                        },
                        "size": "'. $authorItemSize. '"
                    }
                    ';
//                    file_put_contents('/tmp/kfzsearch.log', $getIdsByAuthorQuery. "\n", FILE_APPEND);
                    $tmp = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'shop_recommend', 'item', $getIdsByAuthorQuery, 10, true);
//                    file_put_contents('/tmp/kfzsearch.log', var_export($tmp, true). "\n", FILE_APPEND);
                    $getIdsByAuthorResult = ElasticSearchModel::trunslateFindResult($tmp);
//                    file_put_contents('/tmp/kfzsearch.log', var_export($getIdsByAuthorResult, true). "\n", FILE_APPEND);
                    if($getIdsByAuthorResult['total'] > 0) {
//                        file_put_contents('/tmp/kfzsearch.log', var_export($getIdsByAuthorResult['data'], true). "\n", FILE_APPEND);
                        foreach($getIdsByAuthorResult['data'] as $row) {
                            $itemid = $row['itemid'];
                            if(isset($booksArr[$itemid])) {
                                $booksArr[$itemid] += $authorItemWeight; //itemid => weight
                            } else {
                                $booksArr[$itemid] = $authorItemWeight; //itemid => weight
                            }
                        }
                    }
                }
            }
        } //end footprint author recommend
        
        
        //添加订单作者推荐因素
        $authorOrderItemWeight = 30; //通过作者获取的图书权重
        $authorOrderItemSize = 80;    //通过作者获取的最大图书数量加入按权重随机取样中
//        if($userId == '201253') {
        if($userId > 0) {  //控制是否添加作者推荐因素
            //取用户订单中最多的3个作者
            $queryAuthorStr = '
            {
                "size": "0",
                "facets": {
                    "author_facet": {
                        "terms": [
                            {
                                "field": "author2",
                                "size": "3"
                            }
                        ],
                        "global": false,
                        "facet_filter": {
                            "bool": {
                                "must": [
                                    {
                                        "term": {
                                            "isdeleted": "0"
                                        }
                                    },
                                    {
                                        "term": {
                                            "buyerid": "'. $userId. '"
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            ';
//            file_put_contents('/tmp/kfzsearch.log', $queryAuthorStr. "\n", FILE_APPEND);
            $authorResult = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'orders_shop_recommend', 'item', $queryAuthorStr, 10, true);
            if(isset($authorResult['facets']) && isset($authorResult['facets']['author_facet']) && isset($authorResult['facets']['author_facet']['terms']) && !empty($authorResult['facets']['author_facet']['terms'])) {
                $authorStrTmp = '';
                foreach($authorResult['facets']['author_facet']['terms'] as $term) {
                    if($term['term'] == '其他') {
                        continue;
                    }
                    $authorStrTmp .= '{"match":{"author2":{"query":"'. $term['term']. '","type":"phrase"}}},';
                }
                if($authorStrTmp != '') {
                    $authorStr = trim($authorStrTmp, ',');
                    $getIdsByAuthorQuery = '
                    {
                        "_source": [
                            "itemid"
                        ],
                        "query": {
                            "bool": {
                                "must": [
                                    {
                                        "dis_max": {
                                            "queries": [
                                                '. $authorStr. '
                                            ]
                                        }
                                    }
                                ]
                            }
                        },
                        "filter": {
                            "bool": {
                                "must": [
                                    {
                                        "term": {
                                            "isdeleted": "0"
                                        }
                                    }
                                ]
                            }
                        },
                        "size": "'. $authorOrderItemSize. '"
                    }
                    ';
//                    file_put_contents('/tmp/kfzsearch.log', $getIdsByAuthorQuery. "\n", FILE_APPEND);
                    $tmp = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'shop_recommend', 'item', $getIdsByAuthorQuery, 10, true);
//                    file_put_contents('/tmp/kfzsearch.log', var_export($tmp, true). "\n", FILE_APPEND);
                    $getIdsByAuthorResult = ElasticSearchModel::trunslateFindResult($tmp);
//                    file_put_contents('/tmp/kfzsearch.log', var_export($getIdsByAuthorResult, true). "\n", FILE_APPEND);
                    if($getIdsByAuthorResult['total'] > 0) {
//                        file_put_contents('/tmp/kfzsearch.log', var_export($getIdsByAuthorResult['data'], true). "\n", FILE_APPEND);
                        foreach($getIdsByAuthorResult['data'] as $row) {
                            $itemid = $row['itemid'];
                            if(isset($booksArr[$itemid])) {
                                $booksArr[$itemid] += $authorOrderItemWeight; //itemid => weight
                            } else {
                                $booksArr[$itemid] = $authorOrderItemWeight; //itemid => weight
                            }
                        }
                    }
                }
            }
        } //end order author recommend
        
        
        //将孔夫子新书广场中数据加入推荐
        $kfzItemWeight = 10; //孔夫子新书广场的图书权重
        $kfzItemSize = 100;    //孔夫子新书广场最大图书数量加入按权重随机取样中
//        if($userId == '201253') {
        if($userId > 0) {  //控制是否添加孔夫子新书广场因素
            //取100个商品数据
            $queryKfzStr = '
            {
                "_source": [
                    "itemid"
                ],
                "filter": {
                    "bool": {
                        "must": [
                            {
                                "term": {
                                    "shopid": "19661"
                                }
                            },
                            {
                                "term": {
                                    "isdeleted": "0"
                                }
                            },
                            {
                                "range": {
                                    "count": {
                                        "from": 0,
                                        "include_lower": false
                                    }
                                }
                            }
                        ]
                    }
                },
                "size": "'. $kfzItemSize. '"
            }
            ';
            $tmp = ElasticSearchModel::findDocumentByJson($server['host'], $server['port'], 'shop_recommend', 'item', $queryKfzStr, 10, true);
            $getIdsByKfzResult = ElasticSearchModel::trunslateFindResult($tmp);
            if ($getIdsByKfzResult['total'] > 0) {
                foreach ($getIdsByKfzResult['data'] as $row) {
                    $itemid = $row['itemid'];
                    if (isset($booksArr[$itemid])) {
                        $booksArr[$itemid] += $kfzItemWeight; //itemid => weight
                    } else {
                        $booksArr[$itemid] = $kfzItemWeight; //itemid => weight
                    }
                }
            }
        } //end kfz recommend
        
        
//        if($userId == '201253') {
//            file_put_contents('/tmp/kfzsearch.log', var_export($booksArr, true). "\n", FILE_APPEND);
//        }
        //按分类权重取出$perUserNum本图书，权重越高机会越大
        $getBookIds = array();
        for ($i = 0; $i < $perUserNum; $i++) {
            if (empty($booksArr)) {
                break;
            }
            $bookKeys = array_keys($booksArr);
            shuffle($bookKeys);
            $randKey = mt_rand(1, array_sum($booksArr));
            $radix = 0;
            foreach ($bookKeys as $id) {
                $radix += $booksArr[$id];
                if ($radix >= $randKey) {
                    unset($booksArr[$id]);
                    $getBookIds[] = $id;
                    break;
                }
            }
        }
//        if($userId == '201253') {
//            file_put_contents('/tmp/kfzsearch.log', var_export($getBookIds, true). "\n", FILE_APPEND);
//        }
        
        //将最后取得的图书压入用户堆栈
        foreach($getBookIds as $bookid) {
            $redisObj->lpush($itemListCacheKey, $bookid);
        }
        //用户缓存数据最多保存时间
        if($redisObj->ttl($itemListCacheKey) < 0) {
            $redisObj->expire($itemListCacheKey, 86400*2);
        }
        return true;
    }
    
}
