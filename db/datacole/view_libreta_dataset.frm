TYPE=VIEW
query=select `ug`.`section_id` AS `section_id`,`ug`.`exam_id` AS `exam_id`,`ug`.`student_id` AS `student_id`,`s`.`full_name` AS `full_name`,`ug`.`area_id` AS `area_id`,`a`.`name` AS `area_name`,round(sum(coalesce(`ug`.`grade`,0) * `u`.`weight`) / nullif(sum(`u`.`weight`),0),2) AS `area_avg` from (((`datacole`.`unit_grade` `ug` join `datacole`.`student` `s` on(`s`.`id` = `ug`.`student_id`)) join `datacole`.`area` `a` on(`a`.`id` = `ug`.`area_id`)) join `datacole`.`unit` `u` on(`u`.`id` = `ug`.`unit_id`)) group by `ug`.`section_id`,`ug`.`exam_id`,`ug`.`student_id`,`s`.`full_name`,`ug`.`area_id`,`a`.`name`
md5=7df2a7f9cae3a150ba235a9a1f39d75f
updatable=0
algorithm=0
definer_user=datacole
definer_host=%
suid=2
with_check_option=0
timestamp=0001771996226357443
create-version=2
source=SELECT\n  ug.section_id,\n  ug.exam_id,\n  ug.student_id,\n  s.full_name,\n  ug.area_id,\n  a.name AS area_name,\n  ROUND(SUM(COALESCE(ug.grade,0) * u.weight)/NULLIF(SUM(u.weight),0),2) AS area_avg\nFROM unit_grade ug\nJOIN student s ON s.id = ug.student_id\nJOIN area a ON a.id = ug.area_id\nJOIN unit u ON u.id = ug.unit_id\nGROUP BY ug.section_id, ug.exam_id, ug.student_id, s.full_name, ug.area_id, a.name
client_cs_name=utf8
connection_cl_name=utf8_general_ci
view_body_utf8=select `ug`.`section_id` AS `section_id`,`ug`.`exam_id` AS `exam_id`,`ug`.`student_id` AS `student_id`,`s`.`full_name` AS `full_name`,`ug`.`area_id` AS `area_id`,`a`.`name` AS `area_name`,round(sum(coalesce(`ug`.`grade`,0) * `u`.`weight`) / nullif(sum(`u`.`weight`),0),2) AS `area_avg` from (((`datacole`.`unit_grade` `ug` join `datacole`.`student` `s` on(`s`.`id` = `ug`.`student_id`)) join `datacole`.`area` `a` on(`a`.`id` = `ug`.`area_id`)) join `datacole`.`unit` `u` on(`u`.`id` = `ug`.`unit_id`)) group by `ug`.`section_id`,`ug`.`exam_id`,`ug`.`student_id`,`s`.`full_name`,`ug`.`area_id`,`a`.`name`
mariadb-version=100339
