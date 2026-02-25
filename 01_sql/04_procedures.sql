DELIMITER $$

/* =========================================================
   1) PROMEDIOS POR UNIDAD Y ANUAL
========================================================= */
DROP PROCEDURE IF EXISTS sp_get_area_unit_and_annual_grades$$
CREATE PROCEDURE sp_get_area_unit_and_annual_grades(
  IN p_student_id BIGINT UNSIGNED
)
BEGIN
  -- Detalle por unidad
  SELECT *
  FROM view_unidad_promedio
  WHERE student_id = p_student_id;

  -- Promedio anual por área
  SELECT
    area_id,
    ROUND(SUM(COALESCE(grade,0) * weight) /
          NULLIF(SUM(weight),0),2) AS area_avg
  FROM view_unidad_promedio
  WHERE student_id = p_student_id
  GROUP BY area_id;
END$$


/* =========================================================
   2) RANKING POR SECCIÓN / EXAMEN / ÁREA
========================================================= */
DROP PROCEDURE IF EXISTS sp_rank_section_area$$
CREATE PROCEDURE sp_rank_section_area(
  IN p_section_id BIGINT UNSIGNED,
  IN p_exam_id BIGINT UNSIGNED,
  IN p_area_id BIGINT UNSIGNED
)
BEGIN
  SET @r := 0;

  SELECT
    t.student_id,
    s.full_name,
    t.avg_grade,
    (@r := @r + 1) AS rank_pos
  FROM (
    SELECT
      ug.student_id,
      ROUND(SUM(COALESCE(ug.grade,0) * u.weight) /
            NULLIF(SUM(u.weight),0),2) AS avg_grade
    FROM unit_grade ug
    JOIN unit u ON u.id = ug.unit_id
    WHERE ug.section_id = p_section_id
      AND ug.exam_id = p_exam_id
      AND ug.area_id = p_area_id
    GROUP BY ug.student_id
    ORDER BY avg_grade DESC
  ) t
  JOIN student s ON s.id = t.student_id;
END$$


/* =========================================================
   3) GENERAR NOTA DE CRÉDITO (IDEMPOTENTE)
========================================================= */
DROP PROCEDURE IF EXISTS sp_generate_credit_note$$
CREATE PROCEDURE sp_generate_credit_note(
  IN p_document_id BIGINT UNSIGNED,
  IN p_request_id VARCHAR(64)
)
BEGIN
  DECLARE v_serie VARCHAR(10);
  DECLARE v_number INT;
  DECLARE v_total DECIMAL(12,2);
  DECLARE v_customer_doc VARCHAR(20);
  DECLARE v_cn_number INT;
  DECLARE v_existing_cn_id BIGINT UNSIGNED DEFAULT NULL;

  -- Leer documento origen
  SELECT serie, number, total, customer_doc
    INTO v_serie, v_number, v_total, v_customer_doc
  FROM fe_document
  WHERE id = p_document_id;

  SET v_cn_number = v_number + 10000000;

  -- Verificar si ya existe (idempotencia)
  SELECT id INTO v_existing_cn_id
  FROM fe_document
  WHERE doc_type='CREDIT_NOTE'
    AND serie = v_serie
    AND number = v_cn_number
  LIMIT 1;

  IF v_existing_cn_id IS NULL THEN

    INSERT INTO fe_document(
      doc_type, serie, number, issue_date,
      customer_doc, total, status
    )
    VALUES(
      'CREDIT_NOTE', v_serie, v_cn_number, CURDATE(),
      v_customer_doc, v_total, 'ACTIVE'
    );

    SET v_existing_cn_id = LAST_INSERT_ID();

    INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
    VALUES ('fe_document', p_document_id, 'CREDIT_NOTE_CREATED', p_request_id, 1);

  ELSE

    INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
    VALUES ('fe_document', p_document_id, 'CREDIT_NOTE_ALREADY_EXISTS', p_request_id, 1);

  END IF;

  -- Marcar documento como CREDITED
  UPDATE fe_document
  SET status = 'CREDITED'
  WHERE id = p_document_id
    AND status <> 'CREDITED';

  -- Salida única
  SELECT
    p_document_id AS document_id,
    'CREDITED' AS document_status,
    v_existing_cn_id AS credit_note_id,
    CONCAT(v_serie,'-',LPAD(v_cn_number,8,'0')) AS credit_note_number;

END$$


