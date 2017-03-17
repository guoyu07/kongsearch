<?php

require_once 'unihan.php';

class Process
{

    private $errorInfo;
    private $dataType;
    private $convClass;
    private $convertor;
    private $proc;
    private $table;
    // 采用静态变量，防止索引更新时内存泄露
    private static $scws;

    private function autoload($className)
    {
        $classfile = dirname(__FILE__) . '/../process' . '/' . $className . '.php';
        if (file_exists($classfile)) {
            include_once $classfile;
        }
    }

    public function __construct($convClass, $dataType, $convArgs, $gatherMode, $proc)
    {
        if (spl_autoload_register(array($this, 'autoload')) === false) {
            $this->errorInfo = "spl_autoload_register error";
            throw new Exception($this->errorInfo);
        }

        $this->convClass = $convClass;
        $this->dataType = $dataType;
        $this->table = '';
        $this->proc = $proc;
        $this->convertor = NULL;
        if (class_exists($convClass)) {
            $this->convertor = new $convClass($dataType, $gatherMode, $convArgs);
        }

        // 分词初始化...
        if (!isset(self::$scws)) {
            $charset = ini_get('scws.default.charset');
            if ($charset === false || $charset == 'utf-8')
                $charset = 'utf8';

            $dictdir = ini_get('scws.default.fpath');
            if ($dictdir === false)
                $dictdir = '/usr/local/etc';

            $dict = $dictdir . "/kfz_dict.xdb";
            //$rule = $dictdir . "/kfz_rules.ini";

            if (($sh = scws_open()) === false) {
                $this->errorInfo = "scws open error.";
                throw new Exception($this->errorInfo);
            }

            scws_set_charset($sh, $charset);
            if ($gatherMode == 0) // rebuild mode
                $r = scws_add_dict($sh, $dict, SCWS_XDICT_MEM);
            else                 // update mode
                $r = scws_add_dict($sh, $dict, SCWS_XDICT_XDB);

            if ($r === false) {
                scws_close($sh);
                $this->errorInfo = "scws add dict error.";
                throw new Exception($this->errorInfo);
            }

            //scws_set_multi($sh, SCWS_MULTI_SHORT);
            self::$scws = $sh;
        }
    }

    public function __destruct()
    {
        $this->convertor = NULL;
    }

    public function getErrorInfo()
    {
        return $this->errorInfo;
    }

    public function convert($record, $table)
    {
        if ($this->convertor !== NULL) {
            $this->convertor->set($record, $table);
            foreach ($record as $fieldname => $fieldvalue) {
                if (method_exists($this->convClass, $fieldname)) {
                    $r = $this->convertor->$fieldname($fieldvalue);
                    if ($r === false) { //错误返回false
                        $reason = $this->convertor->getErrorInfo();
                        $this->errorInfo = "[{$this->convClass}][{$fieldname}] convert failure: {$reason}";
                        return false;
                    } else if (is_array($r) && empty($r)) { // 记录过滤掉返回空数组
                        $this->errorInfo = "Filter : [field] => $fieldname  ;  [value] => $fieldvalue";
                        return $r;
                    }
                    $record[$fieldname] = $r;
                }
            }
        }

        return $record;
    }

    public function exec($record, $table)
    {
        $this->table = $table;
        if ($this->proc !== NULL) {
            foreach ($this->proc as $fieldname => $funcs) {
                foreach ($funcs as $func) {
                    $fieldvalue = '';
                    if (isset($record[$fieldname]))
                        $fieldvalue = $record[$fieldname];
                    $funcname = $func[0];
                    if ($funcname == 'echo')
                        $funcname = '_echo';
                    $funcargs = array();
                    $funcargs[0] = $record;
                    $funcargs[1] = $fieldvalue;
                    $funcargs = array_merge($funcargs, $func[1]);
                    $r = call_user_func_array(array($this, $funcname), $funcargs);
                    if ($r === false) {                      // 错误返回false
                        $this->errorInfo = "[{$fieldname}][{$func[0]}] process failure.";
                        return false;
                    } else if (is_array($r) && empty($r)) {  // 记录过滤掉返回空数组
                        return $r;
                    }
                    $record[$fieldname] = $r;
                }
            }
        }

        return $record;
    }

    public function set($record, $value, $setvalue)
    {
        unset($record);
        $value = NULL;
        return $setvalue;
    }

    public function get($record, $value, $field)
    {
        $value = NULL;
        if (isset($record[$field]))
            return $record[$field];
        else
            return NULL;
    }

    public function _echo($record, $value)
    {
        unset($record);
        return $value;
    }

