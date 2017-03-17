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
`bookId` int(11) NOT NULL,
`pid`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`uniqueMd5` varchar(32),
`bookName` varchar(255),
`bookNamePinyin` varchar(255),
`catName` varchar(255),
`catId` bigint(18),
`price` varchar(255),
`author` varchar(255),
`press` varchar(255),
`pubDate` varchar(255),
`edition` varchar(255),
`isbn` varchar(13),
`certifyStatus` tinyint(1) NOT NULL DEFAULT 0,
`zcatId` char(64) NOT NULL DEFAULT '0',
`jcatId1` int(11) NOT NULL DEFAULT '0',
`jcatId2` int(11) NOT NULL DEFAULT '0',
`editorComment` text,
`contentIntroduction` text,
`directory` text,
`Illustration` text,
`description` text,
`bookForeign` varchar(255),
`area` varchar(255),
`language` varchar(255),
`originalLanguage` varchar(255),
`catAgency` varchar(255),
`wordNum` varchar(255),
`pageNum` varchar(255),
`printingNum` varchar(255),
`printingTime` varchar(255),
`pageSize` varchar(255),
`setNum` tinyint(2) unsigned NOT NULL DEFAULT 0,
`impression` varchar(255),
`usedPaper` varchar(255),
`issn` varchar(8),
`unifiedIsbn` varchar(255),
`binding` varchar(255),
`tag` varchar(255),
`series` varchar(255),
`bookSize` varchar(255),
`bookWeight` varchar(30),
`normalImg` varchar(255),
`smallImg` varchar(255),
`bigImg` varchar(255),
`authorId` int(11) NOT NULL,
`authorName` varchar(255),
`authorNamePinyin` varchar(255),
`authorUrl` varchar(255),
`pressId` int(11) NOT NULL,
`pressName` varchar(255),
`pressUrl` varchar(255),
`lifeStory` text,
`authorPhoto` varchar(255),
`jobId` int(11) NOT NULL,
`jobName` varchar(255),
`authorIds` varchar(50),
`authorNames` varchar(255),
`jobIds` varchar(50),
`jobNames` varchar(255),
`isdeleted` tinyint(1) unsigned NOT NULL,
`_bookName` varchar(255),
`_catName` varchar(255),
`_author` varchar(255),
`_press` varchar(255),
`_pubDate` varchar(255),
`_isbn` varchar(13),
`_tag` varchar(255),
`_jobName` varchar(255),
`_authorIds` varchar(50),
`_authorNames` varchar(255),
`_jobIds` varchar(50),
`_jobNames` varchar(255),
`_authorName` varchar(255),
`_pressName` varchar(255),
PRIMARY KEY (`bookId`),
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
CALL create_tables('booklib_',0,10);
CALL drop_table('booklib_new');
CALL create_table('booklib_new');

DROP PROCEDURE IF EXISTS drop_table;
DROP PROCEDURE IF EXISTS create_table;
DROP PROCEDURE IF EXISTS create_tables;