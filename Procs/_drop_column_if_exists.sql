DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_drop_column_if_exists` $$
CREATE PROCEDURE `eqemu`.`_drop_column_if_exists`(in db_ VARCHAR(128), in theTable varchar(128), in theColumn varchar(128) )
BEGIN
	IF(
		(SELECT COUNT(*) AS column_exists
			FROM information_schema.columns
			WHERE TABLE_SCHEMA = db_
			  AND table_name   = theTable
			  AND column_name  = theColumn) > 0
	)
	THEN
	
   SET @s = CONCAT('ALTER TABLE ', db_, '.', theTable,' DROP COLUMN ' , theColumn , ';');
   PREPARE stmt FROM @s;
   EXECUTE stmt;
 END IF;
END$$
DELIMITER ;

-- Usage
-- CALL eqemu._drop_column_if_exists('eqemu','?table?','?column?');