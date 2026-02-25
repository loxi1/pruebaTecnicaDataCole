CREATE OR REPLACE VIEW view_unidad_promedio AS
SELECT
  ug.section_id,
  ug.exam_id,
  ug.area_id,
  ug.unit_id,
  ug.student_id,
  ug.grade,
  u.weight
FROM unit_grade ug
JOIN unit u ON u.id = ug.unit_id;


CREATE OR REPLACE VIEW view_document_status AS
SELECT
  d.id,
  d.doc_type,
  CONCAT(d.serie,'-',LPAD(d.number,8,'0')) AS doc_number,
  d.issue_date,
  d.total,
  d.status
FROM fe_document d;


CREATE OR REPLACE VIEW view_libreta_dataset AS
SELECT
  ug.section_id,
  ug.exam_id,
  ug.student_id,
  s.full_name,
  ug.area_id,
  a.name AS area_name,
  ROUND(SUM(COALESCE(ug.grade,0) * u.weight)/NULLIF(SUM(u.weight),0),2) AS area_avg
FROM unit_grade ug
JOIN student s ON s.id = ug.student_id
JOIN area a ON a.id = ug.area_id
JOIN unit u ON u.id = ug.unit_id
GROUP BY ug.section_id, ug.exam_id, ug.student_id, s.full_name, ug.area_id, a.name;