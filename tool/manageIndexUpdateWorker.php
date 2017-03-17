<?php
    /**************************************************************************************
     * author: xinde
     * 
     * 搜索集群索引更新脚本监控（放到chaijin执行，其它服务器需与chaijin做root互通）
     **************************************************************************************/

    set_time_limit(0);
    $cmdopts = getopt('a:i:h');
    if(isset($cmdopts['h'])) {
        usage($argv[0]);
        exit;
    }
    $action = isset($cmdopts['a']) ? $cmdopts['a'] : '';
    $server = isset($cmdopts['i']) ? $cmdopts['i'] : '';
    
    if ($action == 'stop' || $action == 'restart') {
        if(empty($server)) {
            usage($argv[0]);
            exit;
        }
    }

    $indexUpdateClusterInfo = array(
        'taishanglaojun' => array(
            'item' => array(
                'title' => '【用户】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
            ),
        ),
        'yuebuqun' => array(
            'item' => array(
                'title' => '【用户】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
            ),
            'member' => array(
                'title' => '会员搜索索引更新脚本',
                'number' => 5,
                'flag' => 'member',
            ),
        ),
        'zhugekongming' => array(
            'item' => array(
                'title' => '【用户】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
            ),
            'booklib' => array(
                'title' => '图书资料库搜索索引更新脚本',
                'number' => 3,
                'flag' => 'booklib',
            ),
            'auctioncom' => array(
                'title' => '拍卖公司联盟搜索索引更新脚本',
                'number' => 1,
                'flag' => 'auctioncom',
            ),
            'shufang' => array(
                'title' => '我的书房搜索索引更新脚本',
                'number' => 1,
                'flag' => 'shufang',
            )
        ),
        'duanyu' => array(
            'item' => array(
                'title' => '【用户】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
            ),
        ),
        'niumowang' => array(
            
        ),
        'tangseng' => array(

        ),
        'search-yangguo' => array(
            'item' => array(
                'title' => '【用户】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
            ),
            'searchlog' => array(
                'title' => '搜索关键词记录搜索索引更新脚本',
                'number' => 3,
                'flag' => 'searchlog',
            ),
        ),
        'qiaofeng' => array(
            'endauction' => array(
                'title' => '历史拍卖搜索索引更新脚本',
                'number' => 25,
                'flag' => 'endauction',
            ),
            'message' => array(
                'title' => '消息搜索索引更新脚本',
                'number' => 5,
                'flag' => 'message',
            ),
            'booklog' => array(
                'title' => '审核日志索引更新脚本',
                'number' => 5,
                'flag' => 'booklog',
            )
        ),
        'chaijin' => array(
            'item_spider' => array(
                'title' => '【爬虫】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
                'start' => 'sh /data/project/kongsearch/bin/indexupdateES.sh start_spider item',
                'stop' => 'sh /data/project/kongsearch/bin/indexupdateES.sh stop_spider item',
                'restart' => 'sh /data/project/kongsearch/bin/indexupdateES.sh restart_spider item'
            ),
        ),
        'daizong' => array(
            'item_spider' => array(
                'title' => '【爬虫】商品搜索索引更新脚本',
                'number' => 25,
                'flag' => 'item',
                'start' => 'sh /data/project/kongsearch/bin/indexupdateES.sh start_spider item',
                'stop' => 'sh /data/project/kongsearch/bin/indexupdateES.sh stop_spider item',
                'restart' => 'sh /data/project/kongsearch/bin/indexupdateES.sh restart_spider item'
            ),
        ),
        'zhangshun' => array(
            'footprint_searchword' => array(
                'title' => '【足迹】用户搜索关键词索引更新脚本',
                'number' => 10,
                'flag' => 'footprint_searchword',
            ),
        ),
        'liutang' => array(
            'footprint_pm' => array(
                'title' => '【足迹】用户拍品访问索引更新脚本',
                'number' => 10,
                'flag' => 'footprint_pm',
            ),
            'orders_shop_recommend' => array(
                'title' => '【足迹】订单购买记录索引更新脚本',
                'number' => 10,
                'flag' => 'orders_shop_recommend',
            ),
        ),
        'yanqing' => array(
            'footprint_shop' => array(
                'title' => '【足迹】用户商品访问索引更新脚本',
                'number' => 3,
                'flag' => 'footprint_shop',
            ),
            'shop_recommend' => array(
                'title' => '【足迹】商品推荐索引更新脚本',
                'number' => 15,
                'flag' => '\-i shop_recommend',
            ),
            'get_shop_recommend' => array(
                'title' => '【足迹】获取商品推荐索引更新脚本',
                'number' => 1,
                'flag' => 'get_shop_recommend',
            ),
        )
    );
    
    
    $currentTime = date('Y-m-d H:i:s');
    echo "---------------------------------------------------- {$currentTime} ----------------------------------------------------\n";
    
    $okFlag = true;
    
    foreach($indexUpdateClusterInfo as $nodeName => $nodeInfo) {
        echo "* Node [ {$nodeName} ] :\n";
        if(empty($nodeInfo)) {
            echo "\t\tHas No Index Update Worker.\n";
            continue;
        }

        foreach($nodeInfo as $serverName => $serverInfo) {
            $currentNum = intval(exec('ssh '. $nodeName. ' "ps -ef | grep indexupdate | grep \"'. $serverInfo['flag']. '\" | grep -v \"grep\" | grep -v \"bash\" |  wc -l"'));
            echo "\t\t Server Name : ". str_pad($serverName, 22). " , Title : ". str_pad($serverInfo['title'], 45). " , Should/Current Number : ". str_pad($serverInfo['number'], 2). " / {$currentNum}\n";
            if($currentNum != $serverInfo['number']) {
                $okFlag = false;
            }
        }
    }
    if($okFlag) {
        echo "---> All Right !\n";
    } else {
        echo "---> Has Wrong !\n";
    }
    
    if(!$action) {
        exit;
    }
    
    echo "\n\n***** Action : {$action} \n";
    if($action == 'start') { //检查所有业务worker数量与规定数量是否一致，不一致则重新启动
        if($okFlag) {
            echo "Action[Start] Is Done.\n";
            exit;
        }
        foreach($indexUpdateClusterInfo as $nodeName => $nodeInfo) {
            if(empty($nodeInfo)) {
                continue;
            }

            foreach($nodeInfo as $serverName => $serverInfo) {
                $currentNum = intval(exec('ssh '. $nodeName. ' "ps -ef | grep indexupdate | grep \"'. $serverInfo['flag']. '\" | grep -v \"grep\" | grep -v \"bash\" |  wc -l"'));
                $shouldNum = $serverInfo['number'];
                if($currentNum != $shouldNum) {
                    echo "* Node [ {$nodeName} ] :\n";
                    echo "\t\t Server Name : ". str_pad($serverName, 22). " , Title : ". str_pad($serverInfo['title'], 45). " , Should/Current Number : ". str_pad($serverInfo['number'], 2). " / {$currentNum}\n";
                    echo "\tNow Start...\n";
                    if(isset($serverInfo['start'])) {
                        exec('ssh '. $nodeName. ' "'. $serverInfo['start']. '"');
                    } else {
                        exec('ssh '. $nodeName. ' "sh /data/project/kongsearch/bin/indexupdateES.sh restart "'. $serverName);
                    }
                    echo "\tOk.\n";
                }
            }
        }
        echo "Action[Start] Is Done.\n";
    } elseif ($action == 'stop') { //停止某业务worker
        foreach($indexUpdateClusterInfo as $nodeName => $nodeInfo) {
            if(empty($nodeInfo)) {
                continue;
            }

            foreach($nodeInfo as $serverName => $serverInfo) {
                $currentNum = intval(exec('ssh '. $nodeName. ' "ps -ef | grep indexupdate | grep \"'. $serverInfo['flag']. '\" | grep -v \"grep\" | grep -v \"bash\" |  wc -l"'));
                $shouldNum = $serverInfo['number'];
                if($server == $serverName) {
                    echo "* Node [ {$nodeName} ] :\n";
                    echo "\t\t Server Name : ". str_pad($serverName, 22). " , Title : ". str_pad($serverInfo['title'], 45). " , Should/Current Number : ". str_pad($serverInfo['number'], 2). " / {$currentNum}\n";
                    echo "\tNow Stop...\n";
                    if(isset($serverInfo['stop'])) {
                        exec('ssh '. $nodeName. ' "'. $serverInfo['stop']. '"');
                    } else {
                        exec('ssh '. $nodeName. ' "sh /data/project/kongsearch/bin/indexupdateES.sh stop "'. $serverName);
                    }
                    echo "\tOk.\n";
                }
            }
        }
        echo "Action[Stop] Is Done.\n";
    } elseif ($action == 'restart') { //重启某业务worker
        foreach($indexUpdateClusterInfo as $nodeName => $nodeInfo) {
            if(empty($nodeInfo)) {
                continue;
            }

            foreach($nodeInfo as $serverName => $serverInfo) {
                $currentNum = intval(exec('ssh '. $nodeName. ' "ps -ef | grep indexupdate | grep \"'. $serverInfo['flag']. '\" | grep -v \"grep\" | grep -v \"bash\" |  wc -l"'));
                $shouldNum = $serverInfo['number'];
                if($server == $serverName) {
                    echo "* Node [ {$nodeName} ] :\n";
                    echo "\t\t Server Name : ". str_pad($serverName, 22). " , Title : ". str_pad($serverInfo['title'], 45). " , Should/Current Number : ". str_pad($serverInfo['number'], 2). " / {$currentNum}\n";
                    echo "\tNow Restart...\n";
                    if(isset($serverInfo['restart'])) {
                        exec('ssh '. $nodeName. ' "'. $serverInfo['restart']. '"');
                    } else {
                        exec('ssh '. $nodeName. ' "sh /data/project/kongsearch/bin/indexupdateES.sh restart "'. $serverName);
                    }
                    echo "\tOk.\n";
                }
            }
        }
        echo "Action[Restart] Is Done.\n";
    }

    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -a Action : start or stop or restart , non-required
                 -i Server Name , Use With -i \"item_spider\" , required with action stop or restart
                 -h Help\n";
    }
?>
