<?php

require_once 'convertor.php';

date_default_timezone_set('Asia/Chongqing');

class orders extends Convertor
{
    private $cache;
    private $expire;
    private $dbUser;
    private $dbPwd;
    private $orderPDO;
    private $mapPDO;

    public function __construct($dataType, $gatherMode, $args) 
    {
        parent::__construct($dataType, $gatherMode);
        $this->cache = NULL;
        
        if(empty($args)) 
            throw new Exception ('convert arguments is empty');
        
        if(isset($args['DB.orders']) && !empty($args['DB.orders']))
            $orderDB = explode(':', $args['DB.orders']);
        else 
            throw new Exception ('DB.orders set error in [convert]');
        
        if(isset($args['DB.map']) && !empty($args['DB.map']))
            $mapDB = explode(':', $args['DB.map']);
        else 
            throw new Exception ('DB.map set error in [convert]');
        
        if(isset($args['cache']) && !empty($args['cache']))
            $cache = explode(':', $args['cache']);
        else 
            throw new Exception ('cache set error in [convert]');
       
        // 连接order DB，采用持久连接减少连接数。
        try {
            $dsn = 'mysql:' . 'host=' . $orderDB[0] . ';' . 'port=' . $orderDB[1] . ';' . 'dbname=' . $orderDB[4] . ';' . 'charset=utf8';
            if($this->gatherMode == 0) { // rebuild mode 
                $this->orderPDO = new PDO($dsn, $orderDB[2], $orderDB[3], array(PDO::ATTR_PERSISTENT => false));
                $this->orderPDO->query("SET SESSION wait_timeout=28800");
            } else { // update mode
                $this->orderPDO = new PDO($dsn, $orderDB[2], $orderDB[3], array(PDO::ATTR_PERSISTENT => true));
            }
            $this->orderPDO->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            throw new Exception($this->errorInfo);
        }
        
        // 连接map DB，采用持久连接减少连接数。
        try {
            $dsn = 'mysql:' . 'host=' . $mapDB[0] . ';' . 'port=' . $mapDB[1] . ';' . 'dbname=' . $mapDB[4] . ';' . 'charset=utf8';
            if($this->gatherMode == 0) { // rebuild mode 
                $this->mapPDO = new PDO($dsn, $mapDB[2], $mapDB[3], array(PDO::ATTR_PERSISTENT => false));
                $this->mapPDO->query("SET SESSION wait_timeout=28800");
            } else { // update mode
                $this->mapPDO = new PDO($dsn, $mapDB[2], $mapDB[3], array(PDO::ATTR_PERSISTENT => true));
            }
            $this->mapPDO->query("SET NAMES utf8");
        } catch (PDOException $e) {
            $this->errorInfo = $e->getMessage();
            throw new Exception($this->errorInfo);
        }
        
        // 连接redis cache
        $this->cache = new Redis();
        $conn = $this->cache->pconnect($cache[0], $cache[1]);
        if($conn === false) {
            $this->cache = NULL;
            $this->errorInfo = "connect cache server [{$cache[0]}:{$cache[1]}] failure.";
            throw new Exception($this->errorInfo);
        }
        $this->expire = $cache[2];
        
        
    }
    
