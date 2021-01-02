DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_run_classify_drops` $$
CREATE PROCEDURE `eqemu`.`_run_classify_drops`()
BEGIN
	create table if not exists classify_drops as
	select i.id,
		   i.name,
		   ((avg(le.chance)+avg(lte.probability/100))/2) as 'chance',
		   avg(se.chance/100) as 'spawn_chance',
		   count(distinct le.lootdrop_id, sp2.spawngroupID) as 'occurance',
		   min(npc.level) as 'minlevel',
		   max(npc.level) as 'maxlevel',
		   min(zone.zoneIdNumber) 'minzone',
		   max(zone.zoneIdNumber) 'maxzone',
		   min(zone.expansion) as 'minexpansion',
		   max(zone.expansion) as 'maxexpansion'
	from items i
	inner join lootdrop_entries  le  on le.item_id       = i.id
	inner join loottable_entries lte on lte.lootdrop_id  = le.lootdrop_id
	inner join npc_types         npc on npc.loottable_id = lte.loottable_id
	inner join spawnentry        se  on se.npcid         = npc.id
	inner join spawn2            sp2 on sp2.spawngroupID = se.spawngroupID
	inner join zone              zone on zone.short_name = sp2.zone
	where sp2.enabled = 1
	group by i.id, i.name
	;

	IF (SELECT COUNT(1)
			FROM information_schema.statistics 
			WHERE table_schema = 'eqemu'
			  AND table_name   = 'classify_drops'
			  AND index_name   = 'PRIMARY') = 0
	THEN
		
		ALTER TABLE eqemu.classify_drops ADD PRIMARY KEY (id);
		
	END IF;
	
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_rebuild_classify_drops` $$
CREATE PROCEDURE `eqemu`.`_rebuild_classify_drops`()
BEGIN
	drop table if exists classify_drops;
	
	CALL _run_classify_drops();
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_run_build_drop_zone` $$
CREATE PROCEDURE `eqemu`.`_run_build_drop_zone`()
BEGIN

	create table if not exists item_drop_zone as
	select distinct le.item_id, sp2.zone
	from lootdrop_entries le
	inner join loottable_entries lte on lte.lootdrop_id = le.lootdrop_id
	inner join npc_types npc on npc.loottable_id = lte.loottable_id
	inner join spawnentry se on se.npcID = npc.id
	inner join spawn2 sp2  on sp2.spawngroupID = se.spawngroupID
	;
		
	IF (SELECT COUNT(1)
			FROM information_schema.statistics 
			WHERE table_schema = 'eqemu'
			  AND table_name   = 'item_drop_zone'
			  AND index_name   = 'PRIMARY') = 0
	THEN

		ALTER TABLE eqemu.item_drop_zone ADD PRIMARY KEY (item_id,zone);
	END IF;
	
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_rebuild_drop_zone` $$
CREATE PROCEDURE `eqemu`.`_rebuild_drop_zone`()
BEGIN
	drop table if exists item_drop_zone;
	CALL _run_build_drop_zone();
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS `eqemu`.`_setup_item_quest` $$
CREATE PROCEDURE `eqemu`.`_setup_item_quest`()
BEGIN

	CALL _create_index_if_not_exist('eqemu','spawn2'           ,'sp2_zone','spawngroupID, zone');
	CALL _create_index_if_not_exist('eqemu','spawnentry'       ,'se_npc'  ,'npcID');
	CALL _create_index_if_not_exist('eqemu','npc_types'        ,'npc_loot','loottable_id');
	CALL _create_index_if_not_exist('eqemu','loottable_entries','lte_drop','lootdrop_id');
	
	CALL _run_classify_drops();
	CALL _run_build_drop_zone();
	
	insert ignore into command_settings (command, access, aliases)
	values ('iq-query', 0, 'iqq'), ('iq-set', 0, 'iqs'), ('iq-queryz',0,'iqqz');

END$$
DELIMITER ;

CALL eqemu._setup_item_quest();
