<?php

/**
 * Created by PhpStorm.
 * User: diao
 * Date: 16-9-23
 * Time: 上午9:58
 */
class ShufangModel
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

    private function id()
    {
        if (!isset($this->record['id']) || empty($this->record['id'])) {
            echo 'itemId cannot null or empty!!!';
            exit;
        } else {
            $this->valueList['id'] = $this->record['id'];
        }
    }

    private function bookId($flag)
    {
        if (!isset($this->record['bookid'])) {
            if ($flag == 'insert') {
                $this->valueList['bookid'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['bookid']);
            }
        } else {
            $this->valueList['bookid'] = $this->record['bookid'];
        }
    }

    private function bookFrom($flag)
    {
        if (!isset($this->record['bookfrom'])) {
            if ($flag == 'insert') {
                $this->valueList['bookfrom'] = 1;
            }
            if ($flag == 'update') {
                unset($this->valueList['bookfrom']);
            }
        } else {
            $this->valueList['bookfrom'] = $this->record['bookfrom'];
        }
    }

    private function studyId()
    {
        if (!isset($this->record['studyid']) || empty($this->record['studyid'])) {
            echo 'studyId cannot null or empty!!!';
            exit;
        } else {
            $this->valueList['studyid'] = $this->record['studyid'];
        }
    }

    private function uid($flag)
    {
        if (!isset($this->record['uid'])) {
            if ($flag == 'insert') {
                $this->valueList['uid'] = 1;
            }
            if ($flag == 'update') {
                unset($this->valueList['uid']);
            }
        } else {
            $this->valueList['uid'] = $this->record['uid'];
        }
    }

    private function bookName($flag)
    {
        if (!isset($this->record['bookname'])) {
            if ($flag == 'insert') {
                $this->valueList['bookname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookname']);
            }
        } else {
            $this->valueList['bookname'] = $this->record['bookname'];
        }
    }

    private function author($flag)
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

    private function isbn($flag)
    {
        if (!isset($this->record['isbn'])) {
            if ($flag == 'insert') {
                $this->valueList['isbn'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['isbn']);
            }
        } else {
            $this->valueList['isbn'] = $this->record['isbn'];
        }
    }

    private function press($flag)
    {
        if (!isset($this->record['press'])) {
            if ($flag == 'insert') {
                $this->valueList['press'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['press']);
            }
        } else {
            $this->valueList['press'] = $this->record['press'];
        }
    }

    private function pubDate($flag)
    {
        if (!isset($this->record['pubdate'])) {
            if ($flag == 'insert') {
                $this->valueList['pubdate'] = 1;
            }
            if ($flag == 'update') {
                unset($this->valueList['pubdate']);
            }
        } else {
            $this->valueList['pubdate'] = $this->record['pubdate'];
        }
    }

    private function image($flag)
    {
        if (!isset($this->record['image'])) {
            if ($flag == 'insert') {
                $this->valueList['image'] = 1;
            }
            if ($flag == 'update') {
                unset($this->valueList['image']);
            }
        } else {
            $this->valueList['image'] = $this->record['image'];
        }
    }

    private function _bookName($flag)
    {
        if (!isset($this->record['bookname'])) {
            if ($flag == 'insert') {
                $this->valueList['_bookname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_bookname']);
            }
        } else {
            $this->valueList['_bookfrom'] = $this->record['bookfrom'];
        }
    }

    private function _author($flag)
    {
        if (!isset($this->record['author'])) {
            if ($flag == 'insert') {
                $this->valueList['_author'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_author']);
            }
        } else {
            $this->valueList['_author'] = $this->record['author'];
        }
    }

    private function studyName($flag)
    {
        if (!isset($this->record['studyname'])) {
            if ($flag == 'insert') {
                $this->valueList['studyname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['studyname']);
            }
        } else {
            $this->valueList['studyname'] = $this->record['studyname'];
        }
    }

    private function nickName($flag)
    {
        if (!isset($this->record['nickname'])) {
            if ($flag == 'insert') {
                $this->valueList['nickname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['nickname']);
            }
        } else {
            $this->valueList['nickname'] = $this->record['nickname'];
        }
    }

    private function _studyName($flag)
    {
        if (!isset($this->record['studyname'])) {
            if ($flag == 'insert') {
                $this->valueList['_studyname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_studyname']);
            }
        } else {
            $this->valueList['_studyname'] = $this->record['studyname'];
        }
    }

    private function _nickName($flag)
    {
        if (!isset($this->record['nickname'])) {
            if ($flag == 'insert') {
                $this->valueList['_nickname'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_nickname']);
            }
        } else {
            $this->valueList['_nickname'] = $this->record['nickname'];
        }
    }

    public function setValueList($flag)
    {
        if (isset($this->record['type']) && !empty($this->record['type'])) {
            if ($this->record['type'] == 'study_book_search') {
                $this->id();
                $this->studyId();
                $this->bookId($flag);
                $this->bookFrom($flag);
                $this->uid($flag);
                $this->bookName($flag);
                $this->author($flag);
                $this->isbn($flag);
                $this->press($flag);
                $this->pubDate($flag);
                $this->image($flag);
                $this->_bookName($flag);
                $this->_author($flag);
            }
            if ($this->record['type'] == 'study_search') {
                $this->studyId();
                $this->studyName($flag);
                $this->nickName($flag);
                $this->uid($flag);
                $this->_studyName($flag);
                $this->_nickName($flag);
            }
        }
    }

    public function getValueList()
    {
        return $this->valueList;
    }
}