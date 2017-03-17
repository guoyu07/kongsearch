<?php

/**
 * Created by diao
 * Date: 16-8-30
 * Time: 上午9:44
 */
require 'models/BooklibModel.php';

class indexupdate_es_booklib
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
        $booklibMode = new BooklibModel($msg['data']);
        $booklibMode->setValueList('insert');
        return $booklibMode->getValueList();
    }

    /**
     * Data update
     * @param $msg
     * @return array
     */
    public function dealUp($msg)
    {
        $booklibMode = new BooklibModel($msg['data']);
        $booklibMode->setValueList('update');
        return $booklibMode->getValueList();
    }
}