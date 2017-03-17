<?php
require 'models/ShufangModel.php';

/**
 * Created by PhpStorm.
 * User: diao
 * Date: 16-9-23
 * Time: 上午9:57
 */
class indexupdate_es_shufang
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
        $shufangModel = new ShufangModel($msg['data']);
        $shufangModel->setValueList('insert');
        return $shufangModel->getValueList();
    }

    /**
     * Data update
     * @param $msg
     * @return array
     */
    public function dealUp($msg)
    {
        $shufangModel = new ShufangModel($msg['data']);
        $shufangModel->setValueList('update');
        return $shufangModel->getValueList();
    }
}