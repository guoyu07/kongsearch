<?php

    /*****************************************
     * author: xinde
     * 
     * 论坛数据生成
     *****************************************/

    require_once '/data/project/kongsearch/lib/ElasticSearch.php';
    
    set_time_limit(0);
    ini_set('memory_limit', -1);
    
    $cmdopts = getopt('i:h');
    
    //获取帮助提示
    if(isset($cmdopts['h'])) {
        usage($argv[0]);
        exit;
    }
    
    //索引名
    $index = '';
    if(isset($cmdopts['i']) && trim($cmdopts['i'])) {
        $index = trim($cmdopts['i']);
    }
    if(!$index) {
        usage($argv[0]);
        exit;
    }
    
    //验证索引名是否合法
    if(!in_array($index, array('posts', 'tmsgs'))) {
        usage($argv[0]);
        exit;
    }
    
    $logPath = '/data/kongsearch_logs/forum';
    if(!is_dir($logPath)) {
        mkdir($logPath, 0777, true);
    }
    $logFile = $logPath. '/'. $index. '-'. date("Y-m-d-H-i-s"). ".log";
    
    $processCount = `ps -ef | grep 'forum_build.php' | grep -v grep | grep -v '/bin/sh' | grep -v vi | wc -l`;
    if ($processCount > 1) {
        noticeLog(date("Y-m-d H:i:s"). " 已经有正在运行的程序:forum_build.php !!!\n");
        exit;
    }
    
    noticeLog("----------------------------------------------- Start [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    $index_tmsgs_host = '192.168.1.105';
    $index_tmsgs_port = '9500';
    $index_tmsgs_name = 'forum_tmsgs';
    $index_tmsgs_type = 'tmsgs';
    
    $index_posts_host = '192.168.1.105';
    $index_posts_port = '9500';
    $index_posts_name = 'forum_posts';
    $index_posts_type = 'posts';
    
    $bbs_host = '192.168.2.102';
    $bbs_port = '3306';
    $bbs_user = 'bbs';
    $bbs_pswd = 'sunjincan_1102_kfz#';
    $bbs_db   = 'pw_bbs';
    
    $bbs_Link = mysql_pconnect($bbs_host.":".$bbs_port, $bbs_user, $bbs_pswd);
    mysql_select_db($bbs_db, $bbs_Link);
    mysql_query("SET NAMES 'utf8'", $bbs_Link);
    
    if ($index == 'tmsgs') { //主贴索引
        getTmsgs();
    } elseif ($index == 'posts') { //回贴索引
        getPosts();
    }
    
    noticeLog("----------------------------------------------- End [". date("Y-m-d H:i:s"). "] -----------------------------------------------\n");
    
    /**
     * 创建主贴索引
     */
    function getTmsgs()
    {
        global $index_tmsgs_host;
        global $index_tmsgs_port;
        global $index_tmsgs_name;
        global $index_tmsgs_type;
        global $bbs_Link;
        
        //取主贴辅表分表
        $tmsgs_tables = array();
        $get_tmsgs_table_sql = "SHOW TABLES LIKE 'pw_tmsgs%'";
        $get_tmsgs_table_query = mysql_query($get_tmsgs_table_sql, $bbs_Link);
        while($get_tmsgs_table_result = mysql_fetch_array($get_tmsgs_table_query)) {
            $tableTmp = $get_tmsgs_table_result[0];
            if(preg_match('/^pw_tmsgs\d*$/', $tableTmp)) {
                $tmsgs_tables[] = $tableTmp;
            }
        }
        
        //取主贴主表主键范围
        $threads_m_sql = "SELECT min(tid) as start,max(tid) as end FROM pw_threads";
        $threads_m_query = mysql_query($threads_m_sql, $bbs_Link);
        $threads_m_result = mysql_fetch_assoc($threads_m_query);
        $minId = $threads_m_result['start'];
        $maxId = $threads_m_result['end'];
        $once = 30000;
        $startId = 0;
        $endId = 0;
        while($startId < $maxId) {
            $startId = $startId == 0 ? $minId : $startId;
            $endId = ($startId + $once - 1) > $maxId ? $maxId : ($startId + $once - 1);
            //取主贴主表数据
            $threads_get_sql = "SELECT tid,fid,author,authorid,subject,postdate,ptable FROM pw_threads WHERE tid BETWEEN {$startId}  AND {$endId} AND ifshield=0 AND ifhide=0 AND fid>0 AND fid NOT IN (18,13)";
            $threads_get_query = mysql_query($threads_get_sql, $bbs_Link);
            $threadsResultTmp = array();
            $tmp = array();
            while($threads_get_result = mysql_fetch_assoc($threads_get_query)) {
                $tid = $threads_get_result['tid'];
                $tmp['tid'] = $tid;
                $tmp['fid'] = $threads_get_result['fid'];
                $tmp['author'] = $threads_get_result['author'];
                $tmp['authorid'] = $threads_get_result['authorid'];
                $tmp['subject'] = $threads_get_result['subject'];
                $tmp['postdate'] = $threads_get_result['postdate'];
                $threadsResultTmp[$tid] = array();
                $threadsResultTmp[$tid] = $tmp;
            }
            //取主贴辅表数据并合 并 主辅数据
            foreach($tmsgs_tables as $table) {
                $tmsgs_get_sql = "SELECT tid,alterinfo,content FROM {$table} WHERE tid BETWEEN {$startId} AND {$endId}";
                $tmsgs_get_query = mysql_query($tmsgs_get_sql, $bbs_Link);
                while($tmsgs_get_result = mysql_fetch_assoc($tmsgs_get_query)) {
                    $tid = $tmsgs_get_result['tid'];
                    if(isset($threadsResultTmp[$tid])) {
                        $threadsResultTmp[$tid]['content'] = $tmsgs_get_result['content'];
                    }
                }
            }
            //处理主贴数据 并 创建索引
            foreach($threadsResultTmp as $row) {
                $primaryId = $row['tid'];
                $doc = array();
                $doc['id'] = $primaryId;
                $doc['tid'] = $row['tid'];
                $doc['fid'] = $row['fid'];
                $doc['authorid'] = $row['authorid'];
                $doc['author'] = $row['author'];
                $doc['_author'] = $row['author'];
                $doc['subject'] = $row['subject'];
                $doc['_subject'] = $row['subject'];
                $doc['content'] = $row['content'];
                $doc['_content'] = $row['content'];
                $doc['postdate'] = $row['postdate'];
                $doc['isdeleted'] = 0;
//                echo '<pre>';
//                print_r($doc);
                ElasticSearchModel::indexDocument($index_tmsgs_host, $index_tmsgs_port, $index_tmsgs_name, $index_tmsgs_type, $doc, $primaryId);
            }
            
            noticeLog("Process pw_threads from {$startId} to {$endId}........................................[ OK ]  Add ". count($threadsResultTmp). "\n");
            $startId += $once;
        }
    }
    
    /**
     * 创建回贴索引
     */
    function getPosts()
    {
        global $index_posts_host;
        global $index_posts_port;
        global $index_posts_name;
        global $index_posts_type;
        global $bbs_Link;
        
        //取回贴表分表
        $posts_tables = array();
        $get_posts_table_sql = "SHOW TABLES LIKE 'pw_posts%'";
        $get_posts_table_query = mysql_query($get_posts_table_sql, $bbs_Link);
        while($get_posts_table_result = mysql_fetch_array($get_posts_table_query)) {
            $tableTmp = $get_posts_table_result[0];
            if(preg_match('/^pw_posts\d*$/', $tableTmp)) {
                $posts_tables[] = $tableTmp;
            }
        }
        
        //取回贴表主键范围
        $minId = 0;
        $maxId = 0;
        foreach($posts_tables as $table) {
            $posts_m_sql = "SELECT min(pid) as start,max(pid) as end FROM {$table}";
            $posts_m_query = mysql_query($posts_m_sql, $bbs_Link);
            $posts_m_result = mysql_fetch_assoc($posts_m_query);
            $minId = $posts_m_result['start'] < $minId ? $posts_m_result['start'] : $minId;
            $maxId = $posts_m_result['end'] > $maxId ? $posts_m_result['end'] : $maxId;
        }
        
        $once = 30000;
        $startId = 0;
        $endId = 0;
        while($startId < $maxId) {
            $startId = $startId == 0 ? $minId : $startId;
            $endId = ($startId + $once - 1) > $maxId ? $maxId : ($startId + $once - 1);
            $postsResultTmp = array();
            $threadsResultTmp = array();
            $tidTmp = array();
            //取回贴表数据
            foreach($posts_tables as $table) {
                $posts_get_sql = "SELECT pid,fid,tid,author,authorid,subject AS postSubject,postdate,alterinfo,content FROM {$table} WHERE fid>0 AND fid NOT IN (18,13) AND pid BETWEEN {$startId} AND {$endId}";
                $posts_get_query = mysql_query($posts_get_sql, $bbs_Link);
                $tmp = array();
                while($posts_get_result = mysql_fetch_assoc($posts_get_query)) {
                    $pid = $posts_get_result['pid'];
                    $tmp['pid'] = $pid;
                    $tmp['tid'] = $posts_get_result['tid'];
                    $tmp['fid'] = $posts_get_result['fid'];
                    $tmp['author'] = $posts_get_result['author'];
                    $tmp['authorid'] = $posts_get_result['authorid'];
                    $tmp['postSubject'] = $posts_get_result['postSubject'];
                    $tmp['postdate'] = $posts_get_result['postdate'];
                    $tmp['content'] = $posts_get_result['content'];
                    $postsResultTmp[$pid] = array();
                    $postsResultTmp[$pid] = $tmp;
                    if(!in_array($tmp['tid'], $tidTmp)) {
                        $tidTmp[] = $tmp['tid'];
                    }
                }
            }
            //取不重复主贴数据
            $tidStr = '';
            foreach($tidTmp as $tid) {
                $tidStr .= $tid . ",";
            }
            $tidStr = trim($tidStr, ",");
            $threads_get_sql = "SELECT tid,subject FROM pw_threads WHERE tid IN ({$tidStr}) AND ifshield=0 AND ifhide=0 AND fid>0";
            $threads_get_query = mysql_query($threads_get_sql);
            while($threads_get_result = mysql_fetch_assoc($threads_get_query)) {
                $tid = $threads_get_result['tid'];
                $threadsResultTmp[$tid] = $threads_get_result['subject'];
            }
            //合并主贴与回贴数据
            foreach($postsResultTmp as &$row) {
                $tid = $row['tid'];
                if(isset($threadsResultTmp[$tid])) {
                    $row['subject'] = $threadsResultTmp[$tid];
                }
            }
            //处理回贴数据 并 创建索引
            foreach($postsResultTmp as $row) {
                $primaryId = $row['tid']. '_'. $row['pid'];
                $doc = array();
                $doc['id'] = $primaryId;
                $doc['tid'] = $row['tid'];
                $doc['pid'] = $row['pid'];
                $doc['fid'] = $row['fid'];
                $doc['authorid'] = $row['authorid'];
                $doc['author'] = $row['author'];
                $doc['_author'] = $row['author'];
                $doc['subject'] = $row['subject'];
                $doc['_subject'] = $row['subject'];
                $doc['postsubject'] = $row['postSubject'];
                $doc['_postsubject'] = $row['postSubject'];
                $doc['content'] = $row['content'];
                $doc['_content'] = $row['content'];
                $doc['postdate'] = $row['postdate'];
                $doc['isdeleted'] = 0;
//                echo '<pre>';
//                print_r($doc);break;
                ElasticSearchModel::indexDocument($index_posts_host, $index_posts_port, $index_posts_name, $index_posts_type, $doc, $primaryId);
            }
            
            noticeLog("Process pw_posts from {$startId} to {$endId}........................................[ OK ]  Add ". count($postsResultTmp). "\n");
            $startId += $once;
        }
    }
    
    function noticeLog($msg)
    {
        global $logFile;
        echo $msg;
        file_put_contents($logFile, $msg, FILE_APPEND);
    }
    
    function usage($program)
    {
        echo "usage:php $program options \n";
        echo "mandatory:
                 -i Index Name For Build , tmsgs OR posts
                 -h Help\n";
    }
    
?>