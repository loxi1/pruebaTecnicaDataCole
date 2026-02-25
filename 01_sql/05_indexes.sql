-- ==========================
-- INDICES ADICIONALES (Enterprise)
-- ==========================

-- 1) unit_grade: acelerar ranking / reportes por sección+exam+área
-- (PK ya cubre varios casos, este ayuda a GROUP BY student_id + filtro)
CREATE INDEX ix_ug_section_exam_area_student
  ON unit_grade(section_id, exam_id, area_id, student_id);

-- 2) unit_grade: consultas por alumno en un examen (historial)
-- (si ya existe ix_grade_student, no crees duplicado)
-- CREATE INDEX ix_ug_student_exam ON unit_grade(student_id, exam_id);

-- 3) fe_document: filtros comunes (cliente + rango)
CREATE INDEX ix_doc_customer_issue
  ON fe_document(customer_doc, issue_date);

-- 4) fe_document: búsqueda rápida de NC por serie+numero (además de uq_doc)
-- (uq_doc ya cubre doc_type, serie, number, esto es redundante normalmente)
-- CREATE INDEX ix_doc_serie_number ON fe_document(serie, number);

-- 5) pdf_cache: acelerar invalidación / refresh por lote
CREATE INDEX ix_cache_valid_until
  ON pdf_cache(valid_until);

-- 6) fe_audit_log: búsqueda por acción y fecha (troubleshooting)
CREATE INDEX ix_audit_action_date
  ON fe_audit_log(action, created_at);