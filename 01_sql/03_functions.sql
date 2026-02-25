DELIMITER $$

CREATE OR REPLACE FUNCTION fn_promedio_ponderado(
  p_area_id BIGINT UNSIGNED,
  p_student_id BIGINT UNSIGNED
)
RETURNS DECIMAL(6,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_avg DECIMAL(10,4);

  SELECT
    SUM(COALESCE(grade,0) * weight) /
    NULLIF(SUM(weight),0)
  INTO v_avg
  FROM view_unidad_promedio
  WHERE area_id = p_area_id
    AND student_id = p_student_id;

  RETURN ROUND(COALESCE(v_avg,0),2);
END$$

DELIMITER ;