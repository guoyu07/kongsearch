<?php

/**
 * author: liuxingzhi@2013.11
 */
ini_set('short_open_tag', '1');

/**
 * 在配置模板中可以使用的预定义模板变量：
 * $INDEX: 索引名
 * $SHARD: 索引shard
 * $PARENT:  继承的索引名
 * $SOURCES: 索引对应的sources
 * $TABLE: source对应的table
 * $LOCALS: 分布式索引中local indexs
 * $AGENTS: 分布式索引中agents
 * $INDEXDIR: 索引文件存放目录
 * $BASEDIR: sphinx安装目录
 * $LOGDIR: sphinx日志存放目录
 * $HOST: 节点监听的host
 * $APIPORT: 节点监听的sphinxAPI协议的端口
 * $QLPORT: 节点监听的sphinxQL协议的端口
 * $LOCALNUM: 分布式索引中dist_threads设置值。
 * $EOL: 上述变量用于配置行末尾时需要添加该变量。
 */
// 全局预定义模板变量
$HOST = '';
$APIPORT = '';
$QLPORT = '';
$BASEDIR = '';
$LOGDIR = '';
$LOCALNUM = 0;
$EOL = "\n";

function makeIndexConfig($inifile, $env, $envindex) {
    global $HOST, $APIPORT, $QLPORT, $BASEDIR, $LOGDIR, $LOCALNUM, $EOL;
    $distindexname = getDistIndexName($envindex);
    if (!empty($distindexname)) {
        $inifile = $distindexname . '_' . $inifile;
    }
    $curenv = getCurEnv();
    if ($curenv == 'local')
        $inifile = $distindexname . '_distindex_local.ini';
    else if ($curenv == 'neibu')
        $inifile = $distindexname . '_distindex_neibu.ini';
    $nodes = getDistNodes($inifile);
    $node = getCurNode($nodes, $env);
    $HOST = $node['listen']['host'];
    $APIPORT = $node['listen']['api'];
    $QLPORT = $node['listen']['ql'];
    $BASEDIR = $node['basedir'];
    $LOGDIR = $node['logdir'];
    $INDEXDIR = $node['indexdir'];
    $PARENT = '';

    $SQLHOST = $node['searchdb']['host'];
    $SQLPORT = $node['searchdb']['port'];
    $SQLUSER = $node['searchdb']['user'];
    $SQLPASS = $node['searchdb']['pass'];
    $SQLDB = $node['searchdb']['db'];

    foreach ($node['index'] as $INDEX => $indexcfg) {
        $PARENT = '';
        $shards = $indexcfg['shard'];
        $sourcenum = isset($indexcfg['source']) ? $indexcfg['source'] : 1;
        $table = isset($indexcfg['table']) ? $indexcfg['table'] : $INDEX;
        if (strpos($INDEX, 'rt') === false) {
            foreach ($shards as $SHARD) {
                if (strpos($SHARD, 'rt') === false && $SHARD !== 'dist' && $SHARD !== 'new' && strpos($SHARD, '_') === false) {
                    if (empty($PARENT))
                        $PARENT = $INDEX . '_' . $SHARD;
                    $SOURCES = '';
                    $shard = $SHARD;
                    for ($i = 0; $i < $sourcenum; $i++) {
                        $SHARD = $shard * $sourcenum + $i;
                        $TABLE = $table . '_' . $SHARD;
                        $SOURCES .= "source = {$INDEX}_{$SHARD}\n";
                        include $INDEX . '.src';
                    }

                    $SHARD = $shard;
                    if (!file_exists(dirname(__FILE__). '/'. $INDEX . '.idx')) {
                        include 'common.idx';
                    } else {
                        include $INDEX . '.idx';
                    }
                }
            }
        }

        foreach ($shards as $SHARD) {
            if (strpos($SHARD, 'rt') !== false) {
                include $INDEX . '.rt';
            } else if ($SHARD === 'new' || strpos($SHARD, '_') !== false) {
                $TABLE = $table . '_' . $SHARD;
                include $INDEX . '.src';
                $SOURCES = "source = {$INDEX}_{$SHARD}\n";
                if (!file_exists(dirname(__FILE__). '/'. $INDEX . '.idx')) {
                    include 'common.idx';
                } else {
                    include $INDEX . '.idx';
                }
            }
        }

        // dist索引需要配置在所有local index之后
        foreach ($shards as $SHARD) {
            if ($SHARD === 'dist') {
                $localnum = getDistLocalNum($node, $INDEX);
                if ($localnum > $LOCALNUM)
                    $LOCALNUM = $localnum;
                $LOCALS = getDistLocals($node, $INDEX);
                $AGENTS = getDistAgents($nodes, $node, $INDEX);
                if (!file_exists($INDEX . '.dist')) {
                    include "common.dist";
                } else {
                    include $INDEX . '.dist';
                }
            }
        }
    }

    //snippet index
    if (isset($node['snippet']) && !empty($node['snippet'])) {
        include "snippet.idx";
    }

    //distribute indexs
    if (isset($node['dist'])) {
        foreach ($node['dist'] as $distindex => $indexs) {
            $localnum = 0;
            $LOCALS = '';
            $AGENTS = '';
            $INDEX = $distindex;
            foreach ($indexs as $index) {
                $localnum += getDistLocalNum($node, $index);
                $LOCALS .= getDistLocals($node, $index);
                $AGENTS .= getDistAgents($nodes, $node, $index);
            }
            if ($localnum > $LOCALNUM)
                $LOCALNUM = $localnum;
            if (!file_exists($INDEX . '.dist')) {
                include "common.dist";
            } else {
                include $INDEX . '.dist';
            }
        }
    }
}

