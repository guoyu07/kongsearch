<?php
    
    /*****************************************
     * author: xinde
     * 
     * 搜索集群监控脚本
     *****************************************/
    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    require_once 'monitor.php';

    set_time_limit(0);
    ini_set('memory_limit', -1);
    $cmdopts = getopt('z:h');
    
    $clustersArr = array(
        array(
            'name' => 'item_search',
            'host' => '192.168.2.19',
            'port' => '9800'
        ),
        array(
            'name' => 'item_search_spider',
            'host' => '192.168.1.68',
            'port' => '9700'
        ),
        array(
            'name' => 'endauction_suggest_searchlog',
            'host' => '192.168.1.239',
            'port' => '9600'
        ),
        array(
            'name' => 'message',
            'host' => '192.168.1.105',
            'port' => '9500'
        ),
        array(
            'name' => 'footprint',
            'host' => '192.168.2.200',
            'port' => '9400'
        )
    );
    
    $log_path = '/data/kongsearch_logs/monitor/';
    $log = $log_path. 'searchCluster_'. date('Y_m_d');
    $lastLog = $log_path. 'searchCluster_last'. date('Y_m_d');
    $noticeLog = $log_path. 'searchCluster_notice'. date('Y_m_d');
    
    if(!is_dir($log_path)) {
        mkdir($log_path, 0777, true);
    }
    
    $currentTime = date('Y-m-d H:i:s');
    file_put_contents($log, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
    $messageErr = '';
    
    //取搜索集群信息
    $nodesInfo_s_arr = array();
    $nodesInfo_a_arr = array();
    foreach($clustersArr as $clusterNum => $cluster) {
        $name = $cluster['name'];
        $host = $cluster['host'];
        $port = $cluster['port'];
        
        $searchServers = array(
            '0' => $host. ':'. $port
        );
        
        echo "*** Current Cluster Name : {$name}\n";
        file_put_contents($log, "*** Current Cluster Name : {$name}\n", FILE_APPEND);
        
        $server = ElasticSearchModel::getServer($searchServers);
        $nodesInfo_s_arr[$name] = ElasticSearchModel::getNodesInfo($server['host'], $server['port']);
        $nodesInfo_a_arr[$name] = ElasticSearchModel::getNodesInfo($server['host'], $server['port'], true);
        if(!$nodesInfo_s_arr[$name] || !$nodesInfo_a_arr[$name]) {
            $nodesInfo_s_arr[$name] = ElasticSearchModel::getNodesInfo($server['host'], $server['port']);
            $nodesInfo_a_arr[$name] = ElasticSearchModel::getNodesInfo($server['host'], $server['port'], true);
            if(!$nodesInfo_s_arr[$name] || !$nodesInfo_a_arr[$name]) {
                $messageErr = "Cluster Connect Error : Time:{$currentTime},Cluster Name:{$name},Host:{$host},Port:{$port}.";
                file_put_contents($log, $messageErr. "\n", FILE_APPEND);
                file_put_contents($noticeLog, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
                if (!$nodesInfo_s_arr[$name]) {
                    file_put_contents($noticeLog, '$nodesInfo_s_arr[$name] = ElasticSearchModel::getNodesInfo($server[\'host\'], $server[\'port\'])'. "\n", FILE_APPEND);
                } elseif (!$nodesInfo_a_arr[$name]) {
                    file_put_contents($noticeLog, '$nodesInfo_a_arr[$name] = ElasticSearchModel::getNodesInfo($server[\'host\'], $server[\'port\'], true)'. "\n", FILE_APPEND);
                }
                file_put_contents($noticeLog, $messageErr. "\n", FILE_APPEND);
                
                //!!!
                MonitorModel::sendMsg($messageErr);
                
                continue;
            }
        }
        file_put_contents($log, "****** Current Nodes Info : \n", FILE_APPEND);
        file_put_contents($log, "{$nodesInfo_s_arr[$name]}\n", FILE_APPEND);

        if(!file_exists($lastLog)) {
            if($clusterNum == count($clustersArr) - 1) {
                //存当前各信息
                file_put_contents($lastLog, "<?php \n\t\$lastNodesInfo_s_arr = ". var_export($nodesInfo_s_arr, true). ";\n\t\$lastNodesInfo_a_arr = ". var_export($nodesInfo_a_arr, true). ";\n?>");
                exit;
            } else {
                continue;
            }
        }

        //加载上一次执行结果保存文件
        if($clusterNum == 0) {
            require_once $lastLog;
            global $lastNodesInfo_s_arr;
            global $lastNodesInfo_a_arr;
        }

        //存当前各信息
        if($clusterNum == count($clustersArr) - 1) {
            file_put_contents($lastLog, "<?php \n\t\$lastNodesInfo_s_arr = ". var_export($nodesInfo_s_arr, true). ";\n\t\$lastNodesInfo_a_arr = ". var_export($nodesInfo_a_arr, true). ";\n?>");
        }

        //同上一次状态比对
        $noticeFlag = false;
        if(count($nodesInfo_a_arr[$name]) != count($lastNodesInfo_a_arr[$name])) {
            $messageErr = '';
            $lastNodes = array();
            $curNodes = array();
            foreach($lastNodesInfo_a_arr[$name] as $lastNode) {
                if($lastNode['name'] == 'name') {
                    continue;
                }
                $lastNodes[] = $lastNode['name'];
            }
            foreach($nodesInfo_a_arr[$name] as $node) {
                if($node['name'] == 'name') {
                    continue;
                }
                $curNodes[] = $node['name'];
            }
            $messageErr = "Cluster Notice : Time:{$currentTime},Cluster Name:{$name},Host:{$host},Port:{$port}.";
            $last_cur_diff_nodes = array_diff($lastNodes, $curNodes);
            $cur_last_diff_nodes = array_diff($curNodes, $lastNodes);
            if(!empty($last_cur_diff_nodes)) { //脱离
                $messageErr .= 'Nodes:';
                foreach($last_cur_diff_nodes as $nodeName) {
                    $messageErr .= $nodeName. ',';
                }
                $messageErr = trim($messageErr, ',');
                $messageErr .= '.[PROBLEM]';
            }
            if(!empty($cur_last_diff_nodes)) { //恢复
                $messageErr .= 'Nodes:';
                foreach($cur_last_diff_nodes as $nodeName) {
                    $messageErr .= $nodeName. ',';
                }
                $messageErr = trim($messageErr, ',');
                $messageErr .= '.[OK]';
            }
            
            $noticeFlag = true;
            //!!!
            MonitorModel::sendMsg($messageErr);
            
        }

        //记录问题信息
        if(!$noticeFlag) {
            continue;
        } else {
            file_put_contents($noticeLog, "\n\n\n\n\n---------------------------------------------------- {$currentTime} ----------------------------------------------------\n", FILE_APPEND);
            file_put_contents($noticeLog, "*** Current Cluster Name : {$name}\n", FILE_APPEND);
            file_put_contents($noticeLog, "\n********* Last Nodes Info : \n", FILE_APPEND);
            file_put_contents($noticeLog, "{$lastNodesInfo_s_arr[$name]}\n", FILE_APPEND);
            file_put_contents($noticeLog, "\n********* Current Nodes Info : \n", FILE_APPEND);
            file_put_contents($noticeLog, "{$nodesInfo_s_arr[$name]}\n", FILE_APPEND);
            file_put_contents($noticeLog, "\n********* Result : \n", FILE_APPEND);
            file_put_contents($noticeLog, "{$messageErr}\n", FILE_APPEND);
        }
        
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -h Help\n";
    }
?>