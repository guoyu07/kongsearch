<?php

set_time_limit(0);
date_default_timezone_set('Asia/Shanghai');

//数据库信息
$ip = '192.168.1.60';
$port = '3307';
$username = 'sphinx';
$passward = 'sphinx123321';
$dbname = 'searchword';

//创建数据库链接
function create_mysql_conn() {
    global $ip;
    global $port;
    global $username;
    global $passward;
    global $dbname;
    $link = mysql_connect($ip . ':' . $port, $username, $passward) or die("Count not connect $ip.\n");
    mysql_select_db($dbname, $link) or die("Count not use $dbname.\n");
    mysql_query("SET NAMES 'utf8'", $link);
    return $link;
}

$link = create_mysql_conn();
$node = getenv('SPHINX_NODE');
$baseDirArr = array('/data/logs/product_search/2014'); //目录结构必需为/xxx/xxx../年/月/filename
$startNum = '201405';

foreach ($baseDirArr as $baseDir) { //遍历年级目录
    $year = basename($baseDir);
    foreach (glob($baseDir . '/*') as $dir) { //遍历月级目录
        if (!is_dir($dir)) {
            continue;
        }
        $month = basename($dir);
        if (intval($year . $month) < intval($startNum)) { //小于起始记录日期则不在范围内
            echo "Is beyond the scope of record. \n";
            continue;
        }
        foreach (glob($dir . '/*') as $g_file) { //遍历日志文件
            $dirname = dirname($g_file);
            $g_basename = basename($g_file);
            $basename = strpos($g_basename, '.gz') !== false ? substr($g_basename, 0, strpos($g_basename, '.gz')) : $g_basename;
            $file = $dirname . '/' . $basename;

            if (!mysql_ping($link)) { //检查数据库链接是否有效
                mysql_close($link);
                $link = create_mysql_conn();
            }
            $file_sql = "SELECT * FROM searchlogrecord WHERE node='$node' AND filename='$file'";
            $file_query = mysql_query($file_sql);
            $file_reset = mysql_fetch_assoc($file_query);
            if (!$file_reset) {
                $file_insert_sql = "INSERT INTO searchlogrecord SET node='$node',filename='$file',linenum=0,dealstatus=0";
                mysql_query($file_insert_sql);
                $fileId = mysql_insert_id();
                $startLine = 0;
            } else {
                $fileId = $file_reset['id'];
                $startLine = $file_reset['linenum'];
                $dealstatus = $file_reset['dealstatus'];
                if ($dealstatus == 2) {
                    echo "The file[$basename] has been processed !!! \n";
                    continue;
                }
            }
            if (strpos($g_file, '.gz') !== false) {
                shell_exec('gzip -d ' . $g_file);
            }

            $linesInfo = shell_exec('wc -l ' . $file);
            $linesArr = explode(' ', $linesInfo);
            $lineNum = $linesArr[0];

            $fhandle = fopen($file, 'r');
            $countArr = array();
            $line = 0;
            $locateFlag = 1;
            echo "--------- Total Line Num : $lineNum . ---------\n";
            while ($result = fgets($fhandle)) {
                ++$line;
                if ($line < $startLine) {
                    if ($locateFlag) {
                        echo "The starting point is located... \n";
                        $locateFlag = 0;
                    }
                    if ($line % 10000 == 0) {
                        echo "$line ... \n";
                    }
                    continue;
                }

                if ($line % 1000 == 0) {
                    echo "--------- Current File : $basename . Total Line Num : $lineNum  .  Dealing Line Num : $line .  ---------\n";
                    $counter = 0;
                }
                // else {
                // 	echo "--------- Total Line Num : $lineNum  .  Dealing Line Num : $line .  ---------\n";
                // }
                if (!mysql_ping($link)) { //检查数据库链接是否有效
                    mysql_close($link);
                    $link = create_mysql_conn();
                }
                $file_update_sql = "UPDATE searchlogrecord SET linenum='$line',dealstatus=1 WHERE id='$fileId'";
                mysql_query($file_update_sql);

                preg_match_all('/\@\(_author\,_press\,_itemname\,isbn\,x_itemname\,x_author\,x_press\)(.*)?\'\) AND/isU', $result, $kArr);
                if (!empty($kArr[1])) {
                    $keyword = addslashes(trim(str_replace(' ', '', $kArr[1][0]))); //匹配关键字
                    // preg_match_all('/\/\* (\w+ \w+ \d+ \d+\:\d+)\:/isU', $result, $tArr); 
                    // var_dump($tArr);exit;
                    // $searchtime  = strtotime($tArr[1][0]); //匹配查询时间

                    $checkSql = "SELECT * FROM searchlog WHERE word='$keyword'";
                    $checkquery = mysql_query($checkSql);
                    $checkResult = mysql_fetch_assoc($checkquery);
                    if ($checkResult) { //有此记录则更新
                        $c_id = $checkResult['id'];
                        if (!$c_id) {
                            continue;
                        }
                        $updateSql = "UPDATE searchlog SET querynum=querynum+1 WHERE id='$c_id'";
                        mysql_query($updateSql);
                    } else { //无此记录则插入
                        $insertSql = "INSERT INTO searchlog SET word='$keyword'";
                        mysql_query($insertSql);
                    }
                    // $printTime = date("Y-m-d H:i", $searchtime);
                    // echo "Time => ". $printTime. "  Keyword => ". $keyword. "\n"; 
                    // exit;
                }
            }
            $file_update_sql = "UPDATE searchlogrecord SET dealstatus=2 WHERE id='$fileId'";
            mysql_query($file_update_sql);
            fclose($fhandle);

            shell_exec('gzip ' . $file);

            echo "Done.\n";
        }
    }
}
?>