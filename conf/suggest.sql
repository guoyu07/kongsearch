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
`id`  int(11) UNSIGNED NOT NULL,
`pid`  int(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
`word`  varchar(180)  NOT NULL ,
`pinyin`  varchar(180)  NOT NULL ,
`querynum` int(11) UNSIGNED NOT NULL DEFAULT '0',
`isdeleted` int(11) UNSIGNED NOT NULL DEFAULT 0,
PRIMARY KEY (`id`),
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
CALL create_tables('suggest_',0,4);
CALL drop_table('suggest_new');
CALL create_table('suggest_new');

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;
