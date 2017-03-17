<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_endauction
{
    private $errorInfo;
    private $record;
    
    // 采用静态属性，索引更新时只需要初始化一次
    private static $pressBlist;
    private static $authorBlist;
    private static $vcatemap;
    
    public function __construct($config) 
    {
        $this->errorInfo = '';
        $this->record = array();
        $args = $config;
        
        // 加载出版社黑名单
        if(!isset(self::$pressBlist)) {
            self::$pressBlist = array();
            if(isset($args['blacklist.press']) && !empty($args['blacklist.press'])) {
                $blist = file($args['blacklist.press']);
                if($blist === false) {
                    $this->errorInfo = "load {$args['blacklist.press']} failure.";
                    throw new Exception($this->errorInfo);
                }

               foreach($blist as $key){
                   $key = trim($key);
                   self::$pressBlist[$key] = 1;
               }
            }
        }
        
        // 加载作者黑名单
        if(!isset(self::$authorBlist)) {
            self::$authorBlist = array();
            if(isset($args['blacklist.author']) && !empty($args['blacklist.author'])) {
                $blist = file($args['blacklist.author']);
                if($blist === false) {
                    $this->errorInfo = "load {$args['blacklist.author']} failure.";
                    throw new Exception($this->errorInfo);
                }

               foreach($blist as $key){
                   $key = trim($key);
                   self::$authorBlist[$key] = 1;
                }
            }
        }
        
        // 加载虚拟分类映射表
        if(!isset(self::$vcatemap)) {
            self::$vcatemap = array();
            if(isset($args['vcategory.map']) && !empty($args['vcategory.map'])) {
                $vcates = file($args['vcategory.map']);
                if($vcates === false) {
                    $this->errorInfo = "load {$args['vcategory.map']} failure.";
                    throw new Exception($this->errorInfo);
                }

                foreach($vcates as $vcate) {
                    $vcate = trim($vcate);
                    if(empty($vcate)) continue;
                    $pos = strpos($vcate,'=>');
                    if($pos === false) {
                         $this->errorInfo = "vcategory set error.";
                         throw new Exception($this->errorInfo);
                    }
                    $key = substr($vcate, 0, $pos);
                    $value = substr($vcate, $pos+2);
                    $key = trim($key);
                    $value = trim($value);
                    self::$vcatemap[$key] = $value;
                }
            }
        }
    }
    
    public function getErrorInfo() 
    {
        return $this->errorInfo;
    }
    
    // 此方法依赖于mbstring扩展。
    public function fan2jian($value)
    {
        global $Unihan;

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
    
    // 把一个字符串转换为一个64位的十进制整数，注意只能在64位平台运行，32位平台返回科学计数法形式5.3615184559484E+18
    public function fnv64($value)
    {
        if (empty($value))
            return 0;
        $b128s = md5($value);
        $b64s = substr($b128s, 0, 14); // 用7个字节，因为sphinx不支持uint64 
        $b64 = hexdec($b64s);        // 把一个十六进制的64位整数转换为十进制的64位整数
        return $b64;
    }
    
    private function getJsonErrorMsg() 
    {
        switch (json_last_error()) {
            case JSON_ERROR_NONE:
                $errmsg = 'No errors';
                break;
            case JSON_ERROR_DEPTH:
                $errmsg = 'Maximum stack depth exceeded';
                break;
            case JSON_ERROR_STATE_MISMATCH:
                $errmsg = 'Underflow or the modes mismatch';
                break;
            case JSON_ERROR_CTRL_CHAR:
                $errmsg = 'Unexpected control character found';
                break;
            case JSON_ERROR_SYNTAX:
                $errmsg = 'Syntax error, malformed JSON';
                break;
            case JSON_ERROR_UTF8:
                $errmsg = 'Malformed UTF-8 characters, possibly incorrectly encoded';
                break;
            default:
                $errmsg = 'Unknown error';
                break;
        }
        
        return $errmsg;
    }

    public function hasImg($value)
    {
        if(isset($this->record['img']) && !empty($this->record['img']))
            return 1;
        else
            return 0;
    }
    
    // 日期格式必须为: yyyy-mm-dd  yyyy-m-d
    private function date2int($value, $default=0)
    {
        $v = $default;
        if($value != '0000-00-00') {
            $ymd = explode('-', $value);
            foreach($ymd as $k => $v) {
                if($k == 0 && strlen($v) != 4)
                    return 0;
                if(($k == 1 || $k == 2) && strlen($v) == 1)
                    $ymd[$k] = '0'.$v;
            }
            
            if(count($ymd) == 1) {
                $v = intval($ymd[0].'0000');
            } else if(count($ymd) == 2) {
                $v = intval($ymd[0].$ymd[1].'00');
            } else if(count($ymd) == 3) {
                $v = intval($ymd[0].$ymd[1].$ymd[2]);
            }
        }
        
        return $v;
    }
    
    public function pubDate($value)
    {
        $v = $this->date2int($value, 0);
        if($v !== 0) { // 日期的年份进行判断
            $year = intval(substr("$v", 0, 4));
            $now = intval(date("Y"));
            if($year < 1000 || $year > $now)
                return 0;
        }
        return $v;
    }
    
    public function pubDate2($value)
    {
        if(!isset($this->record['pubDate']) || empty($this->record['pubDate']))
            return 29991231;
        else 
            $value = $this->record['pubDate'];
        
       $v = $this->date2int($value, 29991231);
       if($v !== 29991231) { // 日期的年份进行判断
           $year = intval(substr("$v", 0, 4));
           $now = intval(date("Y"));
           if($year < 1000 || $year > $now)
               return 29991231;
       }
       return $v;
    }
    
    public function years($value)
    {
        if(isset($this->record['years']))
            return $this->record['years'];
        else
            return $value;
    }
    
    public function years2($value)
    {
        if(!isset($this->record['years']) || empty($this->record['years']))
            return 0;
        else 
            $value = $this->record['years'];
        
        $years1 = array('建国后（1949-至今）'  => 10,
                        '民国 （1911-1949）'  => 11,
                        '清代 （1644-1911）'  => 12,
                        '明代 （1368-1644）'  => 13,
                        '宋元及以前'          => 14,
                        '不详'               => 15);
        $years9 = array('清代'               => 90,
                        '民国'               => 91,
                        '新中国早期'          => 92,
                        '文革'               => 93,
                        '70年代'             => 94,
                        '80年代'             => 95,
                        '90年代'             => 96,
                        '2000年之后'         => 97,
                        '不详'               => 98);
        $years10 = array('古代'              => 100,
                         '近现代'            => 101,
                         '现代'              => 102,
                         '不详'              => 103);
        $years11 = array('清朝'              => 110,
                         '民国'              => 111,
                         '新中国早期'         => 112,
                         '文革'              => 113,
                         '现代'              => 114,
                         '其它'              => 115);
        
        if(empty($value)) return 0;
        if(isset($this->record['catId']) && !empty($this->record['catId']))
            $catId = $this->record['catId'];
        else
            return 0;
        
        $tpl = $this->getTplByCatId($catId);
        switch($tpl) {
            case 1:case 3:case 4:case 5:case 8:case 12:
                if(isset($years1[$value])) return $years1[$value];
                if($value == '清' || $value == '清朝' || $value == '清代')
                    return 12;
                else if($value == '明' || $value == '明朝' || $value == '明代') 
                    return 13;
                else if($value == '民国' || $value == '中华民国')
                    return 11;
                else if($value == '新中国' || $value == '建国后' || $value == '中国') 
                    return 10;
       
                $year = intval(trim($value));
                if($year == 0) 
                    return 15;
                else if($year >= 1368 && $year < 1644) 
                    return 13;
                else if($year >= 1644 && $year < 1911)
                    return 12;
                else if($year >= 1911 && $year < 1949)
                    return 11;
                else if($year >= 1949)
                    return 10;
                else
                    return 15;
                break;
            case 9:
                if(isset($years9[$value])) return $years9[$value];
                if($value == '清' || $value == '清朝') return 90;
                $year = intval(trim($value));
                if($year == 0) 
                    return 98;
                else if($year >= 1644 && $year < 1911)
                    return 90;
                else if($year >= 1911 && $year < 1949)
                    return 91;
                else if($year >= 1949 && $year < 1966)
                    return 92;
                else if($year >= 1966 && $year <= 1976)
                    return 93;
                else if($year >= 1977 && $year < 1980)
                    return 94;
                else if($year >= 1980 && $year < 1990)
                    return 95;
                else if($year >= 1990 && $year < 2000)
                    return 96;
                else if($year >= 2000)
                    return 97;
                else
                    return 98;
                break;
            case 10:
                if(isset($years10[$value])) return $years10[$value];
                $year = intval(trim($value));
                if($year == 0)
                    return 103;
                else if($year > 221  && $year < 1911) 
                    return 100;
                else if($year >= 1911 && $year <= 1976)
                    return 101;
                else if($year >= 1977)
                    return 102;
                else
                    return 103;
                break;
            case 11:
                if(isset($years11[$value])) return $years11[$value];
                if($value == '清' || $value == '清代') return 110;
                $year = intval(trim($value));
                if($year == 0) 
                    return 115;
                else if($year >= 1644 && $year < 1911)
                    return 110;
                else if($year >= 1911 && $year < 1949)
                    return 111;
                else if($year >= 1949 && $year < 1966)
                    return 112;
                else if($year >= 1966 && $year <= 1976)
                    return 113;
                else if($year >= 1977)
                    return 114;
                else
                    return 115;
                break;
        }
        
        return 0;
    }
    
    private function trimTail($str,$tails)
    {
        $slen = strlen($str);
        foreach($tails as $tail) {
            $tlen = strlen($tail);
            if($tlen > $slen) continue;
            if(substr_compare($str, $tail, -$tlen, $tlen) == 0) {
                return substr($str, 0, $slen - $tlen);
            }
        }
        return $str;
    }
    
    private function trimHead($str,$heads)
    {
        $slen = strlen($str);
        foreach($heads as $head) {
            $hlen = strlen($head);
            if($hlen > $slen) continue;
            if(substr_compare($str, $head, 0, $hlen) == 0) {
                return substr($str, $hlen, $slen - $hlen);
            }
        }
        return $str;
    }
    
    public function author2($value)
    {
        if(!isset($this->record['author']) || empty($this->record['author']))
            return '';
        else 
            $value = $this->record['author'];
        
        $other = '其他';
        $value = trim($value);
        if(empty($value)) return '';
        $len = mb_strlen($value,'UTF-8'); 
        if($len == 1) return $other;
        if(!empty(self::$authorBlist) && isset(self::$authorBlist[$value]))
            return $other;
                
        $src = array(' ', '　','...', '*', '★',  ',', '//', ':', '・', '•', '(',  ')',  '[',  ']',  '【', '】',  '［', '］');
        $dst = array( '',   '',   '',  '',   '', '，', '，', '：', '·', '·', '（', '）', '（', '）',  '（',  '）', '（', '）');
        $head = array('：',':','！','!');
        $tail = array('/著','编著','编辑','主编','(作者)','(编者)','绘画','绘制','绘著','编绘','漫画','著','撰','编','绘','。','.','？？','？','??','?');
        
        //先去头去尾，再替换、过滤
        $value = $this->trimHead($value, $head);
        if(empty($value)) return $other;
        $value = $this->trimTail($value, $tail);
        if(empty($value)) return $other;
        $value = str_replace($src, $dst, $value);
        return $value;
    }
    
    public function press2($value)
    {
        if(!isset($this->record['press']) || empty($this->record['press']))
            return '';
        else 
            $value = $this->record['press'];
        
        $other = '其他';
        $value = trim($value);
        if(empty($value)) return '';
        $len = mb_strlen($value,'UTF-8'); 
        if($len == 1) return $other;
        if(!empty(self::$pressBlist) && isset(self::$pressBlist[$value])) 
            return $other;
               
        $src = array(' ', '　', '*',  '&#8226;', ',', '、',  ';', '；', '?', '？', '．', '・', '•', '北京市：');
        $dst = array( '',   '',  '',        '·', '，', '，', '，', '，', '，', '，', '.',  '·', '·', '北京市');
        $head = array('！','!','：',':','。','.','＋','+','★','br>出版社:','br>','北京 : ','北京:','北京：','上海 : ','上海市：','上海:','上海：','出版社：');
        $tail = array('本社特价书','本社特','【16开 彩色图文并茂】',
                      '(15元包邮挂)','(20元包邮挂)','（15元包邮挂）','（20元包邮挂）','（25元包邮挂）','（30元包邮挂）',
                      '语言：国语字幕：中文','语言：国语字幕：中英双语','语言：国语字幕：中','语言：国语字幕','语言：国语',
                      '/V-8','&','& nbsp','&nbsp','2009-2','1','2','3','4','5','6','7','8','9','0',
                      '.','。',',','，','??','？？','?','？',';','；');
        
        //先去头去尾，再替换、过滤
        $value = $this->trimHead($value, $head);
        if(empty($value)) return $other;
        $value = $this->trimTail($value, $tail);
        if(empty($value)) return $other;
        $value = str_replace($src, $dst, $value);
        return $value;
    }
            
    // 17,001,001,000
    public function area($value)
    {
        if(empty($value) || strlen($value) <= 9)
            return $value;
        
        $len = strlen($value) - 9;
        $area1 = substr($value, 0, $len);
        $area1 .= '000000000';
        $this->record['area1'] = $area1;
        
        $area2 = substr($value, 0, $len+3);
        $area2 .= '000000';
        $this->record['area2'] = $area2;
        return $value;
    }
    
    public function area1($value)
    {
        if(isset($this->record['area1']))
            return $this->record['area1'];
        else
            return $value;
    }
    
    public function area2($value)
    {
        if(isset($this->record['area2']))
            return $this->record['area2'];
        else
            return $value;
    }
    
    // 第四级分类 58,011,005,003,000,000  象棋
    public function catId($value)
    {
        if(empty($value) || strlen($value) <= 15)
            return $value;
  
        $len = strlen($value) - 15;
        $catId = substr($value, 0, $len);
        $catId .= '000000000000000';
        $this->record['catId1'] = $catId;
        
        $cat = substr($value, $len, 3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+3);
            $catId .= '000000000000';
            $this->record['catId2'] = $catId;
        }
        
        $cat = substr($value,$len+3,3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+6);
            $catId .= '000000000';
            $this->record['catId3'] = $catId;
        }
        
        $cat = substr($value,$len+6,3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+9);
            $catId .= '000000';
            $this->record['catId4'] = $catId;
        }
        
        return $value;
    }
    
    public function catId1($value)
    {
        if(isset($this->record['catId1']))
            return $this->record['catId1'];
        else
            return $value;
    }
    
    public function catId2($value)
    {
        if(isset($this->record['catId2']))
            return $this->record['catId2'];
        else
            return $value;
    }
    
    public function catId3($value)
    {
        if(isset($this->record['catId3']))
            return $this->record['catId3'];
        else
            return $value;
    }
    
    public function catId4($value)
    {
        if(isset($this->record['catId4']))
            return $this->record['catId4'];
        else
            return $value;
    }
    
    public function _catId($value)
    {
        if(isset($this->record['catId']))
            return $this->record['catId'];
        else
            return $value;
    }
    
    public function _catId1($value)
    {
        if(isset($this->record['catId1']))
            return $this->record['catId1'];
        else
            return $value;
    }
    
    public function _catId2($value)
    {
        if(isset($this->record['catId2']))
            return $this->record['catId2'];
        else
            return $value;
    }
    
    public function _catId3($value)
    {
        if(isset($this->record['catId3']))
            return $this->record['catId3'];
        else
            return $value;
    }
    
    public function _catId4($value)
    {
        if(isset($this->record['catId4']))
            return $this->record['catId4'];
        else
            return $value;
    }
    
    public function vcatId($value)
    {        
        if(isset($this->record['catId']))
            $value = $this->record['catId'];
        else
            return '';
        
        if(!empty(self::$vcatemap) && isset(self::$vcatemap[$value]))
            $vcatId = self::$vcatemap[$value];
        else
            return '';
        
        $value = $vcatId;
        if(empty($value) || strlen($value) <= 15)
            return '';
  
        $len = strlen($value) - 15;
        $catId = substr($value, 0, $len);
        $catId .= '000000000000000';
        $this->record['vcatId1'] = $catId;
        
        $cat = substr($value, $len, 3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+3);
            $catId .= '000000000000';
            $this->record['vcatId2'] = $catId;
        }
        
        $cat = substr($value,$len+3,3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+6);
            $catId .= '000000000';
            $this->record['vcatId3'] = $catId;
        }
        
        $cat = substr($value,$len+6,3);
        if($cat != '000') {
            $catId = substr($value, 0, $len+9);
            $catId .= '000000';
            $this->record['vcatId4'] = $catId;
        }
        
        $this->record['vcatId'] = $vcatId;
        return $vcatId;
    }
    
    public function vcatId1($value)
    {
        if(isset($this->record['vcatId1']))
            return $this->record['vcatId1'];
        else
            return $value;
    }
    
    public function vcatId2($value)
    {
        if(isset($this->record['vcatId2']))
            return $this->record['vcatId2'];
        else
            return $value;
    }
    
    public function vcatId3($value)
    {
        if(isset($this->record['vcatId3']))
            return $this->record['vcatId3'];
        else
            return $value;
    }
    
    public function vcatId4($value)
    {
        if(isset($this->record['vcatId4']))
            return $this->record['vcatId4'];
        else
            return $value;
    }
    
    public function _vcatId($value)
    {
        if(isset($this->record['vcatId']))
            return $this->record['vcatId'];
        else
            return $value;
    }
    
    public function _vcatId1($value)
    {
        if(isset($this->record['vcatId1']))
            return $this->record['vcatId1'];
        else
            return $value;
    }
    
    public function _vcatId2($value)
    {
        if(isset($this->record['vcatId2']))
            return $this->record['vcatId2'];
        else
            return $value;
    }
    
    public function _vcatId3($value)
    {
        if(isset($this->record['vcatId3']))
            return $this->record['vcatId3'];
        else
            return $value;
    }
    
    public function _vcatId4($value)
    {
        if(isset($this->record['vcatId4']))
            return $this->record['vcatId4'];
        else
            return $value;
    }
    
    // 用于第一级分类的聚类
    public function catId1g($value)
    {
        $c = '(';
        $c .= $this->record['catId1'];
        if(isset($this->record['vcatId1']) && !empty($this->record['vcatId1'])) {
            $c .= ',';
            $c .= $this->record['vcatId1'];
        }
        $c .= ')';
        return $c;
    }
    
    private function getTplByCatId($catId)
    {
        $tpl13 = array(
            '43000000000000000','1000000000000000','3000000000000000','23000000000000000','5000000000000000', '24000000000000000',
            '14000000000000000','25000000000000000','4000000000000000', '26000000000000000','27000000000000000','7000000000000000',
            '28000000000000000','13000000000000000','44000000000000000','29000000000000000','18000000000000000','19000000000000000',
            '11000000000000000','15000000000000000','17000000000000000','31000000000000000','16000000000000000', '20000000000000000');
        
        if(strlen($catId) <= 15) return 0;
        $isTpl13 = 0;
        foreach($tpl13 as $cid) {
            if(strcmp($catId, $cid) == 0) {
                $isTpl13 = 1;
                break;
            }
        }
        
        if( $isTpl13 ||                   // 2.普通图书、外文旧书、连环画、红色文献
            strncmp($catId, '9', 1) == 0      || 
            strncmp($catId, '37000', 5) == 0  || 
            strncmp($catId, '6', 1) == 0      ||
            strncmp($catId, '32', 2) == 0     ||
            strncmp($catId, '35', 2) == 0     ||
            strncmp($catId, '34', 2) == 0     ||
            strncmp($catId, '12', 2) == 0 ) { 
            $tpl = 2;
        } else if(strncmp($catId, '8', 1) == 0 || strncmp($catId, '57', 2) == 0) { // 1.线装古旧书、碑帖印谱
            $tpl = 1;
        } else if(strncmp($catId, '2', 1) == 0) { // 3.名人墨迹
            $tpl = 3;
        } else if(strncmp($catId, '37001', 5) == 0 || strncmp($catId, '37002', 5) == 0) { // 4.名人字画 书法 国画
            $tpl = 4;
        } else if(strncmp($catId, '37003', 5) == 0) { // 5.名人字画	西画
            $tpl = 5;
        } else if(strncmp($catId, '46', 2) == 0) { // 10.钱币
            $tpl = 10;
        } else if(strncmp($catId, '1', 1) == 0 || strncmp($catId, '4', 1) == 0 ) { // 6.期刊、报纸
            $tpl = 6;
        } else if(strncmp($catId, '55', 2) == 0) { // 7.地图类
            $tpl = 7;
        } else if(strncmp($catId, '56', 2) == 0) { // 8.版画宣传画
            $tpl = 8;
        } else if(strncmp($catId, '36', 2) == 0) { // 9.邮票税票
            $tpl = 9;
        } else if(strncmp($catId, '38', 2) == 0) { // 11.照片影像
            $tpl = 11;
        } else if(strncmp($catId, '58', 2) == 0) { // 12.古玩杂项
            $tpl = 12;
        } else {
            $tpl = 2;
        }
        
        return $tpl;
    }
    
    // {"shopId":24,"shopName":"马睿古旧书店","isbn":"","binding":9,"pageSize":"32开","edition":"","printingNum":0,"wordNum":0,"pageNum":0,"printingTime":"1972-05-02"}
    public function params($value)
    {
        if(!isset($this->record['params']) || empty($this->record['params']))
            return '';
        else
            $value = $this->record['params'];
        
        if(strlen($value) > 1500) // params可能包含大段用户输入的文本，被数据库自动截断，造成json格式错误。
            return '';
        
        // params中存在特殊的空白字符\r\n\t\v\f\\'
        $ws = array("\r","\n","\t","\v","\f","\\\\\\'","\\\\'","\\'","\\0");
        $bs = array("", "", " ", "", "", "'","'","'", "");
        $value = str_replace($ws,$bs,$value);
        $p = json_decode($value, true);
        if($p === NULL) {
            $this->errorInfo = $this->getJsonErrorMsg();
            return '';
            //return false;
        }

        if(isset($this->record['catId']) && !empty($this->record['catId']))
            $catId = $this->record['catId'];
        else
            return '';
        
        $tpl13 = array(
            '43000000000000000','1000000000000000','3000000000000000','23000000000000000','5000000000000000', '24000000000000000',
            '14000000000000000','25000000000000000','4000000000000000', '26000000000000000','27000000000000000','7000000000000000',
            '28000000000000000','13000000000000000','44000000000000000','29000000000000000','18000000000000000','19000000000000000',
            '11000000000000000','15000000000000000','17000000000000000','31000000000000000','16000000000000000', '20000000000000000');
        
        $isTpl13 = 0;
        foreach($tpl13 as $cid) {
            if(strcmp($catId, $cid) == 0) {
                $isTpl13 = 1;
                break;
            }
        }
        
        $params = array();
        // 8 57 9 37000 6 32 35 34 12 2 37001 37002 37003 46 1 4 55 56 36 38 58
        if( $isTpl13 ||                   // 2.普通图书、外文旧书、连环画、红色文献
            strncmp($catId, '9', 1) == 0      || 
            strncmp($catId, '37000', 5) == 0  || 
            strncmp($catId, '6', 1) == 0      ||
            strncmp($catId, '32', 2) == 0     ||
            strncmp($catId, '35', 2) == 0     ||
            strncmp($catId, '34', 2) == 0     ||
            strncmp($catId, '12', 2) == 0 ) { 
            if(isset($p['binding']) && !empty($p['binding'])) {
                $binding = intval($p['binding']);
                if(($binding >= 1 && $binding <= 3) || $binding == 9) 
                    $params['binding'] = $binding + 20;
                else 
                    $params['binding'] = $binding;
            } else {
                $params['binding'] = 29;
            }
            
            $this->record['binding'] = $params['binding'];
            
            if(isset($p['pageSize']) && !empty($p['pageSize']))
                $params['pageSize'] = $p['pageSize'];
            if(isset($p['edition']) && !empty($p['edition']))
                $params['edition'] = $p['edition'];
        }  else if(strncmp($catId, '8', 1) == 0 || strncmp($catId, '57', 2) == 0) { // 1.线装古旧书、碑帖印谱
            if(isset($p['paper']) && !empty($p['paper'])) {
                $params['paper'] = intval($p['paper']);
                $this->record['paper'] = $params['paper'];
            }
            if(isset($p['printType']) && !empty($p['printType'])) {
                $params['printType'] = intval($p['printType']);
                $this->record['printType'] = $params['printType'];
            }
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
            if(isset($p['sizeHeight']) && !empty($p['sizeHeight']))
                $params['sizeHeight'] = $p['sizeHeight'];
            if(isset($p['printingNum']) && !empty($p['printingNum']))
                $params['printingNum'] = $p['printingNum'];
        } else if(strncmp($catId, '2', 1) == 0) { // 3.名人墨迹
            if(isset($p['pageNum']) && !empty($p['pageNum']))
                $params['pageNum'] = $p['pageNum'];
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
        }  else if(strncmp($catId, '37001', 5) == 0 || 
                   strncmp($catId, '37002', 5) == 0) { // 4.名人字画 书法 国画
            if(isset($p['sort']) && !empty($p['sort'])) {
                $params['sort'] = intval($p['sort']);
                $this->record['sort'] = $params['sort'];
            }
            if(isset($p['material']) && !empty($p['material'])) {
                $params['material'] = intval($p['material']);
                $this->record['material'] = $params['material'];
            }
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
            if(isset($p['binding']) && !empty($p['binding'])) {
                $binding = intval($p['binding']);
                if(($binding >= 1 && $binding <= 6) || $binding == 9) 
                    $params['binding'] = $binding + 40;
                else 
                    $params['binding'] = $binding;
            } else {
                $params['binding'] = 49;
            }
            $this->record['binding'] = $params['binding'];
        }  else if(strncmp($catId, '37003', 5) == 0) { // 5.名人字画	西画
            if(isset($p['material']) && !empty($p['material'])) {
                $params['material'] = intval($p['material']);
                $this->record['material'] = $params['material'];
            }
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
            if(isset($p['sizeHeight']) && !empty($p['sizeHeight']))
                $params['sizeHeight'] = $p['sizeHeight'];
        }  else if(strncmp($catId, '46', 2) == 0) { // 10.钱币
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
        }  else if(strncmp($catId, '1', 1) == 0 || strncmp($catId, '4', 1) == 0 ) { // 6.期刊、报纸
            if(isset($p['postDate1']) && !empty($p['postDate1']))
                $params['postDate1'] = $this->date2int($p['postDate1']); //strtotime($p['postDate1']) > 0 ? strtotime($p['postDate1']) : 0;
            if(isset($p['postDate2']) && !empty($p['postDate2']))
                $params['postDate2'] = $this->date2int($p['postDate2']); //strtotime($p['postDate2']) > 0 ? strtotime($p['postDate2']) : 0;
            if(isset($p['period1']) && !empty($p['period1']))
                $params['period1'] = $p['period1'];
            if(isset($p['period2']) && !empty($p['period2']))
                $params['period2'] = $p['period2'];
            if(isset($p['totalPeriod1']) && !empty($p['totalPeriod1']))
                $params['totalPeriod1'] = $p['totalPeriod1'];
            if(isset($p['totalPeriod2']) && !empty($p['totalPeriod2']))
                $params['totalPeriod2'] = $p['totalPeriod2'];
            if(isset($p['pageSize']) && !empty($p['pageSize']))
                $params['pageSize'] = $p['pageSize'];
        }  else if(strncmp($catId, '55', 2) == 0) { // 7.地图类
            if(isset($p['form']) && !empty($p['form'])) {
                $params['form'] = intval($p['form']);
                $this->record['form'] = $params['form'];
            }
        }  else if(strncmp($catId, '56', 2) == 0) { // 8.版画宣传画
            if(isset($p['sort']) && !empty($p['sort'])) {
                $params['sort'] = intval($p['sort']);
                $this->record['sort'] = $params['sort'];
            }
            if(isset($p['material']) && !empty($p['material'])) {
                $params['material'] = intval($p['material']);
                $this->record['material'] = $params['material'];
            }
            if(isset($p['printType']) && !empty($p['printType'])) {
                $params['printType'] = intval($p['printType']);
                $this->record['printType'] = $params['printType'];
            }
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
        }  else if(strncmp($catId, '36', 2) == 0) { // 9.邮票税票
            
        }  else if(strncmp($catId, '38', 2) == 0) { // 11.照片影像
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
            if(isset($p['sort']) && !empty($p['sort'])) {
                $params['sort'] = intval($p['sort']);
                $this->record['sort'] = $params['sort'];
            }
        }  else if(strncmp($catId, '58', 2) == 0) { // 12.古玩杂项
            if(isset($p['material']) && !empty($p['material']))
                $params['material'] = $p['material'];
            if(isset($p['sizeLength']) && !empty($p['sizeLength']))
                $params['sizeLength'] = $p['sizeLength'];
            if(isset($p['sizeWidth']) && !empty($p['sizeWidth']))
                $params['sizeWidth'] = $p['sizeWidth'];
            if(isset($p['sizeHeight']) && !empty($p['sizeHeight']))
                $params['sizeHeight'] = $p['sizeHeight'];
        }  else {
        } 
        
        $paramsJson = '';
        if(!empty($params)) {
            foreach ($params as $k => $v) {
                if(is_string($v)) $params[$k] = urlencode($v);
            }
            $paramsJson = json_encode($params);
            if($paramsJson === false) {
                $this->errorInfo = $this->getJsonErrorMsg();
                return false;
            }
            $paramsJson = urldecode($paramsJson);
        }
        
        //把params中反斜线替换为空格
        //$ss = array("\\");
        //$rs = array(" ");
        //$paramsJson = str_replace($ss, $rs, $paramsJson);
        return $paramsJson;
    }
    
    public function paper($value)
    {
        if(isset($this->record['paper']))
            return $this->record['paper'];
        else
            return $value;
    }
    
    public function printType($value)
    {
        if(isset($this->record['printType']))
            return $this->record['printType'];
        else
            return $value;
    }
    
    public function binding($value)
    {
        if(isset($this->record['binding']))
            return $this->record['binding'];
        else
            return $value;
    }
    
    public function sort($value)
    {
        if(isset($this->record['sort']))
            return $this->record['sort'];
        else
            return $value;
    }
    
    public function material($value)
    {
        if(isset($this->record['material']))
            return $this->record['material'];
        else
            return $value;
    }
    
    public function form($value)
    {
        if(isset($this->record['form']))
            return $this->record['form'];
        else
            return $value;
    }
    
    public function isbn($value) 
    {
        if(!isset($this->record['params']) || empty($this->record['params']))
            return '';
        else
            $value = $this->record['params'];
        
        if(strlen($value) > 1500) // params可能包含大段用户输入的文本，被数据库自动截断，造成json格式错误。
            return '';
        
        // params中存在特殊的空白字符\r\n\t\v\f\\'
        $ws = array("\r","\n","\t","\v","\f","\\\\\\'","\\\\'","\\'","\\0");
        $bs = array("", "", " ", "", "", "'","'","'","");
        $value = str_replace($ws,$bs,$value);
        $p = json_decode($value, true);
        if($p === NULL) {
            $this->errorInfo = $this->getJsonErrorMsg();
            //return false;
            return '';
        }
      
        if(isset($p['isbn']) && !empty($p['isbn'])) // 提取isbn,isbn后面有\r\n导致json错误
           return trim($p['isbn']);
        else 
           return '';
    }

    // 计算商品的rank，rank factors: hasImg class addTime 
    public function rank($value) 
    {
        $hasImg = 0;
        if(isset($this->record['img']) && !empty($this->record['img'])) {
            $hasImg = 1;
        }

        $months = 0;
        if(isset($this->record['addTime']) && !empty($this->record['addTime'])) {
            $addTime = $this->record['addTime'];
            $curyear = intval(date("Y"));
            $startyear = $curyear - 7; // 有效上书时间是今年到前七年
            $otime = strtotime($startyear.'-01-01');
            $months = (int)floor(($addTime - $otime)/(86400*30));
            if($months < 0) $months = 0;
            if($months >= 99) $months = 99;
        }
        
        $rank = $hasImg * 1000 + $months;
        return $rank;
    }
    
    /**
     * 处理insert、modify的数据
     */
    public function deal($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        $msgFields = array(
            'itemId',             //endItem
            'userId',             //endItem
            'auctionArea',        //endItem
            'specialArea',        //endItem
            'catId',              //endItem
            'itemName',           //endItem
            'nickname',           //endItem
            'quality',            //endItem
            'author',             //endItem
            'press',              //endItem
            'pubDate',            //endItem
            'preStartTime',       //endItem
            'beginTime',          //endItem
            'endTime',            //endItem
            'beginPrice',         //endItem
            'minAddPrice',        //endItem
            'img',                //endItem
            'isCreateTrade',      //endItem
            'itemStatus',         //endItem      itemStatus：为0是表示审核通过或者正常，为1是表示被屏蔽，为2是表示待审核，为3是表示被驳回，为4表示被删除
            'addTime',            //endItem
            'params',             //endItem
            'viewedNum',          //endItemExt
            'bidNum',             //endItemExt
            'maxPrice',           //endItemExt
            'area',               //auctioneer
            'class',              //auctioneer
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //itemId
        $msg['itemId'] = $msg['itemId'];
        
        //hasImg
        $msg['hasImg'] = $this->hasImg(1);
        
        //pubDate
        $msg['pubDate'] = $this->pubDate($msg['pubDate']);
        
        //pubDate2
        $msg['pubDate2'] = $this->pubDate2(1);
        
        //catId
        $msg['catId'] = $this->catId($msg['catId']);
        
        //catId1
        $msg['catId1'] = $this->catId1(0);
        
        //catId2
        $msg['catId2'] = $this->catId2(0);
        
        //catId3
        $msg['catId3'] = $this->catId3(0);
        
        //catId4
        $msg['catId4'] = $this->catId4(0);
        
        //vcatId
        $msg['vcatId'] = $this->vcatId(0);
        
        //vcatId1
        $msg['vcatId1'] = $this->vcatId1(0);
        
        //vcatId2
        $msg['vcatId2'] = $this->vcatId2(0);
        
        //vcatId3
        $msg['vcatId3'] = $this->vcatId3(0);
        
        //vcatId4
        $msg['vcatId4'] = $this->vcatId4(0);
        
        //params
        $msg['params'] = $this->params($msg['params']);
        
        //years
        $msg['years'] = $this->years(1);
        
        //years2
        $msg['years2'] = $this->years2(1);
        
        //author2
        $msg['author2'] = $this->author2(1);
        
        //press2
        $msg['press2'] = $this->press2(1);
        
        //area
        $msg['area'] = $this->area($msg['area']);
        
        //area1
        $msg['area1'] = $this->area1(0);
        
        //area2
        $msg['area2'] = $this->area2(0);
        
        //paper
        $msg['paper'] = $this->paper(0);
        
        //printType
        $msg['printType'] = $this->printType(0);
        
        //binding
        $msg['binding'] = $this->binding(0);
        
        //sort
        $msg['sort'] = $this->sort(0);
        
        //material
        $msg['material'] = $this->material(0);
        
        //form
        $msg['form'] = $this->form(0);
        
        //isbn
        $msg['isbn'] = $this->isbn(0);
        
        //rank
        $msg['rank'] = $this->rank(0);
        
        //isdeleted
        $msg['isdeleted'] = 0;
        
        //flag1
        $msg['flag1'] = 0;
        
        //flag2
        $msg['flag2'] = 0;
        
        //itemName
        $msg['itemName'] = $this->fan2jian($msg['itemName']);
        
        //_itemName
        $msg['_itemName'] = $msg['itemName'];
        
        //author
        $msg['author'] = $this->fan2jian($msg['author']);
        
        //_author
        $msg['_author'] = $msg['author'];
        
        //author2
        $msg['author2'] = $this->fan2jian($msg['author2']);
        
        //iauthor
        $msg['iauthor'] = $this->fnv64($msg['author2']);
        
        //press
        $msg['press'] = $this->fan2jian($msg['press']);
        
        //_press
        $msg['_press'] = $msg['press'];
        
        //press2
        $msg['press2'] = $this->fan2jian($msg['press2']);
        
        //ipress
        $msg['ipress'] = $this->fnv64($msg['press2']);
        
        //_nickname
        $msg['_nickname'] = $this->fan2jian($msg['nickname']);
        
        //n_itemname
        $msg['n_itemname'] = $msg['itemName'];
        
        //py_itemname
        $msg['py_itemname'] = $msg['itemName'];
        
        //n_author
        $msg['n_author'] = $msg['author'];
        
        //py_author
        $msg['py_author'] = $msg['author'];
        
        //n_press
        $msg['n_press'] = $msg['press'];
        
        //py_press
        $msg['py_press'] = $msg['press'];
        
        //大小写转换
        foreach($msg as $k => $v) {
            $lower_k = strtolower($k);
            if($k === $lower_k) {
                continue;
            }
            $msg[$lower_k] = $v;
            unset($msg[$k]);
        }
        
        return $msg;

    }
    
    /**
     * 处理update的数据
     */
    public function dealUp($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        
        //userId
        if(isset($msg['userId']) && $msg['userId']) {
            $msg['userId'] = $msg['userId'];
        }
        
        //hasImg
        if(isset($msg['hasImg']) || isset($msg['img'])) {
            $msg['hasImg'] = $this->hasImg(1);
        }
        
        //pubDate
        if(isset($msg['pubDate'])) {
            $msg['pubDate'] = $this->pubDate($msg['pubDate']);
        }
        
        //pubDate2
        if(isset($msg['pubDate'])) {
            $msg['pubDate2'] = $this->pubDate2(1);
        }
        
        //catId
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['catId'] = $this->catId($msg['catId']);
        }
        
        //catId1
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['catId1'] = $this->catId1(0);
        }
        
        //catId2
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['catId2'] = $this->catId2(0);
        }
        
        //catId3
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['catId3'] = $this->catId3(0);
        }
        
        //catId4
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['catId4'] = $this->catId4(0);
        }
        
        //vcatId
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['vcatId'] = $this->vcatId(0);
        }
        
        //vcatId1
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['vcatId1'] = $this->vcatId1(0);
        }
        
        //vcatId2
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['vcatId2'] = $this->vcatId2(0);
        }
        
        //vcatId3
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['vcatId3'] = $this->vcatId3(0);
        }
        
        //vcatId4
        if(isset($msg['catId']) && $msg['catId']) {
            $msg['vcatId4'] = $this->vcatId4(0);
        }
        
        //params
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['params'] = $this->params($msg['params']);
        }
        
        //years
        if(isset($msg['years'])) {
            $msg['years'] = $this->years(1);
        }
        
        //years2
        if(isset($msg['years'])) {
            $msg['years2'] = $this->years2(1);
        }
        
        //author2
        if(isset($msg['author'])) {
            $msg['author2'] = $this->author2(1);
        }
        
        //press2
        if(isset($msg['press'])) {
            $msg['press2'] = $this->press2(1);
        }
        
        //area
        if(isset($msg['area'])) {
            $msg['area'] = $this->area($msg['area']);
        }
        
        //area1
        if(isset($msg['area'])) {
            $msg['area1'] = $this->area1(0);
        }
        
        //area2
        if(isset($msg['area'])) {
            $msg['area2'] = $this->area2(0);
        }
        
        //paper
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['paper'] = $this->paper(0);
        }
        
        //printType
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['printType'] = $this->printType(0);
        }
        
        //binding
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['binding'] = $this->binding(0);
        }
        
        //sort
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['sort'] = $this->sort(0);
        }
        
        //material
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['material'] = $this->material(0);
        }
        
        //form
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['form'] = $this->form(0);
        }
        
        //isbn
        if(isset($msg['params']) && isset($msg['catId'])) {
            $msg['isbn'] = $this->isbn(0);
        }
        
        //rank
        if(isset($msg['img']) && isset($msg['addTime'])) {
            $msg['rank'] = $this->rank(0);
        }
        
        //addTime
        if(isset($msg['addTime']) && $msg['addTime']) {
            $msg['addTime'] = $msg['addTime'];
        }
        
        //itemName
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['itemName'] = $this->fan2jian($msg['itemName']);
        }
        
        //_itemName
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['_itemName'] = $msg['itemName'];
        }
        
        //author
        if(isset($msg['author'])) {
            $msg['author'] = $this->fan2jian($msg['author']);
        }
        
        //_author
        if(isset($msg['author'])) {
            $msg['_author'] = $msg['author'];
        }
        
        //author2
        if(isset($msg['author'])) {
            $msg['author2'] = $this->fan2jian($msg['author2']);
        }
        
        //iauthor
        if(isset($msg['author'])) {
            $msg['iauthor'] = $this->fnv64($msg['author2']);
        }
        
        //press
        if(isset($msg['press'])) {
            $msg['press'] = $this->fan2jian($msg['press']);
        }
        
        //_press
        if(isset($msg['press'])) {
            $msg['_press'] = $msg['press'];
        }
        
        //press2
        if(isset($msg['press'])) {
            $msg['press2'] = $this->fan2jian($msg['press2']);
        }
        
        //ipress
        if(isset($msg['press'])) {
            $msg['ipress'] = $this->fnv64($msg['press2']);
        }
        
        //_nickname
        if(isset($msg['nickname']) && $msg['nickname']) {
            $msg['_nickname'] = $this->fan2jian($msg['nickname']);
        }
        
        //n_itemname
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['n_itemname'] = $msg['itemName'];
        }
        
        //py_itemname
        if(isset($msg['itemName']) && $msg['itemName']) {
            $msg['py_itemname'] = $msg['itemName'];
        }
        
        //n_author
        if(isset($msg['author'])) {
            $msg['n_author'] = $msg['author'];
        }
        
        //py_author
        if(isset($msg['author'])) {
            $msg['py_author'] = $msg['author'];
        }
        
        //n_press
        if(isset($msg['press'])) {
            $msg['n_press'] = $msg['press'];
        }
        
        //py_press
        if(isset($msg['press'])) {
            $msg['py_press'] = $msg['press'];
        }
        
        //大小写转换
        foreach($msg as $k => $v) {
            $lower_k = strtolower($k);
            if($k === $lower_k) {
                continue;
            }
            $msg[$lower_k] = $v;
            unset($msg[$k]);
        }
        
        return $msg;

    }
}