    // 把一个字符串转换为一个64位的十进制整数，注意只能在64位平台运行，32位平台返回科学计数法形式5.3615184559484E+18
    public function fnv64($record, $value)
    {
        unset($record);
        if (empty($value))
            return 0;
        $b128s = md5($value);
        $b64s = substr($b128s, 0, 14); // 用7个字节，因为sphinx不支持uint64 
        $b64 = hexdec($b64s);        // 把一个十六进制的64位整数转换为十进制的64位整数
        return $b64;
    }

    public function htmlencode($record, $value)
    {
        unset($record);
        if (empty($value))
            return $value;
        return htmlspecialchars($value);
    }

    public function htmlstrip($record, $value)
    {
        unset($record);
        if (empty($value))
            return $value;
        return strip_tags($value); // 会把任何<xxx>都过滤掉。
    }
    
    private function segwordByMode($mode, $value) {
        scws_set_multi(self::$scws, $mode);
        if(scws_send_text(self::$scws, $value) === false) {
            return false;
        }

        $r = '';
        while ($words = scws_get_result(self::$scws)) {
          foreach($words as $word) {
            $r .= $word['word'];
            $r .= ' ';
          }
        }

        $r = rtrim($r);
        return $r;
    }
    
    // 参数$multi=0:  采用默认切分模式，默认为0，比如：像itemDesc这种大字段则不需要进行多种切分。
    // 参数$multi=1： 需要进行多种切分，比如：tag shopname nickname。
    // 参数$multi=2:  需要进行多种切分，但只返回和默认模式切分结果中没有的内容。
    public function segword($record, $value, $multi=0) 
    {
        unset($record);
        if(empty($value)) return '';
        
        $r_none = $this->segwordByMode(SCWS_MULTI_NONE, $value);   // 默认模式
        if($r_none === false) return false;
        if ($multi == 0) return $r_none;
        $r_dual = $this->segwordByMode(SCWS_MULTI_DUALITY, $value);// 二元模式
        if($r_dual === false) return false;
        $r_zall = $this->segwordByMode(SCWS_MULTI_ZALL, $value);   // 单字模式
        if($r_zall === false) return false;
        
        $valuelen = mb_strlen($value,'UTF-8'); 
        
        //从二元模式分词结果提取默认模式下没有的词
        if($valuelen <= 16 && $r_dual == $r_none ) { // 短的句子，两种模式切分结果可能相同。
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
        if($valuelen <= 16 && $r_zall == $r_none ) { // 短的句子，两种模式切分结果可能相同。
          $r_nz = '';
        } else {
          $r_zall_array = explode(' ', $r_zall);
          $r_nz = '';
          foreach($r_zall_array as $word) {
            if(mb_strlen($word,'UTF-8') == 1) {
              $r_nz .= $word;
              $r_nz .= ' ';
            }      
          }
        }
        
        // 合并不同模式下的分词结果
        if($multi == 1) {
          $r = $r_none . ' ' . $r_nd . ' ' . $r_nz;
        } else if($multi == 2) {
          $r = $r_nd . ' ' . $r_nz;
        } else {
          $r = $r_none;
        }
        
        return $r;
    }

    /*public function segword($record, $value)
    {
        unset($record);
        if(empty($value)) return '';
        if(scws_send_text(self::$scws, $value) === false) {
            return false;
        }

        $r = '';
        while ($words = scws_get_result(self::$scws)) {
          foreach($words as $word) {
            $r .= $word['word'];
            $r .= ' ';
          }
        }
        $r = rtrim($r);
        return $r;
    }*/

    /*
    public function segword($record, $value)
    {
        unset($record);
        if (empty($value)) {
            return '';
        }
        $segWordsArrTmp = array();
        $segWordsArr = array();

        //默认模式
        scws_set_multi(self::$scws, SCWS_MULTI_NONE);
        if (scws_send_text(self::$scws, $value) === false) {
            return false;
        }
        while ($words = scws_get_result(self::$scws)) {
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
        scws_set_multi(self::$scws, SCWS_MULTI_DUALITY);
        if (scws_send_text(self::$scws, $value) === false) {
            return false;
        }
        while ($words = scws_get_result(self::$scws)) {
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

    // 此方法依赖于mbstring扩展。
    public function fan2jian($record, $value)
    {
        global $Unihan;

        unset($record);
        if ($value === '')
            return '';
        $r = '';
        $len = mb_strlen($value, 'UTF-8');
        for ($i = 0; $i < $len; $i++) {
            $c = mb_substr($value, $i, 1, 'UTF-8');
            if (isset($Unihan[$c]))
                $c = $Unihan[$c];
            $r .= $c;
        }

        return $r;
    }

}

?>
