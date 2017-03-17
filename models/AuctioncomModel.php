<?php

/**
 * Created by diao.
 * Date: 16-9-13
 * Time: 下午4:35
 */
class AuctioncomModel
{
    public function __construct($data)
    {
        //大小写转换
        foreach ($data as $k => $v) {
            $lower_k = strtolower($k);
            if ($k === $lower_k) {
                continue;
            }
            $data[$lower_k] = $v;
            unset($data[$k]);
        }
        $this->record = $data;
        $this->valueList = array();
    }

    public function itemId()
    {
        if (!isset($this->record['itemid']) || empty($this->record['itemid'])) {
            echo 'itemId cannot null or empty!!!';
            exit;
        } else {
            $this->valueList['itemid'] = $this->record['itemid'];
        }
    }

    public function comId($flag)
    {
        if (!isset($this->record['comid'])) {
            if ($flag == 'insert') {
                $this->valueList['comid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['comid']);
            }
        } else {
            $this->valueList['comid'] = $this->record['comid'];
        }
    }

    public function comName($flag)
    {
        if (!isset($this->record['comname'])) {
            if ($flag == 'insert') {
                $this->valueList['comname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['comname']);
            }
        } else {
            $this->valueList['comname'] = $this->fan2jian($this->record['comname']);
        }
    }

    public function userId($flag)
    {
        if (!isset($this->record['userid'])) {
            if ($flag == 'insert') {
                $this->valueList['userid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['userid']);
            }
        } else {
            $this->valueList['userid'] = $this->record['userid'];
        }
    }

    public function cusId($flag)
    {
        if (!isset($this->record['cusid'])) {
            if ($flag == 'insert') {
                $this->valueList['cusid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['cusid']);
            }
        } else {
            $this->valueList['cusid'] = $this->record['cusid'];
        }
    }

    public function itemName($flag)
    {
        if (!isset($this->record['itemname'])) {
            if ($flag == 'insert') {
                $this->valueList['itemname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['itemname']);
            }
        } else {
            $this->valueList['itemname'] = $this->fan2jian($this->record['itemname']);
        }
    }

    public function catId($flag)
    {
        if (!isset($this->record['catid'])) {
            if ($flag == 'insert') {
                $this->valueList['catid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['catid']);
            }
        } else {
            $this->valueList['catid'] = $this->record['catid'];
        }
    }

    public function author($flag)
    {
        if (!isset($this->record['author'])) {
            if ($flag == 'insert') {
                $this->valueList['author'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['author']);
            }
        } else {
            $this->valueList['author'] = $this->record['author'];
        }
    }

    public function decade($flag)
    {
        if (!isset($this->record['decade'])) {
            if ($flag == 'insert') {
                $this->valueList['decade'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['decade']);
            }
        } else {
            $this->valueList['decade'] = $this->fan2jian($this->record['decade']);
        }
    }

    public function beginPrice($flag)
    {
        if (!isset($this->record['beginprice'])) {
            if ($flag == 'insert') {
                $this->valueList['beginprice'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['beginprice']);
            }
        } else {
            $this->valueList['beginprice'] = $this->record['beginprice'];
        }
    }

    public function beginRefPrice($flag)
    {
        if (!isset($this->record['beginrefprice'])) {
            if ($flag == 'insert') {
                $this->valueList['beginrefprice'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['beginrefprice']);
            }
        } else {
            $this->valueList['beginrefprice'] = $this->record['beginrefprice'];
        }
    }

    public function endRefPrice($flag)
    {
        if (!isset($this->record['endrefprice'])) {
            if ($flag == 'insert') {
                $this->valueList['endrefprice'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['endrefprice']);
            }
        } else {
            $this->valueList['endrefprice'] = $this->record['endrefprice'];
        }
    }

    public function bargainPrice($flag)
    {
        if (!isset($this->record['bargainprice'])) {
            if ($flag == 'insert') {
                $this->valueList['bargainprice'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['bargainprice']);
            }
        } else {
            $this->valueList['bargainprice'] = $this->record['bargainprice'];
        }
    }

    public function bigImg($flag)
    {
        if (!isset($this->record['bigimg'])) {
            if ($flag == 'insert') {
                $this->valueList['bigimg'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bigimg']);
            }
        } else {
            $this->valueList['bigimg'] = $this->record['bigimg'];
        }
    }

    public function isHidden($flag)
    {
        if (!isset($this->record['ishidden'])) {
            if ($flag == 'insert') {
                $this->valueList['ishidden'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['ishidden']);
            }
        } else {
            $this->valueList['ishidden'] = $this->record['ishidden'];
        }
    }

    public function viewedNum($flag)
    {
        if (!isset($this->record['viewednum'])) {
            if ($flag == 'insert') {
                $this->valueList['viewednum'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['viewednum']);
            }
        } else {
            $this->valueList['viewednum'] = $this->record['viewednum'];
        }
    }

    public function speId($flag)
    {
        if (!isset($this->record['speid'])) {
            if ($flag == 'insert') {
                $this->valueList['speid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['speid']);
            }
        } else {
            $this->valueList['speid'] = $this->record['speid'];
        }
    }

    public function beginTime($flag)
    {
        if (!isset($this->record['begintime'])) {
            if ($flag == 'insert') {
                $this->valueList['begintime'] = $this->date2int('2999-01-01');
            }
            if ($flag == 'update') {
                unset($this->valueList['begintime']);
            }
        } else {
            $this->valueList['begintime'] = $this->date2int($this->record['begintime']);
        }
    }

    public function isDeleted($flag)
    {
        if (!isset($this->record['isdeleted'])) {
            if ($flag == 'insert') {
                $this->valueList['isdeleted'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['isdeleted']);
            }
        } else {
            $this->valueList['isdeleted'] = $this->record['isdeleted'];
        }
    }

    public function _itemName($flag)
    {
        if (!isset($this->record['itemname'])) {
            if ($flag == 'insert') {
                $this->valueList['_itemname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_itemname']);
            }
        } else {
            $this->valueList['_itemname'] = $this->fan2jian($this->record['itemname']);
        }
    }

    public function _decade($flag)
    {
        if (!isset($this->record['decade'])) {
            if ($flag == 'insert') {
                $this->valueList['_decade'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_decade']);
            }
        } else {
            $this->valueList['_decade'] = $this->fan2jian($this->record['decade']);
        }
    }

    public function _comName($flag)
    {
        if (!isset($this->record['comname'])) {
            if ($flag == 'insert') {
                $this->valueList['_comname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_comname']);
            }
        } else {
            $this->valueList['_comname'] = $this->fan2jian($this->record['comname']);
        }
    }

    public function beginTime2($flag)
    {
        if (!isset($this->record['begintime2'])) {
            if ($flag == 'insert') {
                $this->valueList['begintime2'] = $this->date2int('2999-01-01');
            }
            if ($flag == 'update') {
                unset($this->valueList['begintime2']);
            }
        } else {
            $this->valueList['begintime2'] = $this->date2int($this->record['begintime2']);
        }
    }

    public function comShortName($flag)
    {
        if (!isset($this->record['comshortname'])) {
            if ($flag == 'insert') {
                $this->valueList['comshortname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['comshortname']);
            }
        } else {
            $this->valueList['comshortname'] = $this->record['comshortname'];
        }
    }

    public function setValueList($flag)
    {
        $this->itemId();
        $this->comId($flag);
        $this->comName($flag);
        $this->userId($flag);
        $this->cusId($flag);
        $this->itemName($flag);
        $this->catId($flag);
        $this->author($flag);
        $this->decade($flag);
        $this->beginPrice($flag);
        $this->beginRefPrice($flag);
        $this->endRefPrice($flag);
        $this->bargainPrice($flag);
        $this->bigImg($flag);
        $this->isHidden($flag);
        $this->viewedNum($flag);
        $this->speId($flag);
        $this->beginTime($flag);
        $this->isDeleted($flag);
        $this->_itemName($flag);
        $this->_decade($flag);
        $this->_comName($flag);
        $this->beginTime2($flag);
        $this->comShortName($flag);
    }

    public function getValueList()
    {
        return $this->valueList;
    }

    // 日期格式必须为: yyyy-mm-dd  yyyy-m-d
    private function date2int($value, $default = 0)
    {
        $v = $default;
        if ($value != '0000-00-00') {
            $ymd = explode('-', $value);
            foreach ($ymd as $k => $v) {
                if ($k == 0 && strlen($v) != 4)
                    return 0;
                if (($k == 1 || $k == 2) && strlen($v) == 1)
                    $ymd[$k] = '0' . $v;
            }

            if (count($ymd) == 1) {
                $v = intval($ymd[0] . '0000');
            } else if (count($ymd) == 2) {
                $v = intval($ymd[0] . $ymd[1] . '00');
            } else if (count($ymd) == 3) {
                $v = intval($ymd[0] . $ymd[1] . $ymd[2]);
            }
        }

        return $v;
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
}