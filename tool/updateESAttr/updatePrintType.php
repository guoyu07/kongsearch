<?php
    /*****************************************
     * author: xinde
     * 
     * 商品数据更新脚本
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('h');
    
    $searchHost = '192.168.2.19';
    $searchPort = '9800';
    $searchIndex = 'item,item_sold';
    $searchType = 'product';
    $maxLoad    = '45.0';
    
    $allNum = getAllBooksNum();
    if($allNum == 0) {
        echo "Get Null.\n";
        exit;
    }
    $once = 1000;
    $times = ceil($allNum / $once);
    for($i = 0; $i < $times; $i++) {
        if($i == 0) {
            $id = 0;
        }
        echo "Times : {$times} , Once : {$once} , Current : {$i} , Deal Min Id : {$id}  ... \n";
        if(!checkLoad($searchHost, $searchPort, $maxLoad)) { //当前系统负载大于指定值时checkLoad返回false
            while(true) {
                sleep(60);
                $loadStatus = checkLoad($searchHost, $searchPort, $maxLoad);
                if($loadStatus) {
                    break;
                }
            }
        }
        $books = getBooks($id);
        if(!$books) {
            break;
        }
        foreach($books as $book) {
            $id = $book['_source']['itemid'];
            $printtype = $book['_source']['printtype'] ? $book['_source']['printtype'] : 0;
            $index = $book['_index'];
            if(!$id || !is_numeric($id) || !in_array($index, array('item_v1', 'item_sold_v1'))) {
                echo "id : {$id} , index : {$index} Is Wrong ! \n";
                exit;
            }
            echo "    index : ". str_pad($index, 12, ' '). " , id : {$id} , printtype : {$printtype} \n";
            $updateData = array('printtype' => $printtype);
            $updateResult = ElasticSearchModel::updateDocument($searchHost, $searchPort, $index, $searchType, $id, $updateData);
            if($updateResult && (isset($updateResult['_version']) || (isset($updateResult['status']) && $updateResult['status'] == '404'))) {
                if(isset($updateResult['status']) && $updateResult['status'] == '404') {
                    echo "    [Update] index : ". str_pad($index, 12, ' '). " , id : {$id} , printtype : {$printtype} Failure .\n";
                    continue;
                }
            } else {
                echo "[ERROR] : ". var_export($updateResult, true). "\n";
                continue;
            }
        }
        $getIdIndex = $once - 1;
        $id = $books[$getIdIndex]['_source']['itemid'];
    }
    
    
    /**
     * 检测系统负载
     * 
     * @param string $ip
     * @param int    $port
     * @param int    $maxLoad
     * @return boolean
     */
    function checkLoad($ip, $port, $maxLoad)
    {
        $loadInfo = ElasticSearchModel::getLoadInfo($ip, $port);
        $loadInfoArr = explode(' ', trim($loadInfo));
        if(is_array($loadInfoArr) && !empty($loadInfoArr)) {
            foreach($loadInfoArr as $info) {
                $load = trim($info);
                if($load > $maxLoad) {
                    return false;
                }
            }
        }
        return true;
    }
    
    /**
     * 获取所有图书总数
     */
    function getAllBooksNum()
    {
        global $searchHost;
        global $searchPort;
        global $searchIndex;
        global $searchType;
        $searchParams = array();
        $searchParams['filter']['must_in'][] = array('field' => 'catid1', 'value' => '8000000000000000,56000000000000000');
        $searchParams['fields'] = array('itemid');
        $searchParams['limit']['from'] = 0;
        $searchParams['limit']['size'] = 1;
        $result = ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, $searchParams['fields'], array(), $searchParams['filter'], array(), $searchParams['limit'], array(), array(), 120);
        if(isset($result['hits']) && isset($result['hits']['total'])) {
            return $result['hits']['total'];
        } else {
            return 0;
        }
    }
    
    /**
     * 获取指定范围图书
     */
    function getBooks($id = 0)
    {
        global $searchHost;
        global $searchPort;
        global $searchIndex;
        global $searchType;
        global $once;
        $searchParams = array();
        $searchParams['filter']['must_in'][] = array('field' => 'catid1', 'value' => '8000000000000000,56000000000000000');
        $searchParams['filter']['range_must'][] = array('field' => 'itemid', 'from' => $id, 'include_lower' => false);
        $searchParams['sort'] = array(array('field' => 'itemid', 'order' => 'asc'));
        $searchParams['fields'] = array('itemid','printtype');
        $searchParams['limit']['from'] = 0;
        $searchParams['limit']['size'] = $once;
        $result = ElasticSearchModel::findDocument($searchHost, $searchPort, $searchIndex, $searchType, 0, $searchParams['fields'], array(), $searchParams['filter'], $searchParams['sort'], $searchParams['limit'], array(), array(), 120);
        if(isset($result['hits']) && isset($result['hits']['hits'])) {
            return $result['hits']['hits'];
        } else {
            return array();
        }
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
    
?>