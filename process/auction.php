<?php

require_once 'convertor.php';

date_default_timezone_set('Asia/Chongqing');

class endauction extends Convertor
{
    private $cache;
    private $expire;
    private $dbHost;
    private $dbPort;
    private $dbName;
    private $dbUser;
    private $dbPwd;
    
    // 采用静态属性，索引更新时只需要初始化一次
    private static $pressBlist;
    private static $authorBlist;
    private static $vcatemap;
    
    public function __construct($dataType, $gatherMode, $args) 
    {
        parent::__construct($dataType, $gatherMode);
        $this->cache = NULL;
        
        if(empty($args)) 
            throw new Exception ('convert arguments is empty');
        
        if(isset($args['cache']) && !empty($args['cache']))
            $cache = explode(':', $args['cache']);
        else 
            throw new Exception ('cache set error in [convert]');
        
        $this->dbHost = '';
        $this->dbPort = '';
        $this->dbName = '';
        $this->dbUser = '';
        $this->dbPwd = '';
        if(isset($args['DB.host']) && !empty($args['DB.host']))
            $this->dbHost = $args['DB.host'];
        if(isset($args['DB.port']) && !empty($args['DB.port']))
            $this->dbPort = $args['DB.port'];
        if(isset($args['DB.name']) && !empty($args['DB.name']))
            $this->dbName = $args['DB.name'];
        if(isset($args['DB.user']) && !empty($args['DB.user']))
            $this->dbUser = $args['DB.user'];
        if(isset($args['DB.password']) && !empty($args['DB.password']))
            $this->dbPwd = $args['DB.password'];
        
        // 连接redis cache
        $this->cache = new Redis();
        $conn = $this->cache->pconnect($cache[0], $cache[1]);
        if($conn === false) {
            $this->cache = NULL;
            $this->errorInfo = "connect cache server [{$cache[0]}:{$cache[1]}] failure.";
            throw new Exception($this->errorInfo);
        }
        $this->expire = $cache[2];
        
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
    
    public function __destruct() 
    {
        if($this->cache !== NULL) {
            $this->cache->close();
        }
        
        unset($this->record);
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
    
    public function viewedNum($value)
    {
        if(!isset($this->record['userId']) || empty($this->record['userId'])) {
            $this->errorInfo = "userId inexist for [viewedNum]";
            return false;
        } else {
            $userID = $this->record['userId'];
        }
        
        if(!isset($this->record['itemId']) || empty($this->record['itemId'])) {
            $this->errorInfo = "itemId inexist for [viewedNum]";
            return false;
        } else {
            $itemID = $this->record['itemId'];
        }
        
        // 根据itemId从对应的endItemExt_表中查询viewedNum、bidNum、maxPrice
        try {
            $dsn = 'mysql:' . 'host=' . $this->dbHost . ';' . 'port=' . $this->dbPort . ';' . 'dbname=' . $this->dbName . ';' . 'charset=utf8';
            $pdo = new PDO($dsn, $this->dbUser, $this->dbPwd, array(PDO::ATTR_PERSISTENT => true)); //采用持久连接，减少数据库连接数
            $pdo->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            return false;
        }
        
        $pos = strpos($this->table,'_');
        $table = substr($this->table, 0, $pos);
        $tabID = substr($this->table, $pos+1);
        $table = $table . 'Ext_' . $tabID; //endItemExt_23
        $sql = "SELECT viewedNum,bidNum,maxPrice FROM $table WHERE itemId = $itemID";
        $result = $pdo->query($sql);
        if($result === false) {
            $e = $pdo->errorInfo();
            $this->errorInfo = $e[2];
            //$pdo = NULL;
            return false;
        }
        
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) { //返回的结果为空。
            $this->errorInfo = "itemID [{$itemID}] inexist in endItemExt_{$tabID}";
            //$pdo = NULL;
            return ''; // 忽略该字段。
        }
        
        // 关闭连接
        //$pdo = NULL;
        
        $viewedNum = $resultset[0]['viewedNum'];
        $bidNum = $resultset[0]['bidNum'];
        $maxPrice = $resultset[0]['maxPrice'];
        $this->record['bidNum'] = $bidNum;
        $this->record['maxPrice'] = $maxPrice;
        return $viewedNum;
    }
    
    public function bidNum($value)
    {
        if(isset($this->record['bidNum']))
            return $this->record['bidNum'];
        else
            return $value;
    }
    
    public function maxPrice($value)
    {
        if(isset($this->record['maxPrice']))
            return $this->record['maxPrice'];
        else
            return $value;
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
        if(empty($value) || strlen($value) > 1500) // params可能包含大段用户输入的文本，被数据库自动截断，造成json格式错误。
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
        
        if (isset($p['isbn']) && !empty($p['isbn'])) {
            $params['isbn'] = trim($p['isbn']);
            $this->record['isbn'] = $params['isbn'];
        }
        if (isset($p['years']) && !empty($p['years'])) {
            $params['years'] = intval($p['years']);
            $this->record['years'] = $params['years'];
        }
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
    
    public function isbn($value)
    {
        if(isset($this->record['isbn']))
            return $this->record['isbn'];
        else
            return $value;
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
    
    
}

?>