    public function __destruct() 
    {
        if($this->cache !== NULL) {
            $this->cache->close();
        }
 
        if($this->gatherMode == 0) { // rebuild mode
            $this->orderPDO = NULL;
            $this->mapPDO = NULL;
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
    
    public function orderId($value)
    {
        $this->record['orderId'] = $value;
        return $value;
    }
    
    public function shopId($value)
    {
        $this->record['shopId'] = $value;
        $shopInfoResult = $this->getShopInfo();
        if ($shopInfoResult === false && $this->record['shopInfo'] === -1) { //如果没有相应店铺shopInfo，则过滤
            return array();
        } else if ($shopInfoResult === false && $this->record['shopInfo'] === -2) {
            return false;
        }
        return $value;
    }
    
    public function getShopInfo()
    {
        $shopInfo = NULL;
        $key = 'orderSearch_shopInfo:'. $this->record['shopId'];
        if($this->cache !== NULL) {
            $value = $this->cache->get($key);
            if($value !== false) {
                $shopInfo = unserialize($value);
            }
        }
        if($shopInfo == NULL) {
            $table = 'shopInfo';
            $sql = "SELECT * FROM ". $table. " WHERE shopId='". $this->record['shopId']. "'";
            $result = $this->mapPDO->query($sql);
            if ($result === false) {
                $e = $this->mapPDO->errorInfo();
                $this->errorInfo = $e[2];
                $this->record['shopInfo'] = -2;
                return false;
            }
            $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
            if(empty($resultset)) {
                $this->record['shopInfo'] = -1;
                return false;
            }
            $shopInfo = $resultset[0];
            // 把结果存到cache，并设置过期时间
            if($this->cache !== NULL) {
                $value = serialize($shopInfo);
                $this->cache->set($key,$value);
                $this->cache->expire($key, $this->expire);
            }
        }

        $this->record['shopInfo'] = $shopInfo;
    }
    
    public function bizType($value)
    {
        if($this->record['shopInfo']['shopType'] == 'shop') {
            return 1;
        } else {
            return 2;
        }
    }
    
    public function shopkeeperId($value)
    {
        $this->record['shopkeeperId'] = $value;
        if($this->setTableId() === false && $this->record['tableId'] === -1) { //如果没有对应表ID，则过滤
            return array();
        }
//        $this->record['tableId'] = 1;
        
        $orderOtherInfoResult = $this->getOrderOtherInfo();
        if ($orderOtherInfoResult === false && $this->record['orderOtherInfo'] === -1) { //如果没有相应订单otherOtherInfo，则过滤
            return array();
        } else if ($orderOtherInfoResult === false && $this->record['orderOtherInfo'] === -2) {
            return false;
        }
        
        $orderReceiverInfoResult = $this->getOrderReceiverInfo();
        if($orderReceiverInfoResult === false && $this->record['orderReceiverInfo'] === -1) { //如果没有相应订单orderReceiverInfo，则过滤
            return array();
        } else if($orderReceiverInfoResult === false && $this->record['orderReceiverInfo'] === -2) {
            return false;
        }
        
        $orderItemsResult = $this->getOrderItems();
        if($orderItemsResult === false && $this->record['orderItems'] === -1) { //如果没有相应订单orderItems，则过滤
            return array();
        } else if($orderItemsResult === false && $this->record['orderItems'] === -2) {
            return false;
        }
        return $value;
    }
    
    private function setTableId()
    {
        $shopkeeperId = $this->record['shopkeeperId'];
        $sql = "SELECT tableId FROM sellerOrderMap WHERE userId='$shopkeeperId'";
        $result = $this->orderPDO->query($sql);
        if($result === false) {
            $e = $this->orderPDO->errorInfo();
            $this->errorInfo = $e[2];
            $this->record['tableId'] = -2;
            return false;
        }
        
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['tableId'] = -1;
            return false;
        }
        
        $this->record['tableId'] = $resultset[0]['tableId'];
    }
    
    //获取orderOtherInfo表
    private function getOrderOtherInfo()
    {
        $table = 'sellerOrderOtherInfo_'. $this->record['tableId'];
        $sql = "SELECT * FROM ". $table. " WHERE orderId='". $this->record['orderId']. "'";
        $result = $this->orderPDO->query($sql);
        if ($result === false) {
            $e = $this->orderPDO->errorInfo();
            $this->errorInfo = $e[2];
            $this->record['orderOtherInfo'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['orderOtherInfo'] = -1;
            return false;
        }
            
        $this->record['orderOtherInfo'] = $resultset[0];
    }
    
    //获取orderReceiverInfo表
    private function getOrderReceiverInfo()
    {
        $table = 'sellerOrderReceiverInfo_'. $this->record['tableId'];
        $sql = "SELECT * FROM ". $table. " WHERE orderId='". $this->record['orderId']. "'";
        $result = $this->orderPDO->query($sql);
        if ($result === false) {
            $e = $this->orderPDO->errorInfo();
            $this->errorInfo = $e[2];
            $this->record['orderReceiverInfo'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['orderReceiverInfo'] = -1;
            return false;
        }
            
        $this->record['orderReceiverInfo'] = $resultset[0];
    }
    
    //获取orderItems表
    private function getOrderItems()
    {
        $table = 'sellerOrderItems_'. $this->record['tableId'];
        $sql = "SELECT * FROM ". $table. " WHERE orderId='". $this->record['orderId']. "'";
        $result = $this->orderPDO->query($sql);
        if ($result === false) {
            $e = $this->orderPDO->errorInfo();
            $this->errorInfo = $e[2];
            $this->record['orderItems'] = -2;
            return false;
        }
        $resultset = $result->fetchAll(PDO::FETCH_ASSOC);
        if(empty($resultset)) {
            $this->record['orderItems'] = -1;
            return false;
        }
        
        $itemIds = '';
        $itemNames = '';
        foreach($resultset as $item) {
            $itemIds .= '|'. $item['itemId'];
            $itemNames .= '|'. $item['itemName'];
        }
        $this->record['itemIds'] = trim($itemIds, '|');
        $this->record['itemNames'] = trim($itemNames, '|');
        $this->record['items'] = json_encode($resultset);
    }
    
    public function shippingId($value)
    {
        switch($value) {
            case 'registerPost':
                return 0;
            case 'express':
                return 1;
            case 'ems':
                return 2;
            case 'logistics':
                return 3;
            case 'noLogistics':
                return 4;
            default:
                return '';
        }
    }
    
    public function orderStatus($value)
    {
        switch($value) {
            case 'Pending':
                return 0;
            case 'BuyerCancelledBeforeConfirm':
                return 1;
            case 'SellerCancelledBeforeConfirm':
                return 2;
            case 'AdminClosedBeforeConfirm':
                return 3;
            case 'ConfirmedToPay':
                return 4;
            case 'BuyerCancelledBeforePay':
                return 5;
            case 'SellerClosedBeforePay':
                return 6;
            case 'PaidToConfirm':
                return 7;
            case 'PaidToShip':
                return 8;
            case 'Paid-Refunding':
                return 9;
            case 'Paid-RefundRejected':
                return 10;
            case 'PaidRefunded':
                return 11;
            case 'ShippedToReceipt':
                return 12;
            case 'Shipped-Returning':
                return 13;
            case 'Shipped-ReturnRejected':
                return 14;
            case 'Shipped-Refunding':
                return 15;
            case 'Shipped-RefundRejected':
                return 16;
            case 'ReturnPending':
                return 17;
            case 'ReturnedToReceipt':
                return 18;
            case 'ShippedRefunded':
                return 19;
            case 'ShippedReturned':
                return 20;
            case 'Successful':
                return 21;
            default:
                return '';
        }
    }
    
    public function applyRefundStatus($value)
    {
        switch($value) {
            case 'Refunding':
                return 0;
            case 'RefundRejected':
                return 1;
            case 'Refunded':
                return 2;
            case 'Returning':
                return 3;
            case 'ReturnRejected':
                return 4;
            case 'ReturnPending':
                return 5;
            case 'ReturnedToReceipt':
                return 6;
            case 'ShippedReturned':
                return 7;
            case 'BuyerCancelled':
                return 8;
            case 'BuyerCancelledReturn':
                return 9;
            case 'SysClosedRefund':
                return 10;
            case 'SysClosedReturn':
                return 11;
            case 'CustomerServiceIntervention':
                return 12;
            default:
                return '';
        }
    }
    
    public function goodsAmount($value)
    {
        $this->record['goodsAmount'] = $value;
        return $value;
    }
    
    public function favorableMoney($value)
    {
        $this->record['favorableMoney'] = $value;
        return $value;
    }
    
    public function shippingFee($value)
    {
        $this->record['shippingFee'] = $value;
        return $value;
    }
    
    public function createdTime($value)
    {
        $this->record['createdTime'] = $value;
        return $value;
    }
    
    public function allAmount($value)
    {
        return $this->record['goodsAmount'] - $this->record['favorableMoney'] + $this->record['shippingFee'];
    }
    
    public function date($value)
    {
        return date('Y-m-d', $this->record['createdTime']);
    }
    
    public function month($value)
    {
        return date('Y-m', $this->record['createdTime']);
    }
    
    
    public function payStatus($value)
    {
        switch($this->record['orderOtherInfo']['payStatus']) {
            case 'notPay':
                return 0;
            case 'hasPay':
                return 1;
            case 'hasReceivables':
                return 2;
            case 'hasRefund':
                return 3;
            default:
                return '';
        }
    }
    
    public function shippingStatus($value)
    {
        switch($this->record['orderOtherInfo']['shippingStatus']) {
            case 'notShipment':
                return 0;
            case 'hasShipment':
                return 1;
            case 'hasReceipt':
                return 2;
            case 'hasReturns':
                return 3;
            default:
                return '';
        }
    }
    
    public function sellerConfirmedTime($value)
    {
        return $this->record['orderOtherInfo']['sellerConfirmedTime'];
    }
    
    public function startPayTime($value)
    {
        return $this->record['orderOtherInfo']['startPayTime'];
    }
    
    public function payTime($value)
    {
        return $this->record['orderOtherInfo']['payTime'];
    }
    
    public function shippingTime($value)
    {
        return $this->record['orderOtherInfo']['shippingTime'];
    }
    
    public function receivedTime($value)
    {
        return $this->record['orderOtherInfo']['receivedTime'];
    }
    
    public function finishTime($value)
    {
        return $this->record['orderOtherInfo']['finishTime'];
    }
    
    public function shippingComCode($value)
    {
        return $this->record['orderOtherInfo']['shippingComCode'];
    }
    
    public function shippingCom($value)
    {
        return $this->record['orderOtherInfo']['shippingCom'];
    }
    
    public function shippingTel($value)
    {
        return $this->record['orderOtherInfo']['shippingTel'];
    }
    
    public function shipmentNum($value)
    {
        return $this->record['orderOtherInfo']['shipmentNum'];
    }
    
    public function moneyOrderNum($value)
    {
        return $this->record['orderOtherInfo']['moneyOrderNum'];
    }
    
    public function logisticFlowId($value)
    {
        return $this->record['orderOtherInfo']['logisticFlowId'];
    }
    
    public function delay($value)
    {
        return $this->record['orderOtherInfo']['delay'];
    }
    
    
    public function receiverName($value)
    {
        return $this->record['orderReceiverInfo']['receiverName'];
    }
    
    public function _receiverName($value)
    {
        return $this->record['orderReceiverInfo']['receiverName'];
    }
    
    public function phoneNum($value)
    {
        return $this->record['orderReceiverInfo']['phoneNum'];
    }
    
    public function _phoneNum($value)
    {
        return $this->record['orderReceiverInfo']['phoneNum'];
    }
    
    public function mobile($value)
    {
        return $this->record['orderReceiverInfo']['mobile'];
    }
    
    public function _mobile($value)
    {
        return $this->record['orderReceiverInfo']['mobile'];
    }
    
    public function email($value)
    {
        return $this->record['orderReceiverInfo']['email'];
    }
    
    public function area($value)
    {
        return $this->record['orderReceiverInfo']['area'];
    }
    
    public function address($value)
    {
        return $this->record['orderReceiverInfo']['address'];
    }
    
    public function zipCode($value)
    {
        return $this->record['orderReceiverInfo']['zipCode'];
    }
    
    
    public function items($value)
    {
        return $this->record['items'];
    }
    public function itemIds($value)
    {
        return $this->record['itemIds'];
    }
    
    public function _itemIds($value)
    {
        if(isset($this->record['itemIds'])) {
            return $this->record['itemIds'];
        } else {
            return $value;
        }
    }
    
    public function itemNames($value)
    {
        return $this->record['itemNames'];
    }
    
    public function _itemNames($value)
    {
        if(isset($this->record['itemNames'])) {
            return $this->record['itemNames'];
        } else {
            return $value;
        }
    }
    
}

?>