<?php

date_default_timezone_set('Asia/Chongqing');

class indexupdate_es_footprint_shop
{
    private $errorInfo;
    private $record;
    private static $authorBlist;
    
    public function __construct($config) 
    {
        $this->errorInfo = '';
        $this->record = array();
        
        // 加载作者黑名单
        if(!isset(self::$authorBlist)) {
            self::$authorBlist = array();
            if(isset($config['blacklist.author']) && !empty($config['blacklist.author'])) {
                $blist = file($config['blacklist.author']);
                if($blist === false) {
                    $this->errorInfo = "load {$config['blacklist.author']} failure.";
                    throw new Exception($this->errorInfo);
                }

               foreach($blist as $key){
                   $key = trim($key);
                   self::$authorBlist[$key] = 1;
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
        if(empty($value))
            return '';
        
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
    
    /**
     * 处理insert、modify的数据
     */
    public function deal($msg)
    {
        $msg = $msg['data'];
        $this->record = $msg;
        $msgFields = array(
            'id',
            'itemId',
            'itemName',
            'catId',
            'imgUrl',
            'shopClass',
            'isSaled',
            'insertTime',
            'sellerId',
            'viewerId',
            'shopId'
        );
        foreach($msgFields as $field) {
            if(!isset($msg[$field])) {
                $this->errorInfo = var_export($msg, true). "Error : $field is not set.";
                return false;
            }
        }
        
        //itemName
        $msg['itemName'] = $this->fan2jian($msg['itemName']);
        
        //_itemName
        $msg['_itemName'] = $msg['itemName'];
        
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
            $msg['author2'] = $this->author2($msg['author']);
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
    
    public function custominsert($indexconfig, $msg)
    {
        if(!isset($msg['data']) || empty($msg['data'])) {
            $this->errorInfo = "[ERROR]: data isn't set.";
            return false;
        }
        $insertData = $this->deal($msg);
        if($insertData === false) {
            $this->errorInfo = $this->getErrorInfo();
            return false;
        }
        $server = ElasticSearchModel::getServer($indexconfig['servers']);
        $searchHasResult = ElasticSearchModel::getDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $insertData['id']);
        $count = 0;
        $isdeleted = 0;
        if(!empty($searchHasResult) && isset($searchHasResult['found']) && $searchHasResult['found'] == 'true' && isset($searchHasResult['_source']) && isset($searchHasResult['_source']['count']) && isset($searchHasResult['_source']['isdeleted'])) {
            $count = $searchHasResult['_source']['count'];
            $isdeleted = $searchHasResult['_source']['isdeleted'];
        }
        $insertData['count'] = $count + 1;
        $insertData['isdeleted'] = $isdeleted;
        $result = ElasticSearchModel::indexDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $insertData, $insertData['id']);
        if(!$result || !isset($result['created'])) {
            $this->errorInfo = "[ERROR]: ". var_export($result, true);
            return false;
        }
        
        //删除超过指定长度的文档
        $condition = array();
        $condition['filter']['must'][] = array('field' => 'viewerid', 'value' => $insertData['viewerid']);
        $condition['limit'] = array('from' => 0, 'size' => 1);
        $searchNumResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($server['host'], $server['port'], $msg['index'], $msg['type'], 0, array('id'), array(), $condition['filter'], array(), $condition['limit'], array(), array(), 60)); //在搜索中数量
        $searchNum = $searchNumResult['total'];
        if($searchNum > 200) { //如果结果大于200
            $condition = array();
            $condition['filter']['must'][] = array('field' => 'viewerid', 'value' => $insertData['viewerid']);
            $condition['limit'] = array('from' => 0, 'size' => 300);
            $condition['sort'] = array(array('field' => 'inserttime', 'order' => 'desc'));
            $searchResult = ElasticSearchModel::trunslateFindResult(ElasticSearchModel::findDocument($server['host'], $server['port'], $msg['index'], $msg['type'], 0, array('id'), array(), $condition['filter'], $condition['sort'], $condition['limit'], array(), array(), 60));
            if(count($searchResult['data']) > 200) {
                $i = 0;
                foreach($searchResult['data'] as $data) {
                    $i++;
                    if($i > 200) {
                        $id = $data['id'];
                        ElasticSearchModel::deleteDocument($server['host'], $server['port'], $msg['index'], $msg['type'], $id);
                    }
                }
            }
        }
        
        return true;
    }
    
}
