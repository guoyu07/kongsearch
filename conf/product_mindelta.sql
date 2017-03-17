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
`itemId`  bigint(18) UNSIGNED NOT NULL,
`pid`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`bizType` tinyint(1) unsigned NOT NULL,
`userId` int(11) unsigned NOT NULL,
`catId` bigint(18) unsigned NOT NULL,
`catId1` bigint(18) unsigned NOT NULL,
`catId2` bigint(18) unsigned NOT NULL,
`catId3` bigint(18) unsigned NOT NULL,
`catId4` bigint(18) unsigned NOT NULL,
`_catId` bigint(18) unsigned NOT NULL,
`_catId1` bigint(18) unsigned NOT NULL,
`_catId2` bigint(18) unsigned NOT NULL,
`_catId3` bigint(18) unsigned NOT NULL,
`_catId4` bigint(18) unsigned NOT NULL,
`vcatId` bigint(18) unsigned NOT NULL,
`vcatId1` bigint(18) unsigned NOT NULL,
`vcatId2` bigint(18) unsigned NOT NULL,
`vcatId3` bigint(18) unsigned NOT NULL,
`vcatId4` bigint(18) unsigned NOT NULL,
`_vcatId` bigint(18) unsigned NOT NULL,
`_vcatId1` bigint(18) unsigned NOT NULL,
`_vcatId2` bigint(18) unsigned NOT NULL,
`_vcatId3` bigint(18) unsigned NOT NULL,
`_vcatId4` bigint(18) unsigned NOT NULL,
`catId1g`  varchar(60) NULL DEFAULT NULL ,
`itemName`  varchar(180)  NOT NULL ,
`author`  varchar(90) NULL DEFAULT NULL ,
`author2`  varchar(90) NULL DEFAULT NULL ,
`press`  varchar(60) NULL DEFAULT NULL ,
`press2`  varchar(60) NULL DEFAULT NULL ,
`_itemName`  varchar(512)  NOT NULL ,
`_author`  varchar(180) NULL DEFAULT NULL ,
`_press`  varchar(180) NULL DEFAULT NULL ,
`x_itemName`  varchar(512)  NULL DEFAULT NULL,
`x_author`  varchar(180) NULL DEFAULT NULL ,
`x_press`  varchar(180) NULL DEFAULT NULL ,
`isbn`  varchar(60) NULL DEFAULT NULL ,
`price` decimal(10,2) NOT NULL DEFAULT '0.00',
`pubDate`  int(11) UNSIGNED NULL DEFAULT NULL ,
`pubDate2` int(11) UNSIGNED NULL DEFAULT NULL ,
`years` varchar(20) NOT NULL DEFAULT '',
`years2`  tinyint(1) unsigned NOT NULL,
`discount` tinyint(3) NOT NULL DEFAULT '100',
`number` smallint(4) NOT NULL DEFAULT '0',
`quality` tinyint(3) NOT NULL DEFAULT '0',
`addTime` int(11) NOT NULL DEFAULT '0',
`updateTime` int(11) NOT NULL DEFAULT '0',
`reCertifyStatus` tinyint(1) unsigned NOT NULL DEFAULT '0',
`approach` tinyint(1) NOT NULL DEFAULT '0',
`imgUrl`  varchar(255) NULL DEFAULT NULL ,
`hasImg` tinyint(1) unsigned NOT NULL,
`tag`  varchar(1024) NULL DEFAULT NULL ,
`_tag`  varchar(1024) NULL DEFAULT NULL ,
`nickname` char(60) NOT NULL,
`shopName` char(60) NOT NULL DEFAULT '',
`_nickname` char(120) NOT NULL,
`_shopName` char(120) NOT NULL DEFAULT '',
`shopId` int(11) unsigned NOT NULL,
`area` bigint(12) NOT NULL DEFAULT '0',
`area1` bigint(12) NOT NULL DEFAULT '0',
`area2` bigint(12) NOT NULL DEFAULT '0',
`class` smallint(4) NOT NULL DEFAULT '0',
`shopStatus` tinyint(1) unsigned NOT NULL,
`isdeleted` tinyint(1) unsigned NOT NULL,
`saleStatus`  tinyint(1) unsigned NOT NULL,
`certifyStatus` tinyint(1) unsigned NOT NULL,
`olReceiveType` tinyint(1) unsigned NOT NULL,
`params` varchar(1000) NOT NULL DEFAULT '',
`itemDesc` text NULL,
`iauthor` bigint(18) unsigned NOT NULL,
`ipress` bigint(18) unsigned NOT NULL,
`paper`  int(11) UNSIGNED NULL DEFAULT NULL ,
`printType`  int(11) UNSIGNED NULL DEFAULT NULL ,
`binding`  int(11) UNSIGNED NULL DEFAULT NULL ,
`sort`  int(11) UNSIGNED NULL DEFAULT NULL ,
`material`  int(11) UNSIGNED NULL DEFAULT NULL ,
`form`  int(11) UNSIGNED NULL DEFAULT NULL ,
`rank`  int(11) UNSIGNED NOT NULL DEFAULT '0',
`trust` tinyint(1) NOT NULL DEFAULT '0',
`isautoverify` tinyint(1) unsigned NOT NULL,
`istrustshop` tinyint(1) unsigned NOT NULL,
`flag1` tinyint(1) unsigned NOT NULL,
`flag2` tinyint(1) unsigned NOT NULL,
PRIMARY KEY (`itemId`),
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
CALL create_tables('product_mindelta_',0,32);

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;
