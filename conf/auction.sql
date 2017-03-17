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
`userId` int(11) unsigned NOT NULL,
`auctionArea` tinyint(3) unsigned NOT NULL,
`specialArea` int(11) unsigned NOT NULL,
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
`quality` tinyint(3) NOT NULL DEFAULT '0',
`itemName`  varchar(180)  NOT NULL ,
`nickname` char(60) NOT NULL,
`author`  varchar(90) NULL DEFAULT NULL ,
`author2`  varchar(90) NULL DEFAULT NULL ,
`press`  varchar(60) NULL DEFAULT NULL ,
`press2`  varchar(60) NULL DEFAULT NULL ,
`img`  varchar(255) NULL DEFAULT NULL ,
`hasImg` tinyint(1) unsigned NOT NULL,
`params` varchar(1000) NOT NULL DEFAULT '',
`iauthor` bigint(18) unsigned NOT NULL,
`ipress` bigint(18) unsigned NOT NULL,
`_itemName`  varchar(512)  NOT NULL ,
`_nickname` char(120) NOT NULL,
`_author`  varchar(180) NULL DEFAULT NULL ,
`_press`  varchar(180) NULL DEFAULT NULL ,
`pubDate`  int(11) UNSIGNED NULL DEFAULT NULL ,
`pubDate2` int(11) UNSIGNED NULL DEFAULT NULL ,
`preStartTime` int(11) UNSIGNED NOT NULL DEFAULT '0',
`beginTime` int(11) UNSIGNED NOT NULL DEFAULT '0',
`endTime` int(11) UNSIGNED NOT NULL DEFAULT '0',
`beginPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`minAddPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`isCreateTrade` tinyint(3) NOT NULL DEFAULT '0',
`itemStatus` tinyint(3) NOT NULL DEFAULT '0',
`isdeleted` tinyint(1) unsigned NOT NULL,
`addTime` int(11) NOT NULL DEFAULT '0',
`viewedNum` int(11) UNSIGNED NOT NULL DEFAULT '0',
`bidNum` int(11) UNSIGNED NOT NULL DEFAULT '0',
`maxPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`rank`  int(11) UNSIGNED NOT NULL DEFAULT '0',
`isbn`  varchar(60) NULL DEFAULT NULL ,
`paper`  int(11) UNSIGNED NULL DEFAULT NULL ,
`printType`  int(11) UNSIGNED NULL DEFAULT NULL ,
`binding`  int(11) UNSIGNED NULL DEFAULT NULL ,
`sort`  int(11) UNSIGNED NULL DEFAULT NULL ,
`material`  int(11) UNSIGNED NULL DEFAULT NULL ,
`form`  int(11) UNSIGNED NULL DEFAULT NULL ,
`years` varchar(20) NOT NULL DEFAULT '',
`years2`  tinyint(1) unsigned NOT NULL,
`area` bigint(12) NULL DEFAULT '0',
`area1` bigint(12) NOT NULL DEFAULT '0',
`area2` bigint(12) NOT NULL DEFAULT '0',
`class` smallint(4) NULL DEFAULT '0',
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
CALL create_tables('auction_',0,2);
CALL drop_table('auction_new');
CALL create_table('auction_new');

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;