function getDistNodes($inifile) {
    $nodes = parse_ini_file($inifile, true);
    if ($nodes === false) {
        echo "can't parse ini file: $inifile\n";
        exit;
    }

    foreach ($nodes as $nodename => $node) {
        $node['name'] = $nodename;

        // listen
        $node['listen'] = explode(':', $node['listen']);
        if (count($node['listen']) != 3) {
            echo "node [{$nodename}] listen set error.\n";
            exit;
        }
        $node['listen']['host'] = $node['listen'][0];
        $node['listen']['api'] = $node['listen'][1];
        $node['listen']['ql'] = $node['listen'][2];

        // base dir
        if (!isset($node['basedir']) || empty($node['basedir'])) {
            echo "node [$nodename] base dir isn't set.\n";
            exit;
        }

        // log dir
        if (!isset($node['logdir']) || empty($node['logdir'])) {
            echo "node [$nodename] log dir isn't set.\n";
            exit;
        }

        if (!file_exists($node['logdir']) && !mkdir($node['logdir'], 0777, true)) {
            echo "log dir [{$node['logdir']}] make failure.\n";
            exit;
        }

        // index dir
        if (!isset($node['indexdir']) || empty($node['indexdir'])) {
            echo "node [$nodename] index dir isn't set.\n";
            exit;
        }

        if (!file_exists($node['indexdir']) && !mkdir($node['indexdir'], 0777, true)) {
            echo "index dir [{$node['indexdir']}] make failure.\n";
            exit;
        }

        // searchdb
        $node['searchdb'] = explode(':', $node['searchdb']);
        if (count($node['searchdb']) != 5) {
            echo "node [{$nodename}] searchdb set error.\n";
            exit;
        }
        $node['searchdb']['host'] = $node['searchdb'][0];
        $node['searchdb']['port'] = $node['searchdb'][1];
        $node['searchdb']['user'] = $node['searchdb'][2];
        $node['searchdb']['pass'] = $node['searchdb'][3];
        $node['searchdb']['db'] = $node['searchdb'][4];

        // snippet
        if (isset($node['snippet']) && !empty($node['snippet'])) {
            $snippet_xml = $node['indexdir'] . '/snippet.xml';
            touch($snippet_xml);
        }

        // index
        foreach ($node as $key => $value) {
            if (($indexname = strstr($key, '.index', true)) === false)
                continue;
            $node['index'][$indexname] = explode(',', $value);
            $shards = array();
            foreach ($node['index'][$indexname] as $shard) {
                $shard = trim($shard);
                if ($shard === '')
                    continue;
                if (($pos = strpos($shard, '-')) === false) {
                    array_push($shards, $shard);
                } else {
                    if(strpos($shard, '[') === false) {
                        $b = intval(trim(substr($shard, 0, $pos)));
                        $e = intval(trim(substr($shard, $pos + 1)));
                        for ($i = $b; $i <= $e; $i++)
                            array_push($shards, "$i");
                    } else {
                        $r = sscanf($shard, "%[^[][%[^-]-%[^]]]", $n, $b, $e); //daydelta_[12-23]
                        if ($r == 3) {
                            for ($i = $b; $i <= $e; $i++) {
                                array_push($shards, $n . $i);
                            }
                        } else {
                            array_push($shards, $shard);
                        }
                    }
                }
            }
            $node['index'][$indexname]['shard'] = $shards;

            // 创建索引目录
            $dir = $node['indexdir'] . '/' . $indexname;
            if (!file_exists($dir) && !mkdir($dir, 0777)) {
                echo "index dir [{$dir}] make failure.\n";
                exit;
            }

            // 索引的source的个数
            $srckey = $indexname . '.source';
            if (isset($node[$srckey]) && !empty($node[$srckey]))
                $node['index'][$indexname]['source'] = intval($node[$srckey]);

            // 索引source对应的table
            $tablekey = $indexname . '.table';
            if (isset($node[$tablekey]) && !empty($node[$tablekey]))
                $node['index'][$indexname]['table'] = $node[$tablekey];
        }

        // 分布式索引
        foreach ($node as $key => $value) {
            if (($distindex = strstr($key, '.dist', true)) === false)
                continue;
            $indexs = array();
            $vv = explode(',', $value);
            foreach ($vv as $v) {
                $t = trim($v);
                if ($t === '')
                    continue;
                if (!isset($node['index'][$t])) {
                    echo "index [{$t}] inexist for $key\n";
                    exit;
                }
                array_push($indexs, $t);
            }
            $node['dist'][$distindex] = $indexs;
        }

        $nodes[$nodename] = $node;
    }

    return $nodes;
}

