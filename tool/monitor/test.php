<?php
    require_once 'monitor.php';
    
    $result = MonitorModel::sendMsg('测试');
    var_dump($result);
?>