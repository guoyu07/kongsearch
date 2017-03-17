<?php

$charset = ini_get('scws.default.charset');
if ($charset === false || $charset == 'utf-8')
    $charset = 'utf8';

$dictdir = ini_get('scws.default.fpath');
if ($dictdir === false)
    $dictdir = '/usr/local/etc';

$dict = $dictdir . "/kfz_dict.xdb";

if (($sh = scws_open()) === false) {
    die("scws open error.");
}

scws_set_charset($sh, $charset);
$r = scws_add_dict($sh, $dict, SCWS_XDICT_XDB);

if ($r === false) {
    scws_close($sh);
    die("scws add dict error.");
}

$word = $argv[1];
$mod  = isset($argv[2]) ? $argv[2] : 0;
if (!$word) {
    die("Usage: php " . $argv[0] . " 书叶丛话\r\n");
}

function segwordByMode($mode, $value)
{
    global $sh;
    scws_set_multi($sh, $mode);
    if (scws_send_text($sh, $value) === false) {
        return false;
    }

    $r = '';
    while ($words = scws_get_result($sh)) {
        foreach ($words as $word) {
            $r .= $word['word'];
            $r .= ' ';
        }
    }

    $r = rtrim($r);
    return $r;
}

// 参数$multi=0:  默认
// 参数$multi=1： 单字
// 参数$multi=2:  二元
// 参数$multi=3:  全部
function segword($value, $multi = 0)
{
    if (empty($value))
        return '';

    $r_none = segwordByMode(SCWS_MULTI_NONE, $value);   // 默认模式
    if ($r_none === false)
        return false;
    if ($multi == 0)
        return $r_none;
    $r_dual = segwordByMode(SCWS_MULTI_DUALITY, $value); // 二元模式
    if ($r_dual === false)
        return false;
    $r_zall = segwordByMode(SCWS_MULTI_ZALL, $value);   // 单字模式
    if ($r_zall === false)
        return false;
    
    if($multi == 1) {
        return $r_zall;
    }
    
    if($multi == 2) {
        return $r_dual;
    }

    $valuelen = mb_strlen($value, 'UTF-8');

    //从二元模式分词结果提取默认模式下没有的词
    if ($valuelen <= 16 && $r_dual == $r_none) { // 短的句子，两种模式切分结果可能相同。
        $r_nd = '';
    } else {
        $r_none_array = explode(' ', $r_none);
        $r_dual_array = explode(' ', $r_dual);
        $r_diff = array_diff($r_dual_array, $r_none_array);
        if (!empty($r_diff)) {
            $r_nd = implode(' ', $r_diff);
        } else {
            $r_nd = '';
        }
    }

    //从单字模式分词结果中提取所有的单字
    if ($valuelen <= 16 && $r_zall == $r_none) { // 短的句子，两种模式切分结果可能相同。
        $r_nz = '';
    } else {
        $r_zall_array = explode(' ', $r_zall);
        $r_nz = '';
        foreach ($r_zall_array as $word) {
            if (mb_strlen($word, 'UTF-8') == 1) {
                $r_nz .= $word;
                $r_nz .= ' ';
            }
        }
    }

    if($multi == 3) {
        return $r_none. ' '. $r_nd. ' '. $r_nz;
    } else {
        return $r_none;
    }
}

/*
function segword($value)
{
    global $sh;
    if (empty($value)) {
        return '';
    }
    $segWordsArrTmp = array();
    $segWordsArr = array();

    //默认模式
    if (scws_send_text($sh, $value) === false) {
        return false;
    }
    while ($words = scws_get_result($sh)) {
        foreach ($words as $word) {
            $segWordsArrTmp['default'][] = $word['word'];
            $segWordsArr[] = $word['word'];
        }
    }

    //单字模式
    $ulen = mb_strlen($value, 'UTF-8');
    $arr = array();
    $tmp = '';
    for ($i = 0; $i < $ulen; $i++) {
        $s = mb_substr($value, $i, 1, 'UTF-8');
        if (preg_match('/[0-9a-z]/is', $s)) {
            $tmp .= $s;
            continue;
        } else {
            if ($tmp) {
                $arr[] = $tmp;
                $tmp = '';
            }
            $arr[] = $s;
        }
    }
    if ($tmp) {
        $arr[] = $tmp;
    }
    if (array_diff($segWordsArrTmp['default'], $arr)) {
        foreach ($arr as $word) {
            $segWordsArrTmp['single'][] = $word;
            if (preg_match('/[0-9a-z]/is', $word) && in_array($word, $segWordsArr)) {
                continue;
            }
            $segWordsArr[] = $word;
        }
    }

    //二元模式
    scws_set_multi($sh, SCWS_MULTI_DUALITY);
    if (scws_send_text($sh, $value) === false) {
        return false;
    }
    while ($words = scws_get_result($sh)) {
        foreach ($words as $word) {
            $segWordsArrTmp['double'][] = $word['word'];
            if (in_array($word['word'], $segWordsArr)) {
                continue;
            }
            $segWordsArr[] = $word['word'];
        }
    }

//    echo '<pre>';
//    print_r($segWordsArrTmp);

    if (empty($segWordsArr)) {
        return '';
    }
    $r = implode(' ', $segWordsArr);
    return $r;
}
*/

var_dump(segword($word, $mod));
?>