function getCurNode($nodes, $env) {
    $name = getenv($env);
    if (empty($name)) {
        echo "environment variable [{$env}] isn't set.\n";
        exit;
    }

    if (!isset($nodes[$name])) {
        echo "environment variable [{$env}] set error.\n";
        exit;
    }

    return $nodes[$name];
}

function getDistIndexName($env) {
    $name = getenv($env);
    if (empty($name)) {
        return '';
    } else {
        return $name;
    }
}

function getCurEnv() {
    $env = getenv("SPHINX_ENV");
    if (empty($env)) {
        return '';
    } else {
        return $env;
    }
}

function getDistLocals($node, $index) {
    $locals = array();
    foreach ($node['index'][$index]['shard'] as $shard) {
        if ($shard !== 'dist') {
            $local = 'local = ' . $index . '_' . $shard;
            array_push($locals, $local);
        }
    }

    $r = implode("\n", $locals);
    $r = $r . "\n";
    return $r;
}

function getDistLocalNum($node, $index) {
    $n = 0;
    foreach ($node['index'][$index]['shard'] as $shard) {
        if ($shard !== 'dist') {
            $n++;
        }
    }

    return $n;
}

function getDistAgents($nodes, $curnode, $index) {
    $agents = array();
    foreach ($nodes as $nodename => $node) {
        if ($nodename == $curnode['name'])
            continue;
        foreach ($node['index'][$index]['shard'] as $shard) {
            if ($shard !== 'dist') {
                $agent = 'agent_persistent = ' . $node['listen']['host'] . ':' . $node['listen']['api'] . ':' . $index . '_' . $shard;
                array_push($agents, $agent);
            }
        }
    }

    $r = implode("\n", $agents);
    $r = $r . "\n";
    return $r;
}

?>
