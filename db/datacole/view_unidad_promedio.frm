TYPE=VIEW
query=select `ug`.`section_id` AS `section_id`,`ug`.`exam_id` AS `exam_id`,`ug`.`area_id` AS `area_id`,`ug`.`unit_id` AS `unit_id`,`ug`.`student_id` AS `student_id`,`ug`.`grade` AS `grade`,`u`.`weight` AS `weight` from (`datacole`.`unit_grade` `ug` join `datacole`.`unit` `u` on(`u`.`id` = `ug`.`unit_id`))
md5=f972eeee904d7254c411bd58e59d6ea7
updatable=1
algorithm=0
definer_user=datacole
definer_host=%
suid=2
with_check_option=0
timestamp=0001771996226348836
create-version=2
source=SELECT\n  ug.section_id,\n  ug.exam_id,\n  ug.area_id,\n  ug.unit_id,\n  ug.student_id,\n  ug.grade,\n  u.weight\nFROM unit_grade ug\nJOIN unit u ON u.id = ug.unit_id
client_cs_name=utf8
connection_cl_name=utf8_general_ci
view_body_utf8=select `ug`.`section_id` AS `section_id`,`ug`.`exam_id` AS `exam_id`,`ug`.`area_id` AS `area_id`,`ug`.`unit_id` AS `unit_id`,`ug`.`student_id` AS `student_id`,`ug`.`grade` AS `grade`,`u`.`weight` AS `weight` from (`datacole`.`unit_grade` `ug` join `datacole`.`unit` `u` on(`u`.`id` = `ug`.`unit_id`))
mariadb-version=100339
