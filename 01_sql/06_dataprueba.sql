-- ==========================
-- DATA DE PRUEBA ACADEMICA + FACTURACION
-- ==========================

-- Limpieza (orden por FK)
DELETE FROM unit_grade;
DELETE FROM enrollment;
DELETE FROM pdf_cache;

DELETE FROM unit;
DELETE FROM area;

DELETE FROM exam;
DELETE FROM student;
DELETE FROM section;

-- ==========================
-- ACADEMICO
-- ==========================

INSERT INTO section(name, year) VALUES ('3A', 2026);
SET @section_id := LAST_INSERT_ID();

INSERT INTO exam(name, exam_date) VALUES ('BIMESTRE_1', CURDATE());
SET @exam_id := LAST_INSERT_ID();

INSERT INTO student(doc_num, full_name) VALUES
('70000001', 'Alumno Uno'),
('70000002', 'Alumno Dos'),
('70000003', 'Alumno Tres');

SET @s1 := (SELECT id FROM student WHERE doc_num='70000001');
SET @s2 := (SELECT id FROM student WHERE doc_num='70000002');
SET @s3 := (SELECT id FROM student WHERE doc_num='70000003');

-- Matricula (enrollment)
INSERT INTO enrollment(section_id, student_id, status) VALUES
(@section_id, @s1, 'ACTIVE'),
(@section_id, @s2, 'ACTIVE'),
(@section_id, @s3, 'ACTIVE');

INSERT INTO area(name) VALUES ('MATEMATICA'), ('COMUNICACION');
SET @a1 := (SELECT id FROM area WHERE name='MATEMATICA');
SET @a2 := (SELECT id FROM area WHERE name='COMUNICACION');

INSERT INTO unit(area_id, name, weight) VALUES
(@a1, 'U1', 1.0),
(@a1, 'U2', 2.0),
(@a2, 'U1', 1.0),
(@a2, 'U2', 1.0);

SET @u_a1_1 := (SELECT id FROM unit WHERE area_id=@a1 AND name='U1');
SET @u_a1_2 := (SELECT id FROM unit WHERE area_id=@a1 AND name='U2');
SET @u_a2_1 := (SELECT id FROM unit WHERE area_id=@a2 AND name='U1');
SET @u_a2_2 := (SELECT id FROM unit WHERE area_id=@a2 AND name='U2');

-- Notas (MATEMATICA pondera U2 x2)
INSERT INTO unit_grade(section_id, exam_id, area_id, unit_id, student_id, grade) VALUES
(@section_id, @exam_id, @a1, @u_a1_1, @s1, 12.0),
(@section_id, @exam_id, @a1, @u_a1_2, @s1, 18.0),
(@section_id, @exam_id, @a1, @u_a1_1, @s2, 15.0),
(@section_id, @exam_id, @a1, @u_a1_2, @s2, 16.0),
(@section_id, @exam_id, @a1, @u_a1_1, @s3, 10.0),
(@section_id, @exam_id, @a1, @u_a1_2, @s3, 11.0),

(@section_id, @exam_id, @a2, @u_a2_1, @s1, 14.0),
(@section_id, @exam_id, @a2, @u_a2_2, @s1, 13.0),
(@section_id, @exam_id, @a2, @u_a2_1, @s2, 17.0),
(@section_id, @exam_id, @a2, @u_a2_2, @s2, 18.0),
(@section_id, @exam_id, @a2, @u_a2_1, @s3, 12.0),
(@section_id, @exam_id, @a2, @u_a2_2, @s3, 12.0);

-- IDs para pruebas
SELECT @section_id AS section_id, @exam_id AS exam_id, @a1 AS area_mate, @a2 AS area_comu;

-- ==========================
-- FACTURACION (casos 7 días)
-- ==========================
DELETE FROM fe_audit_log;
DELETE FROM fe_document;

INSERT INTO fe_document
(doc_type, serie, number, issue_date, customer_doc, total, status)
VALUES
('INVOICE','F001',1, DATE_SUB(CURDATE(), INTERVAL 10 DAY),'20123456789',150.00,'ACTIVE'),
('INVOICE','F001',2, DATE_SUB(CURDATE(), INTERVAL 3 DAY),'20123456789',200.00,'ACTIVE');

SELECT id, issue_date, status FROM fe_document ORDER BY id;