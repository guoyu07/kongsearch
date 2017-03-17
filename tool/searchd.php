<?php
    /*****************************************
     * author: xinde
     * 
     * 监听搜索进程脚本（下班时启用）
     *****************************************/

    set_time_limit(0);
    ini_set('memory_limit', '1024M');
    $PHP_HOME = '/opt/app/php/';
    $SEARCH_HOME = '/data/project/kongsearch/';
    $sphinx_node = getenv('SPHINX_NODE');
    $searchDis = array(
        'tslj' => array(
            'product' => array(
                'ip' => '192.168.1.68',
                'port' => '9307'
            )
//            'orders' => array(
//                'ip' => '192.168.1.137',
//                'port' => '9307'
//            )
        ),
        'swk' => array(
            'product' => array(
                'ip' => '192.168.1.66',
                'port' => '9307'
            )
//            'orders' => array(
//                'ip' => '192.168.1.124',
//                'port' => '9307'
//            )
        ),
        'ybq' => array(
            'product' => array(
                'ip' => '192.168.1.239',
                'port' => '9307'
            ),
            'booklib' => array(
                'ip' => '192.168.1.239',
                'port' => '9320'
            )
        ),
        'zgkm' => array(
            'product' => array(
                'ip' => '192.168.1.83',
                'port' => '9307'
            )
        ),
        'dy' => array(
            'product' => array(
                'ip' => '192.168.1.115',
                'port' => '9307'
            )
        ),
        'nmw' => array(
            'seoproduct' => array(
                'ip' => '192.168.1.103',
                'port' => '9307'
            )
        ),
//        'ts' => array(
//            'booklib' => array(
//                'ip' => '192.168.1.132',
//                'port' => '9320'
//            )
//        ),
        'hr' => array( //内部测试
            'product' => array(
                'ip' => '192.168.1.91',
                'port' => '9307'
            ),
            'booklib' => array(
                'ip' => '192.168.1.91',
                'port' => '9320'
            )
        ),
        'ts' => array(
            'endauction' => array(
                'ip' => '192.168.1.132',
                'port' => '9309'
            )
        ),
        'qf' => array(
            'endauction' => array(
                'ip' => '192.168.1.105',
                'port' => '9309'
            )
        )
    );
    
    if(!array_key_exists($sphinx_node, $searchDis)) {
        echo "Current Node Is Not The Sphinx Node !!!\n";
        exit;
    }
    
    $curNodeInfo = $searchDis[$sphinx_node];
    while(true) {
        foreach($curNodeInfo as $key => $value) {
            $grepStr = $value['ip']. ':'. $value['port'];
            $checkCmd = "netstat -tlnp | grep searchd | grep ". $grepStr;
            $checkResult = shell_exec($checkCmd);
            if(!$checkResult) {
                $curTime = date('Y-m-d H:i:s');
                echo "\n\n----------------------------{$curTime}------------------------------\n";
                echo "-----------------". $sphinx_node. " Node ". $key. " ({$grepStr}) Is Down ! Now Trying Start The {$key} Search !!!-----------------\n";
                $startCmd = "sh ". $SEARCH_HOME. 'bin/searchd.sh start '. $key;
                $startResult = shell_exec($startCmd);
                echo $startResult. "\n";
                sleep(420);
                $checkResult2 = shell_exec($checkCmd);
                if(!$checkResult2) {
                    echo "-----Try To Start ". $sphinx_node. " Node ". $key. " ({$grepStr}) Failure !!! Now Try To Delete The binlog.meta-----\n";
                    $metaFile = '/data/logs/'. $key. '_search/binlog.meta';
                    if(file_exists($metaFile)) {
                        $rmCmd = "rm -rf ". $metaFile;
                        echo $rmCmd. "\n";
                        $rmResult = shell_exec($rmCmd);
                        if(!$rmResult) {
                            $startResult2 = shell_exec($startCmd);
                            echo $startResult2. "\n";
                            sleep(300);
                            $checkResult3 = shell_exec($checkCmd);
                            if($checkResult3) {
                                echo "---------------------Try To Start ". $sphinx_node. " Node ". $key. " ({$grepStr}) Success !!!---------------------\n";
                            } else {
                                echo "-----Try To Start ". $sphinx_node. " Node ". $key. " ({$grepStr}) Failure !!!-----\n";
                                //unset($curNodeInfo[$key]);
                            }
                        } else {
                            echo "------Delete The Meta File Failure !!!------\n";
                            //unset($curNodeInfo[$key]);
                        }
                    } else {
                        echo "------The Meta File Is Not Exists !!!------\n";
                        //unset($curNodeInfo[$key]);
                    }
                } else {
                    echo "---------------------Try To Start ". $sphinx_node. " Node ". $key. " ({$grepStr}) Success !!!---------------------\n";
                }
            }
            sleep(5);
        }
        sleep(90);
    }
?>