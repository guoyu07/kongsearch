<?php

/**
 * Created by diao
 * Date: 16-8-30
 * Time: 上午11:08
 */
class BooklibModel
{
    public function __construct($data)
    {
        $this->record = $data;
        $this->valueList = array();
    }

    public function bookId()
    {
        if (!isset($this->record['bookId']) || empty($this->record['bookId'])) {
            echo 'bookId cannot null or empty!!!';
            exit;
        } else {
            $this->valueList['bookId'] = $this->record['bookId'];
        }
    }

    public function uniqueMd5($flag)
    {
        if (!isset($this->record['uniqueMd5'])) {
            if ($flag == 'insert') {
                $this->valueList['uniqueMd5'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['uniqueMd5']);
            }
        } else {
            $this->valueList['uniqueMd5'] = $this->record['uniqueMd5'];
        }
    }

    public function bookName($flag)
    {
        if (!isset($this->record['bookName'])) {
            if ($flag == 'insert') {
                $this->valueList['bookName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookName']);
            }
        } else {
            $this->valueList['bookName'] = $this->fan2jian($this->record['bookName']);
        }
    }

    public function bookNamePinyin($flag)
    {
        if (!isset($this->record['bookNamePinyin'])) {
            if ($flag == 'insert') {
                $this->valueList['bookNamePinyin'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookNamePinyin']);
            }
        } else {
            $this->valueList['bookNamePinyin'] = $this->record['bookNamePinyin'];
        }
    }

    public function catName($flag)
    {
        if (!isset($this->record['catName'])) {
            if ($flag == 'insert') {
                $this->valueList['catName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['catName']);
            }
        } else {
            $this->valueList['catName'] = $this->record['catName'];
        }
    }

    public function catId($flag)
    {
        if (!isset($this->record['catId'])) {
            if ($flag == 'insert') {
                $this->valueList['catId'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['catId']);
            }
        } else {
            $this->valueList['catId'] = $this->record['catId'];
        }
    }

    public function price($flag)
    {
        if (!isset($this->record['price'])) {
            if ($flag == 'insert') {
                $this->valueList['price'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['price']);
            }
        } else {
            $this->valueList['price'] = $this->record['price'];
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

    public function press($flag)
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

    public function pubDate($flag)
    {
        if (!isset($this->record['pubDate'])) {
            if ($flag == 'insert') {
                $this->valueList['pubDate'] = '9999-12-31';
            }
            if ($flag == 'update') {
                unset($this->valueList['pubDate']);
            }
        } else {
            $this->valueList['pubDate'] = $this->record['pubDate'];
        }
    }

    public function edition($flag)
    {
        if (!isset($this->record['edition']) || empty($this->record['edition'])) {
            if ($flag == 'insert') {
                $this->valueList['edition'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['edition']);
            }
        } else {
            $this->valueList['edition'] = $this->record['edition'];
        }
    }

    public function isbn($flag)
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

    public function certifyStatus($flag)
    {
        if (!isset($this->record['certifyStatus'])) {
            if ($flag == 'insert') {
                $this->valueList['certifyStatus'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['certifyStatus']);
            }
        } else {
            $this->valueList['certifyStatus'] = $this->record['certifyStatus'];
        }
    }

    public function zcatId($flag)
    {
        if (!isset($this->record['zcatId'])) {
            if ($flag == 'insert') {
                $this->valueList['zcatId'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['zcatId']);
            }
        } else {
            $this->valueList['zcatId'] = $this->record['zcatId'];
        }
    }

    public function editorComment($flag)
    {
        if (!isset($this->record['editorComment'])) {
            if ($flag == 'insert') {
                $this->valueList['editorComment'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['editorComment']);
            }
        } else {
            $this->valueList['editorComment'] = $this->record['editorComment'];
        }
    }

    public function contentIntroduction($flag)
    {
        if (!isset($this->record['contentIntroduction'])) {
            if ($flag == 'insert') {
                $this->valueList['contentIntroduction'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['contentIntroduction']);
            }
        } else {
            $this->valueList['contentIntroduction'] = $this->record['contentIntroduction'];
        }
    }

    public function directory($flag)
    {
        if (!isset($this->record['directory'])) {
            if ($flag == 'insert') {
                $this->valueList['directory'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['directory']);
            }
        } else {
            $this->valueList['directory'] = $this->record['directory'];
        }
    }

    public function illustration($flag)
    {
        if (!isset($this->record['illustration'])) {
            if ($flag == 'insert') {
                $this->valueList['illustration'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['illustration']);
            }
        } else {
            $this->valueList['illustration'] = $this->record['illustration'];
        }
    }

    public function description($flag)
    {
        if (!isset($this->record['description'])) {
            if ($flag == 'insert') {
                $this->valueList['description'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['description']);
            }
        } else {
            $this->valueList['description'] = $this->record['description'];
        }
    }

    public function bookForeign($flag)
    {
        if (!isset($this->record['bookForeign'])) {
            if ($flag == 'insert') {
                $this->valueList['bookForeign'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookForeign']);
            }
        } else {
            $this->valueList['bookForeign'] = $this->record['bookForeign'];
        }
    }

    public function area($flag)
    {
        if (!isset($this->record['area'])) {
            if ($flag == 'insert') {
                $this->valueList['area'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['area']);
            }
        } else {
            $this->valueList['area'] = $this->record['area'];
        }
    }

    public function language($flag)
    {
        if (!isset($this->record['language'])) {
            if ($flag == 'insert') {
                $this->valueList['language'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['language']);
            }
        } else {
            $this->valueList['language'] = $this->record['language'];
        }
    }

    public function originalLanguage($flag)
    {
        if (!isset($this->record['originalLanguage'])) {
            if ($flag == 'insert') {
                $this->valueList['originalLanguage'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['originalLanguage']);
            }
        } else {
            $this->valueList['originalLanguage'] = $this->record['originalLanguage'];
        }
    }

    public function catAgency($flag)
    {
        if (!isset($this->record['catAgency'])) {
            if ($flag == 'insert') {
                $this->valueList['catAgency'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['catAgency']);
            }
        } else {
            $this->valueList['catAgency'] = $this->record['catAgency'];
        }
    }

    public function wordNum($flag)
    {
        if (!isset($this->record['wordNum'])) {
            if ($flag == 'insert') {
                $this->valueList['wordNum'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['wordNum']);
            }
        } else {
            $this->valueList['wordNum'] = $this->record['wordNum'];
        }
    }

    public function pageNum($flag)
    {
        if (!isset($this->record['pageNum'])) {
            if ($flag == 'insert') {
                $this->valueList['pageNum'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['pageNum']);
            }
        } else {
            $this->valueList['pageNum'] = $this->record['pageNum'];
        }
    }

    public function printingNum($flag)
    {
        if (!isset($this->record['printingNum'])) {
            if ($flag == 'insert') {
                $this->valueList['printingNum'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['printingNum']);
            }
        } else {
            $this->valueList['printingNum'] = $this->record['printingNum'];
        }
    }

    public function printingTime($flag)
    {
        if (!isset($this->record['printingTime'])) {
            if ($flag == 'insert') {
                $this->valueList['printingTime'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['printingTime']);
            }
        } else {
            $this->valueList['printingTime'] = $this->record['printingTime'];
        }
    }

    public function pageSize($flag)
    {
        if (!isset($this->record['pageSize'])) {
            if ($flag == 'insert') {
                $this->valueList['pageSize'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['pageSize']);
            }
        } else {
            $this->valueList['pageSize'] = $this->record['pageSize'];
        }
    }

    public function setNum($flag)
    {
        if (!isset($this->record['setNum'])) {
            if ($flag == 'insert') {
                $this->valueList['setNum'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['setNum']);
            }
        } else {
            $this->valueList['setNum'] = $this->record['setNum'];
        }
    }

    public function impression($flag)
    {
        if (!isset($this->record['impression'])) {
            if ($flag == 'insert') {
                $this->valueList['impression'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['impression']);
            }
        } else {
            $this->valueList['impression'] = $this->record['impression'];
        }
    }

    public function usedPaper($flag)
    {
        if (!isset($this->record['usedPaper'])) {
            if ($flag == 'insert') {
                $this->valueList['usedPaper'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['usedPaper']);
            }
        } else {
            $this->valueList['usedPaper'] = $this->record['usedPaper'];
        }
    }

    public function issn($flag)
    {
        if (!isset($this->record['issn'])) {
            if ($flag == 'insert') {
                $this->valueList['issn'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['issn']);
            }
        } else {
            $this->valueList['issn'] = $this->record['issn'];
        }
    }

    public function unifiedIsbn($flag)
    {
        if (!isset($this->record['unifiedIsbn'])) {
            if ($flag == 'insert') {
                $this->valueList['unifiedIsbn'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['unifiedIsbn']);
            }
        } else {
            $this->valueList['unifiedIsbn'] = $this->record['unifiedIsbn'];
        }
    }

    public function binding($flag)
    {
        if (!isset($this->record['binding'])) {
            if ($flag == 'insert') {
                $this->valueList['binding'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['binding']);
            }
        } else {
            $this->valueList['binding'] = $this->record['binding'];
        }
    }

    public function tag($flag)
    {
        if (!isset($this->record['tag'])) {
            if ($flag == 'insert') {
                $this->valueList['tag'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['tag']);
            }
        } else {
            $this->valueList['tag'] = $this->record['tag'];
        }
    }

    public function series($flag)
    {
        if (!isset($this->record['series'])) {
            if ($flag == 'insert') {
                $this->valueList['series'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['series']);
            }
        } else {
            $this->valueList['series'] = $this->record['series'];
        }
    }

    public function bookSize($flag)
    {
        if (!isset($this->record['bookSize'])) {
            if ($flag == 'insert') {
                $this->valueList['bookSize'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookSize']);
            }
        } else {
            $this->valueList['bookSize'] = $this->record['bookSize'];
        }
    }

    public function bookWeight($flag)
    {
        if (!isset($this->record['bookWeight'])) {
            if ($flag == 'insert') {
                $this->valueList['bookWeight'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bookWeight']);
            }
        } else {
            $this->valueList['bookWeight'] = $this->record['bookWeight'];
        }
    }

    public function normalImg($flag)
    {
        if (!isset($this->record['normalImg'])) {
            if ($flag == 'insert') {
                $this->valueList['normalImg'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['normalImg']);
            }
        } else {
            $this->valueList['normalImg'] = $this->record['normalImg'];
        }
    }

    public function smallImg($flag)
    {
        if (!isset($this->record['smallImg'])) {
            if ($flag == 'insert') {
                $this->valueList['smallImg'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['smallImg']);
            }
        } else {
            $this->valueList['smallImg'] = $this->record['smallImg'];
        }
    }

    public function bigImg($flag)
    {
        if (!isset($this->record['bigImg'])) {
            if ($flag == 'insert') {
                $this->valueList['bigImg'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['bigImg']);
            }
        } else {
            $this->valueList['bigImg'] = $this->record['bigImg'];
        }
    }

    public function authorId($flag)
    {
        if (!isset($this->record['authorId'])) {
            if ($flag == 'insert') {
                $this->valueList['authorId'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorId']);
            }
        } else {
            $this->valueList['authorId'] = $this->record['authorId'];
        }
    }

    public function authorName($flag)
    {
        if (!isset($this->record['authorName'])) {
            if ($flag == 'insert') {
                $this->valueList['authorName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorName']);
            }
        } else {
            $this->valueList['authorName'] = $this->fan2jian($this->record['authorName']);
        }
    }

    public function authorNamePinyin($flag)
    {
        if (!isset($this->record['authorNamePinyin'])) {
            if ($flag == 'insert') {
                $this->valueList['authorNamePinyin'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorNamePinyin']);
            }
        } else {
            $this->valueList['authorNamePinyin'] = $this->record['authorNamePinyin'];
        }
    }

    public function authorUrl($flag)
    {
        if (!isset($this->record['authorUrl'])) {
            if ($flag == 'insert') {
                $this->valueList['authorUrl'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorUrl']);
            }
        } else {
            $this->valueList['authorUrl'] = $this->record['authorUrl'];
        }
    }

    public function pressId($flag)
    {
        if (!isset($this->record['pressId'])) {
            if ($flag == 'insert') {
                $this->valueList['pressId'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['pressId']);
            }
        } else {
            $this->valueList['pressId'] = $this->record['pressId'];
        }
    }

    public function pressName($flag)
    {
        if (!isset($this->record['pressName'])) {
            if ($flag == 'insert') {
                $this->valueList['pressName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['pressName']);
            }
        } else {
            $this->valueList['pressName'] = $this->record['pressName'];
        }
    }

    public function pressUrl($flag)
    {
        if (!isset($this->record['pressUrl'])) {
            if ($flag == 'insert') {
                $this->valueList['pressUrl'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['pressUrl']);
            }
        } else {
            $this->valueList['pressUrl'] = $this->record['pressUrl'];
        }
    }

    public function lifeStory($flag)
    {
        if (!isset($this->record['lifeStory'])) {
            if ($flag == 'insert') {
                $this->valueList['lifeStory'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['lifeStory']);
            }
        } else {
            $this->valueList['lifeStory'] = $this->record['lifeStory'];
        }
    }

    public function authorPhoto($flag)
    {
        if (!isset($this->record['authorPhoto'])) {
            if ($flag == 'insert') {
                $this->valueList['authorPhoto'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorPhoto']);
            }
        } else {
            $this->valueList['authorPhoto'] = $this->record['authorPhoto'];
        }
    }

    public function jobId($flag)
    {
        if (!isset($this->record['jobId'])) {
            if ($flag == 'insert') {
                $this->valueList['jobId'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['jobId']);
            }
        } else {
            $this->valueList['jobId'] = $this->record['jobId'];
        }
    }

    public function jobName($flag)
    {
        if (!isset($this->record['jobName'])) {
            if ($flag == 'insert') {
                $this->valueList['jobName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['jobName']);
            }
        } else {
            $this->valueList['jobName'] = $this->record['jobName'];
        }
    }

    public function authorIds($flag)
    {
        if (!isset($this->record['authorIds'])) {
            if ($flag == 'insert') {
                $this->valueList['authorIds'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['authorIds']);
            }
        } else {
            $this->valueList['authorIds'] = $this->record['authorIds'];
        }
    }

    public function authorNames($flag)
    {
        if (!isset($this->record['authorNames'])) {
            if ($flag == 'insert') {
                $this->valueList['authorNames'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['authorNames']);
            }
        } else {
            $this->valueList['authorNames'] = $this->fan2jian($this->record['authorNames']);
        }
    }

    public function jobIds($flag)
    {
        if (!isset($this->record['jobIds'])) {
            if ($flag == 'insert') {
                $this->valueList['jobIds'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['jobIds']);
            }
        } else {
            $this->valueList['jobIds'] = $this->record['jobIds'];
        }
    }

    public function jobNames($flag)
    {
        if (!isset($this->record['jobNames'])) {
            if ($flag == 'insert') {
                $this->valueList['jobNames'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['jobNames']);
            }
        } else {
            $this->valueList['jobNames'] = $this->record['jobNames'];
        }
    }

    public function jcatId1($flag)
    {
        if (!isset($this->record['jcatId1'])) {
            if ($flag == 'insert') {
                $this->valueList['jcatId1'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['jcatId1']);
            }
        } else {
            $this->valueList['jcatId1'] = $this->record['jcatId1'];
        }
    }

    public function jcatId2($flag)
    {
        if (!isset($this->record['jcatId2'])) {
            if ($flag == 'insert') {
                $this->valueList['jcatId2'] = 0;
            }
            if ($flag == 'update') {
                unset($this->valueList['jcatId2']);
            }
        } else {
            $this->valueList['jcatId2'] = $this->record['jcatId2'];
        }
    }

    public function isdeleted($flag)
    {
        if (!isset($this->record['isdeleted'])) {
            if ($flag == 'insert') {
                $this->valueList['isdeleted'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['isdeleted']);
            }
        } else {
            $this->valueList['isdeleted'] = $this->record['isdeleted'];
        }
    }

    public function _bookName($flag)
    {
        if (!isset($this->record['_bookName'])) {
            if ($flag == 'insert') {
                $this->valueList['_bookName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_bookName']);
            }
        } else {
            $this->valueList['_bookName'] = $this->fan2jian($this->record['_bookName']);
        }
    }

    public function _catName($flag)
    {
        if (!isset($this->record['_catName'])) {
            if ($flag == 'insert') {
                $this->valueList['_catName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_catName']);
            }
        } else {
            $this->valueList['_catName'] = $this->record['_catName'];
        }
    }

    public function _author($flag)
    {
        if (!isset($this->record['_author'])) {
            if ($flag == 'insert') {
                $this->valueList['edition'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_author']);
            }
        } else {
            $this->valueList['author'] = $this->fan2jian($this->record['author']);
        }
    }

    public function _press($flag)
    {
        if (!isset($this->record['_press'])) {
            if ($flag == 'insert') {
                $this->valueList['_press'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_press']);
            }
        } else {
            $this->valueList['_press'] = $this->record['_press'];
        }
    }

    public function _pubDate($flag)
    {
        if (!isset($this->record['_pubDate'])) {
            if ($flag == 'insert') {
                $this->valueList['_pubDate'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_pubDate']);
            }
        } else {
            $this->valueList['_pubDate'] = $this->record['_pubDate'];
        }
    }

    public function _isbn($flag)
    {
        if (!isset($this->record['_isbn'])) {
            if ($flag == 'insert') {
                $this->valueList['_isbn'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_isbn']);
            }
        } else {
            $this->valueList['_isbn'] = $this->record['_isbn'];
        }
    }

    public function _tag($flag)
    {
        if (!isset($this->record['_tag'])) {
            if ($flag == 'insert') {
                $this->valueList['_tag'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_tag']);
            }
        } else {
            $this->valueList['_tag'] = $this->record['_tag'];
        }
    }

    public function _jobName($flag)
    {
        if (!isset($this->record['_jobName'])) {
            if ($flag == 'insert') {
                $this->valueList['_jobName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_jobName']);
            }
        } else {
            $this->valueList['_jobName'] = $this->record['_jobName'];
        }
    }

    public function _authorIds($flag)
    {
        if (!isset($this->record['_authorIds'])) {
            if ($flag == 'insert') {
                $this->valueList['_authorIds'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_authorIds']);
            }
        } else {
            $this->valueList['_authorIds'] = $this->record['_authorIds'];
        }
    }

    public function _authorNames($flag)
    {
        if (!isset($this->record['_authorNames'])) {
            if ($flag == 'insert') {
                $this->valueList['_authorNames'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_authorNames']);
            }
        } else {
            $this->valueList['_authorNames'] = $this->fan2jian($this->record['_authorNames']);
        }
    }

    public function _jobIds($flag)
    {
        if (!isset($this->record['_jobIds'])) {
            if ($flag == 'insert') {
                $this->valueList['_jobIds'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_jobIds']);
            }
        } else {
            $this->valueList['_jobIds'] = $this->record['_jobIds'];
        }
    }

    public function _jobNames($flag)
    {
        if (!isset($this->record['_jobNames'])) {
            if ($flag == 'insert') {
                $this->valueList['_jobNames'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_jobNames']);
            }
        } else {
            $this->valueList['_jobNames'] = $this->record['_jobNames'];
        }
    }

    public function _authorName($flag)
    {
        if (!isset($this->record['_authorName'])) {
            if ($flag == 'insert') {
                $this->valueList['_authorName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_authorName']);
            }
        } else {
            $this->valueList['_authorName'] = $this->fan2jian($this->record['_authorName']);
        }
    }

    public function _pressName($flag)
    {
        if (!isset($this->record['_pressName'])) {
            if ($flag == 'insert') {
                $this->valueList['_pressName'] = '';
            }
            if ($flag == 'update') {
                unset($this->valueList['_pressName']);
            }
        } else {
            $this->valueList['_pressName'] = $this->record['_pressName'];
        }
    }

    /**
     * Set field value
     * @param $flag
     */
    public function setValueList($flag)
    {
        $this->bookId();
        $this->uniqueMd5($flag);
        $this->bookName($flag);
        $this->bookNamePinyin($flag);
        $this->catName($flag);
        $this->catId($flag);
        $this->price($flag);
        $this->author($flag);
        $this->press($flag);
        $this->pubDate($flag);
        $this->edition($flag);
        $this->isbn($flag);
        $this->certifyStatus($flag);
        $this->zcatId($flag);
        $this->editorComment($flag);
        $this->contentIntroduction($flag);
        $this->directory($flag);
        $this->illustration($flag);
        $this->description($flag);
        $this->bookForeign($flag);
        $this->area($flag);
        $this->language($flag);
        $this->originalLanguage($flag);
        $this->catAgency($flag);
        $this->wordNum($flag);
        $this->pageNum($flag);
        $this->printingNum($flag);
        $this->printingTime($flag);
        $this->pageSize($flag);
        $this->setNum($flag);
        $this->impression($flag);
        $this->usedPaper($flag);
        $this->issn($flag);
        $this->unifiedIsbn($flag);
        $this->binding($flag);
        $this->tag($flag);
        $this->series($flag);
        $this->bookSize($flag);
        $this->bookWeight($flag);
        $this->normalImg($flag);
        $this->smallImg($flag);
        $this->bigImg($flag);
        $this->authorId($flag);
        $this->authorName($flag);
        $this->authorNamePinyin($flag);
        $this->authorUrl($flag);
        $this->pressId($flag);
        $this->pressName($flag);
        $this->pressUrl($flag);
        $this->lifeStory($flag);
        $this->authorPhoto($flag);
        $this->jobId($flag);
        $this->jobName($flag);
        $this->authorIds($flag);
        $this->authorNames($flag);
        $this->jobIds($flag);
        $this->jobNames($flag);
        $this->jcatId1($flag);
        $this->jcatId2($flag);
        $this->isdeleted($flag);
        $this->_bookName($flag);
        $this->_catName($flag);
        $this->_author($flag);
        $this->_press($flag);
        $this->_pubDate($flag);
        $this->_isbn($flag);
        $this->_tag($flag);
        $this->_jobName($flag);
        $this->_authorIds($flag);
        $this->_authorNames($flag);
        $this->_jobIds($flag);
        $this->_jobNames($flag);
        $this->_authorName($flag);
        $this->_pressName($flag);
    }

    public function getValueList()
    {
        //大小写转换
        foreach ($this->valueList as $k => $v) {
            $lower_k = strtolower($k);
            if ($k === $lower_k) {
                continue;
            }
            $this->valueList[$lower_k] = $v;
            unset($this->valueList[$k]);
        }
        return $this->valueList;
    }

    // 此方法依赖于mbstring扩展。
    private function fan2jian($value)
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