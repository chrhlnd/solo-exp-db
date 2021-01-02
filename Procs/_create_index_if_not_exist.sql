DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_create_index_if_not_exist` $$
CREATE PROCEDURE `eqemu`.`_create_index_if_not_exist`(in db_        varchar(128)
													, in theTable   varchar(128)
													, in theIndex   varchar(128)
													, in theColumns varchar(128))
BEGIN
	IF(
		(SELECT COUNT(*) AS column_exists
			FROM information_schema.statistics 
			WHERE table_schema = db_
			  AND table_name   = theTable
			  AND index_name   = theIndex) = 0
	)
	THEN
	
		   SET @s = CONCAT('CREATE INDEX ', db_, '.', theIndex,' ON ',theTable,' (',theColumns,');');
		   PREPARE stmt FROM @s;
		   EXECUTE stmt;
		   
	END IF;
END$$
DELIMITER ;