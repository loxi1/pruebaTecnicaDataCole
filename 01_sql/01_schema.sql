SET NAMES utf8mb4;
SET sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- =============================
-- TABLAS ACADEMICAS MINIMAS
-- =============================

CREATE TABLE IF NOT EXISTS section (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  year SMALLINT NOT NULL,
  KEY ix_section_year (year)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  doc_num VARCHAR(20) NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  UNIQUE KEY uq_student_doc (doc_num),
  KEY ix_student_name (full_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS area (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  UNIQUE KEY uq_area (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS unit (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  area_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(80) NOT NULL,
  weight DECIMAL(6,3) NOT NULL DEFAULT 1.000,
  UNIQUE KEY uq_unit (area_id, name),
  KEY ix_unit_area (area_id),
  CONSTRAINT fk_unit_area FOREIGN KEY (area_id) REFERENCES area(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  exam_date DATE NOT NULL,
  KEY ix_exam_date (exam_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS unit_grade (
  section_id BIGINT UNSIGNED NOT NULL,
  exam_id BIGINT UNSIGNED NOT NULL,
  area_id BIGINT UNSIGNED NOT NULL,
  unit_id BIGINT UNSIGNED NOT NULL,
  student_id BIGINT UNSIGNED NOT NULL,
  grade DECIMAL(5,2) NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (section_id, exam_id, area_id, unit_id, student_id),
  KEY ix_grade_student (student_id, exam_id),
  CONSTRAINT fk_ug_section FOREIGN KEY (section_id) REFERENCES section(id),
  CONSTRAINT fk_ug_exam FOREIGN KEY (exam_id) REFERENCES exam(id),
  CONSTRAINT fk_ug_area FOREIGN KEY (area_id) REFERENCES area(id),
  CONSTRAINT fk_ug_unit FOREIGN KEY (unit_id) REFERENCES unit(id),
  CONSTRAINT fk_ug_student FOREIGN KEY (student_id) REFERENCES student(id)
) ENGINE=InnoDB;

-- =============================
-- FACTURACION
-- =============================

CREATE TABLE IF NOT EXISTS fe_document (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  doc_type ENUM('INVOICE','CREDIT_NOTE') NOT NULL,
  serie VARCHAR(10) NOT NULL,
  number INT NOT NULL,
  issue_date DATE NOT NULL,
  customer_doc VARCHAR(20) NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  status ENUM('ACTIVE','VOIDED','CREDITED') NOT NULL DEFAULT 'ACTIVE',
  normalized TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_doc (doc_type, serie, number),
  KEY ix_doc_issue_status (issue_date, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fe_audit_log (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  entity_type VARCHAR(30) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(40) NOT NULL,
  request_id VARCHAR(64) NULL,
  success TINYINT NOT NULL DEFAULT 1,
  error_message VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_audit_entity (entity_type, entity_id, created_at),
  KEY ix_audit_request (request_id)
) ENGINE=InnoDB;

-- =============================
-- CACHE LIBRETAS
-- =============================

CREATE TABLE IF NOT EXISTS pdf_cache (
  cache_key VARCHAR(120) PRIMARY KEY,
  section_id BIGINT UNSIGNED NOT NULL,
  exam_id BIGINT UNSIGNED NOT NULL,
  payload JSON NOT NULL,
  valid_until DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY ix_cache_section_exam (section_id, exam_id, valid_until)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS enrollment (
  section_id BIGINT UNSIGNED NOT NULL,
  student_id BIGINT UNSIGNED NOT NULL,
  status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (section_id, student_id),
  KEY ix_enroll_student (student_id, section_id),
  CONSTRAINT fk_enroll_section FOREIGN KEY (section_id) REFERENCES section(id),
  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES student(id)
) ENGINE=InnoDB;