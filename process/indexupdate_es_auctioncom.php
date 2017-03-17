<?php
require 'models/AuctioncomModel.php';

/**
 * Created by diao.
 * Date: 16-9-13
 * Time: 下午4:34
 */
class indexupdate_es_auctioncom
{
    public function __construct($config)
    {
        $this->errorInfo = '';
    }

    public function getErrorInfo()
    {
        return $this->errorInfo;
    }

    /**
     * Data insert
     * @param $msg
     * @return array
     */
    public function deal($msg)
    {
        $auctioncomModel = new AuctioncomModel($msg['data']);
        $auctioncomModel->setValueList('insert');
        return $auctioncomModel->getValueList();
    }

    /**
     * Data update
     * @param $msg
     * @return array
     */
    public function dealUp($msg)
    {
        $auctioncomModel = new AuctioncomModel($msg['data']);
        $auctioncomModel->setValueList('update');
        return $auctioncomModel->getValueList();
    }
}