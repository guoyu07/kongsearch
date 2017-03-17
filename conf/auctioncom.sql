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
`comId` int(11) unsigned NOT NULL,
`comName`  varchar(180)  NOT NULL ,
`userId` int(11) unsigned NOT NULL,
`cusId` int(11) unsigned NOT NULL,
`itemName`  varchar(180)  NOT NULL ,
`catId` int(11) unsigned NOT NULL,
`author`  varchar(60) NULL DEFAULT NULL ,
`decade`  varchar(180) NULL DEFAULT NULL ,
`beginPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`beginRefPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`endRefPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`bargainPrice` decimal(10,2) NOT NULL DEFAULT '0.00',
`bigImg`  varchar(255) NULL DEFAULT NULL ,
`isHidden` tinyint(1) unsigned NOT NULL,
`viewedNum` int(11) unsigned NOT NULL,
`speId` int(11) unsigned NOT NULL,
`isdeleted` tinyint(1) unsigned NOT NULL,
`beginTime` int(11) UNSIGNED NOT NULL DEFAULT '0',
`beginTime2` int(11) UNSIGNED NOT NULL DEFAULT '0',
`_itemName`  varchar(512)  NOT NULL ,
`_decade` char(180) NOT NULL,
`_comName`  varchar(180) NULL DEFAULT NULL ,
`comShortName`  varchar(180) NULL DEFAULT NULL ,
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
CALL create_tables('auctioncom_',0,2);
CALL drop_table('auctioncom_new');
CALL create_table('auctioncom_new');

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;
