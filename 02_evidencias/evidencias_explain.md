Evidencias de Pruebas

EXPLAIN, Resultados y Casos Límite
Proyecto: Examen Técnico Senior – Datacole
Motor: MariaDB 10.3
Backend de prueba: CodeIgniter 3 (Docker)

1. Problema Académico
seccion_id = 1
examen_id = 1
area_id = 1 -> MATEMATICA
area_id = 2 -> Comunicacion
3 alumnos
2 areas
2 unidades por area
12 registros unit_grade

MariaDB [datacole]> SELECT * FROM section;
+----+------+------+
| id | name | year |
+----+------+------+
|  1 | 3A   | 2026 |
+----+------+------+
1 row in set (0.000 sec)

MariaDB [datacole]> SELECT * FROM exam;
+----+------------+------------+
| id | name       | exam_date  |
+----+------------+------------+
|  1 | BIMESTRE_1 | 2026-02-25 |
+----+------------+------------+
1 row in set (0.000 sec)

MariaDB [datacole]> SELECT id, name FROM area;
+----+--------------+
| id | name         |
+----+--------------+
|  2 | COMUNICACION |
|  1 | MATEMATICA   |
+----+--------------+
2 rows in set (0.000 sec)

MariaDB [datacole]> SELECT id, doc_num, full_name FROM student;
+----+----------+-------------+
| id | doc_num  | full_name   |
+----+----------+-------------+
|  1 | 70000001 | Alumno Uno  |
|  2 | 70000002 | Alumno Dos  |
|  3 | 70000003 | Alumno Tres |
+----+----------+-------------+
3 rows in set (0.001 sec)

MariaDB [datacole]> SELECT COUNT(*) AS filas_unit_grade FROM unit_grade;
+------------------+
| filas_unit_grade |
+------------------+
|               12 |
+------------------+

Funcion Promedio ponderado:
MariaDB [datacole]> SELECT fn_promedio_ponderado(
    ->   (SELECT id FROM area WHERE name='MATEMATICA' LIMIT 1),
    ->   (SELECT id FROM student WHERE doc_num='70000002' LIMIT 1)
    -> ) AS prom_mate_alumno2;
+-------------------+
| prom_mate_alumno2 |
+-------------------+
|             15.67 |
+-------------------+
1 row in set (0.001 sec)

Ranking por Area
MATEMATICA
MariaDB [datacole]> CALL sp_rank_section_area(1, 1, 1);
+------------+-------------+-----------+----------+
| student_id | full_name   | avg_grade | rank_pos |
+------------+-------------+-----------+----------+
|          1 | Alumno Uno  |     16.00 |        1 |
|          2 | Alumno Dos  |     15.67 |        2 |
|          3 | Alumno Tres |     10.67 |        3 |
+------------+-------------+-----------+----------+
3 rows in set (0.001 sec)

COMUNICACION
MariaDB [datacole]> CALL sp_rank_section_area(1, 1, 2);
+------------+-------------+-----------+----------+
| student_id | full_name   | avg_grade | rank_pos |
+------------+-------------+-----------+----------+
|          2 | Alumno Dos  |     17.50 |        1 |
|          3 | Alumno Tres |     12.00 |        2 |
|          1 | Alumno Uno  |     13.50 |        3 |
+------------+-------------+-----------+----------+
3 rows in set (0.001 sec)

Explain ranking

MariaDB [datacole]> EXPLAIN
    -> SELECT ug.student_id,
    ->        ROUND(SUM(COALESCE(ug.grade,0) * u.weight)/NULLIF(SUM(u.weight),0),2) AS avg_grade
    -> FROM unit_grade ug
    -> JOIN unit u ON u.id = ug.unit_id
    -> WHERE ug.section_id = 1
    ->   AND ug.exam_id = 1
    ->   AND ug.area_id = 1
    -> GROUP BY ug.student_id
    -> ORDER BY avg_grade DESC;
+------+-------------+-------+------+--------------------------------------------------------------------------+---------+---------+---------------------------------+------+---------------------------------+
| id   | select_type | table | type | possible_keys                                                            | key     | key_len | ref                             | rows | Extra                           |
+------+-------------+-------+------+--------------------------------------------------------------------------+---------+---------+---------------------------------+------+---------------------------------+
|    1 | SIMPLE      | u     | ALL  | PRIMARY                                                                  | NULL    | NULL    | NULL                            |    4 | Using temporary; Using filesort |
|    1 | SIMPLE      | ug    | ref  | PRIMARY,fk_ug_exam,fk_ug_area,fk_ug_unit,ix_ug_section_exam_area_student | PRIMARY | 32      | const,const,const,datacole.u.id |    1 |                                 |
+------+-------------+-------+------+--------------------------------------------------------------------------+---------+---------+---------------------------------+------+---------------------------------+
2 rows in set (0.000 sec)


2. Facturacón electronica
regla de los 7 días
id=6, issue_date=2026-02-22
MariaDB [datacole]> SELECT id, doc_type, serie, number, issue_date, status, total
    -> FROM fe_document
    -> ORDER BY id;
