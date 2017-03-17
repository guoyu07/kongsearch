<?php

date_default_timezone_set('Asia/Chongqing');

// 支持继承
function parse_ini_file_extended($filename)
{
    $p_ini = parse_ini_file($filename, true);
    $config = array();
    foreach($p_ini as $namespace => $properties) {
        $info = explode(':', $namespace);
        if ($info === false || empty($info) || empty($info[0]))
            return false;
        if (empty($info[1])) {
            $name = $info[0];
            $extends = "";
        } else {
            list($name, $extends) = $info;
        }
        $name = trim($name);
        $extends = trim($extends);
        // create namespace if necessary
        if(!isset($config[$name])) $config[$name] = array();
        // inherit base namespace
        if(isset($p_ini[$extends])) {
            foreach($p_ini[$extends] as $prop => $val)
            $config[$name][$prop] = $val;
        }
        // overwrite / set current namespace values
        foreach($properties as $prop => $val)
            $config[$name][$prop] = $val;
    }
    return $config;
}

// 返回一个table数组： array('table', ...);
// $v: table[n-m] table0 table1
function parseTables($v) 
{
    $tables = array();
    $t = explode(' ', $v);    
    foreach ($t as $it) {
        $it = trim($it);
        if(empty($it) && $it !== '0' && $it !== 0) continue;
        $r = sscanf($it, "%[^[][%[^-]-%[^]]]", $n, $b, $e);
        if ($r == 3) {
            for ($i = $b; $i <= $e; $i++) {
                array_push($tables, $n . $i);
            }
        } else {
            array_push($tables, $it);
        }
    }

    return $tables;
}
      
function writeLog($msg, $logpath) 
{
    error_log(date('Y-m-d H:i:s') . " " . $msg . "\n", 3, $logpath);
}

function json_clean_decode($json, $assoc = false, $depth = 512, $options = 0) {
    // search and remove comments like /* */ and //
    $json = preg_replace("#(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|([\s\t]//.*)|(^//.*)#", '', $json);

    if(version_compare(phpversion(), '5.4.0', '>=')) {
        $json = json_decode($json, $assoc, $depth, $options);
    }
    elseif(version_compare(phpversion(), '5.3.0', '>=')) {
        $json = json_decode($json, $assoc, $depth);
    }
    else {
        $json = json_decode($json, $assoc);
    }

    return $json;
}

?>