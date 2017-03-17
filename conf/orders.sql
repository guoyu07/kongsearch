CREATE DATABASE IF NOT EXISTS search;
use search;
DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;
delimiter $$

CREATE PROCEDURE drop_table(tablename VARCHAR(255))
BEGIN
DECLARE s VARCHAR(8192);
SET s = CONCAT_WS('','DROP TABLE IF EXISTS ',tableName, ";");
SET @ss = s;
prepare stmt from @ss;
execute stmt;
deallocate prepare stmt;
END$$

CREATE PROCEDURE create_table(tablename VARCHAR(255))
BEGIN
DECLARE s VARCHAR(8192);
SET s = CONCAT_WS('','CREATE TABLE IF NOT EXISTS ',tableName,"(
`orderId`  int(11) UNSIGNED NOT NULL,
`pid`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`shopId` int(11) UNSIGNED NOT NULL DEFAULT 0,
`bizType` tinyint(1) UNSIGNED NOT NULL DEFAULT 1,
`isdeleted` tinyint(1) unsigned NOT NULL,
`shopName` varchar(60) NOT NULL,
`shopkeeperId` int(11) UNSIGNED NOT NULL DEFAULT 0,
`userId` int(11) UNSIGNED NOT NULL DEFAULT 0,
`nickname` varchar(60) NOT NULL,
`orderStatus` tinyint(1) UNSIGNED NOT NULL,
`goodsAmount` decimal(10,2) UNSIGNED NOT NULL,
`favorableMoney` decimal(10,2) NOT NULL,
`createdTime` int(11) NOT NULL DEFAULT 0,
`shippingId` tinyint(1) UNSIGNED NOT NULL,
`shippingFee` decimal(10,2) UNSIGNED NOT NULL,
`payId` smallint(4) NOT NULL DEFAULT 0,
`buyerReviewed` tinyint(1) NOT NULL DEFAULT 0,
`sellerReviewed` tinyint(1) NOT NULL DEFAULT 0,
`applyRefundStatus` tinyint(1) UNSIGNED NOT NULL,
`applyRefundTime` int(11) UNSIGNED NOT NULL DEFAULT 0,
`orderMessage` varchar(255),
`isRemove` tinyint(1) NOT NULL DEFAULT 0,
`allAmount` decimal(10,2) UNSIGNED NOT NULL,
`date` char(10),
`month` char(10),
`payStatus` tinyint(1) UNSIGNED NOT NULL,
`shippingStatus` tinyint(1) UNSIGNED NOT NULL,
`sellerConfirmedTime` int(11) NOT NULL DEFAULT 0,
`startPayTime` int(11) NOT NULL DEFAULT 0,
`payTime` int(11) NOT NULL DEFAULT 0,
`shippingTime` int(11) NOT NULL DEFAULT 0,
`receivedTime` int(11) NOT NULL DEFAULT 0,
`finishTime` int(11) NOT NULL DEFAULT 0,
`shippingComCode` varchar(30),
`shippingCom` varchar(60),
`shippingTel` varchar(60),
`shipmentNum` varchar(60),
`moneyOrderNum` varchar(30),
`logisticFlowId` varchar(20),
`delay` tinyint(4) UNSIGNED NOT NULL DEFAULT 0,
`receiverName` varchar(30),
`phoneNum` varchar(30),
`mobile` varchar(30),
`email` varchar(60),
`area` bigint(12) UNSIGNED NOT NULL DEFAULT 0,
`address` varchar(210),
`zipCode` varchar(30),
`items` longtext,
`itemIds` text,
`itemNames` text,
`_shopName` varchar(120),
`_nickname` varchar(120),
`_receiverName` varchar(60),
`_phoneNum` varchar(30),
`_mobile` varchar(30),
`_itemIds` text,
`_itemNames` text,
PRIMARY KEY (`orderId`),
UNIQUE `pid` (`pid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;
");
SET @ss = s;
prepare stmt from @ss;
execute stmt;
deallocate prepare stmt;
END$$

CREATE PROCEDURE create_tables(tablename VARCHAR(255), beg INT, num INT)
BEGIN
DECLARE n INT;
DECLARE t VARCHAR(255);
SET n = beg;
SET t = '';
myloop: REPEAT
   SET t = CONCAT_WS('',tablename,n);
   CALL drop_table(t);
   CALL create_table(t);
   SET n = n + 1;
UNTIL n >= num END REPEAT;
END$$

delimiter ;
CALL create_tables('orders_',0,16);
CALL drop_table('orders_new');
CALL create_table('orders_new');

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;