DROP PROCEDURE IF EXISTS sp_process_void_request$$
CREATE PROCEDURE sp_process_void_request(
  IN p_document_id BIGINT UNSIGNED,
  IN p_request_id VARCHAR(64)
)
main: BEGIN
  DECLARE v_issue DATE;
  DECLARE v_days INT;
  DECLARE v_status VARCHAR(20);

  DECLARE v_serie VARCHAR(10);
  DECLARE v_number INT;
  DECLARE v_cn_number INT;
  DECLARE v_cn_id BIGINT UNSIGNED DEFAULT NULL;

  START TRANSACTION;

  SELECT issue_date, status, serie, number
    INTO v_issue, v_status, v_serie, v_number
  FROM fe_document
  WHERE id = p_document_id
  FOR UPDATE;

  -- Idempotencia: si ya fue procesado, devolver estado y salir
  IF v_status IN ('VOIDED','CREDITED') THEN
    -- Si ya estaba CREDITED, intentar ubicar la NC
    IF v_status = 'CREDITED' THEN
      SET v_cn_number = v_number + 10000000;
      SELECT id INTO v_cn_id
      FROM fe_document
      WHERE doc_type='CREDIT_NOTE' AND serie=v_serie AND number=v_cn_number
      LIMIT 1;
    END IF;

    INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
    VALUES ('fe_document', p_document_id, 'VOID_IDEMPOTENT', p_request_id, 1);

    COMMIT;

    SELECT
      p_document_id AS document_id,
      v_status AS document_status,
      v_cn_id AS credit_note_id,
      CASE WHEN v_cn_id IS NULL THEN NULL
           ELSE CONCAT(v_serie,'-',LPAD(v_number + 10000000,8,'0'))
      END AS credit_note_number;

    LEAVE main;
  END IF;

  SET v_days = DATEDIFF(CURDATE(), v_issue);

  IF v_days > 7 THEN
    -- Generar/obtener NC de forma determinística
    SET v_cn_number = v_number + 10000000;

    SELECT id INTO v_cn_id
    FROM fe_document
    WHERE doc_type='CREDIT_NOTE' AND serie=v_serie AND number=v_cn_number
    LIMIT 1;

    IF v_cn_id IS NULL THEN
      INSERT INTO fe_document(doc_type, serie, number, issue_date, customer_doc, total, status, normalized)
      SELECT 'CREDIT_NOTE', serie, (number + 10000000), CURDATE(), customer_doc, total, 'ACTIVE', 1
      FROM fe_document
      WHERE id = p_document_id;

      SET v_cn_id = LAST_INSERT_ID();

      INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
      VALUES ('fe_document', p_document_id, 'CREDIT_NOTE_CREATED', p_request_id, 1);
    ELSE
      INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
      VALUES ('fe_document', p_document_id, 'CREDIT_NOTE_ALREADY_EXISTS', p_request_id, 1);
    END IF;

    UPDATE fe_document
    SET status = 'CREDITED'
    WHERE id = p_document_id
      AND status <> 'CREDITED';

    COMMIT;

    SELECT
      p_document_id AS document_id,
      'CREDITED' AS document_status,
      v_cn_id AS credit_note_id,
      CONCAT(v_serie,'-',LPAD(v_cn_number,8,'0')) AS credit_note_number;

  ELSE
    UPDATE fe_document
    SET status = 'VOIDED'
    WHERE id = p_document_id;

    INSERT INTO fe_audit_log(entity_type, entity_id, action, request_id, success)
    VALUES ('fe_document', p_document_id, 'VOID_WITHIN_7_DAYS', p_request_id, 1);

    COMMIT;

    SELECT
      p_document_id AS document_id,
      'VOIDED' AS document_status,
      NULL AS credit_note_id,
      NULL AS credit_note_number;
  END IF;

END$$

/* =========================================================
   5) CACHE DE LIBRETA (30 MIN)
========================================================= */
DROP PROCEDURE IF EXISTS sp_generate_libreta_dataset$$
CREATE PROCEDURE sp_generate_libreta_dataset(
  IN p_section_id BIGINT UNSIGNED,
  IN p_exam_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_key VARCHAR(120);
  DECLARE v_payload LONGTEXT;

  SET v_key = CONCAT('LIBRETA:', p_section_id, ':', p_exam_id);

  -- Cache hit
  SELECT payload INTO v_payload
  FROM pdf_cache
  WHERE cache_key = v_key
    AND valid_until > NOW()
  LIMIT 1;

  -- Cache miss
  IF v_payload IS NULL THEN

    -- Construir JSON array manual usando GROUP_CONCAT (compatible MariaDB 10.3)
    SELECT CONCAT(
             '[',
             IFNULL(
               GROUP_CONCAT(
                 JSON_OBJECT(
                   'student_id', student_id,
                   'full_name', full_name,
                   'area_id', area_id,
                   'area_name', area_name,
                   'area_avg', area_avg
                 )
                 ORDER BY student_id, area_id
                 SEPARATOR ','
               ),
               ''
             ),
             ']'
           )
    INTO v_payload
    FROM view_libreta_dataset
    WHERE section_id = p_section_id
      AND exam_id = p_exam_id;

    INSERT INTO pdf_cache(cache_key, section_id, exam_id, payload, valid_until)
    VALUES (
      v_key,
      p_section_id,
      p_exam_id,
      v_payload,
      DATE_ADD(NOW(), INTERVAL 30 MINUTE)
    )
    ON DUPLICATE KEY UPDATE
      payload = VALUES(payload),
      valid_until = VALUES(valid_until);

  END IF;

  -- Siempre devolver payload
  SELECT v_payload AS payload;
END$$

DELIMITER ;