+----+----------+-------+--------+------------+--------+--------+
| id | doc_type | serie | number | issue_date | status | total  |
+----+----------+-------+--------+------------+--------+--------+
|  5 | INVOICE  | F001  |      1 | 2026-02-15 | ACTIVE | 150.00 |
|  6 | INVOICE  | F001  |      2 | 2026-02-22 | ACTIVE | 200.00 |
+----+----------+-------+--------+------------+--------+--------+

Si es mas de 7 días se genera una nota de credito
http://localhost:8079/index.php/api/void_request/5?request_id=test123
{
  "ok": true,
  "request_id": "test123",
  "data": [
      {
      "document_id": "5",
      "document_status": "CREDITED",
      "credit_note_id": "7",
      "credit_note_number": "F001-10000001"
      }
    ]
}

En caso de ser menor a 7 dias no genera nota de credito:
http://localhost:8079/index.php/api/void_request/6?request_id=test123
{
  "ok": true,
  "request_id": "test123",
  "data": [
    {
      "document_id": "6",
      "document_status": "VOIDED",
      "credit_note_id": null,
      "credit_note_number": null
    }
  ]
}

Caso liminte: Idempotencia
http://localhost:8079/index.php/api/void_request/1?request_id=test123

MariaDB [datacole]> SELECT doc_type, serie, number, COUNT(*) c FROM fe_document GROUP BY doc_type, serie, number HAVING c > 1;
Empty set (0.000 sec)

Explain Faccturación
MariaDB [datacole]> EXPLAIN SELECT id, issue_date, status FROM fe_document WHERE issue_date BETWEEN '2026-01-01' AND '2026-12-31' AND status IN ('ACTIVE','VOIDED','CREDITED');
+------+-------------+-------------+-------+---------------------+---------------------+---------+------+------+--------------------------+
| id   | select_type | table       | type  | possible_keys       | key                 | key_len | ref  | rows | Extra                    |
+------+-------------+-------------+-------+---------------------+---------------------+---------+------+------+--------------------------+
|    1 | SIMPLE      | fe_document | index | ix_doc_issue_status | ix_doc_issue_status | 4       | NULL |    3 | Using where; Using index |
+------+-------------+-------------+-------+---------------------+---------------------+---------+------+------+--------------------------+
1 row in set (0.000 sec)

MariaDB [datacole]>


3.- Problema de libreta + Cache (30 min TTL)

MariaDB [datacole]> CALL sp_generate_libreta_dataset(1,1);
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| payload                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| [{"student_id": 1, "full_name": "Alumno Uno", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 16.00},{"student_id": 1, "full_name": "Alumno Uno", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 13.50},{"student_id": 2, "full_name": "Alumno Dos", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 15.67},{"student_id": 2, "full_name": "Alumno Dos", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 17.50},{"student_id": 3, "full_name": "Alumno Tres", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 10.67},{"student_id": 3, "full_name": "Alumno Tres", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 12.00}] |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.000 sec)

Query OK, 1 row affected (0.001 sec)
se insert  pdf_cache

MariaDB [datacole]> SELECT cache_key, valid_until FROM pdf_cache;
+-------------+---------------------+
| cache_key   | valid_until         |
+-------------+---------------------+
| LIBRETA:1:1 | 2026-02-25 06:35:57 |
+-------------+---------------------+
1 row in set (0.000 sec)

Segunda ejecucion cache


MariaDB [datacole]> CALL sp_generate_libreta_dataset(1,1);
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| payload                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| [{"student_id": 1, "full_name": "Alumno Uno", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 16.00},{"student_id": 1, "full_name": "Alumno Uno", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 13.50},{"student_id": 2, "full_name": "Alumno Dos", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 15.67},{"student_id": 2, "full_name": "Alumno Dos", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 17.50},{"student_id": 3, "full_name": "Alumno Tres", "area_id": 1, "area_name": "MATEMATICA", "area_avg": 10.67},{"student_id": 3, "full_name": "Alumno Tres", "area_id": 2, "area_name": "COMUNICACION", "area_avg": 12.00}] |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.007 sec)

Query OK, 3 rows affected (0.007 sec)

MariaDB [datacole]>
devuelve el mismo json y no recalcula

explain cache

MariaDB [datacole]> EXPLAIN SELECT payload FROM pdf_cache WHERE cache_key = 'LIBRETA:1:1' AND valid_until > NOW();
+------+-------------+-----------+-------+------------------------------+---------+---------+-------+------+-------+
| id   | select_type | table     | type  | possible_keys                | key     | key_len | ref   | rows | Extra |
+------+-------------+-----------+-------+------------------------------+---------+---------+-------+------+-------+
|    1 | SIMPLE      | pdf_cache | const | PRIMARY,ix_cache_valid_until | PRIMARY | 482     | const |    1 |       |
+------+-------------+-----------+-------+------------------------------+---------+---------+-------+------+-------+
1 row in set (0.000 sec)

MariaDB [datacole]>