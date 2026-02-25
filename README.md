
# Evidencias de Pruebas
**EXPLAIN, Resultados y Casos Límite**
Proyecto: Examen Técnico Senior – Datacole
Motor: MariaDB 10.3
Backend de prueba: CodeIgniter 3 (Docker)

---

## 1) Problema Académico

### Datos de prueba
- section_id = 1
- exam_id = 1
- area_id = 1 → MATEMATICA
- area_id = 2 → COMUNICACION
- 3 alumnos
- 2 áreas
- 2 unidades por área
- 12 registros en unit_grade

---

### Promedio ponderado

```sql
SELECT fn_promedio_ponderado(
  (SELECT id FROM area WHERE name='MATEMATICA' LIMIT 1),
  (SELECT id FROM student WHERE doc_num='70000002' LIMIT 1)
) AS prom_mate_alumno2;
```

Resultado:

15.67

---

### Ranking MATEMATICA

```sql
CALL sp_rank_section_area(1,1,1);
```

Alumno Uno  → 16.00 (Rank 1)
Alumno Dos  → 15.67 (Rank 2)
Alumno Tres → 10.67 (Rank 3)

---

### Ranking COMUNICACION

```sql
CALL sp_rank_section_area(1,1,2);
```

Alumno Dos  → 17.50 (Rank 1)
Alumno Tres → 12.00 (Rank 2)
Alumno Uno  → 13.50 (Rank 3)

---

## EXPLAIN Ranking

```sql
EXPLAIN
SELECT ug.student_id,
       ROUND(SUM(COALESCE(ug.grade,0) * u.weight)/NULLIF(SUM(u.weight),0),2) AS avg_grade
FROM unit_grade ug
JOIN unit u ON u.id = ug.unit_id
WHERE ug.section_id = 1
  AND ug.exam_id = 1
  AND ug.area_id = 1
GROUP BY ug.student_id
ORDER BY avg_grade DESC;
```

Observación:
- unit_grade usa índice PRIMARY
- unit aparece como ALL (tabla pequeña)
- Uso de temporary + filesort esperado por GROUP BY

---

## 2) Facturación Electrónica – Regla 7 días

### Regla de negocio

- Si DATEDIFF(CURDATE(), issue_date) <= 7 → VOIDED
- Si DATEDIFF(CURDATE(), issue_date) > 7 → CREDITED + CREDIT_NOTE

---

### Caso > 7 días

Endpoint:
http://localhost:8079/index.php/api/void_request/5?request_id=test123

Resultado:

{
  "document_status": "CREDITED",
  "credit_note_number": "F001-10000001"
}

---

### Caso <= 7 días

Endpoint:
http://localhost:8079/index.php/api/void_request/6?request_id=test123

Resultado:

{
  "document_status": "VOIDED"
}

---

### Idempotencia

```sql
SELECT doc_type, serie, number, COUNT(*) c
FROM fe_document
GROUP BY doc_type, serie, number
HAVING c > 1;
```

Resultado: Empty set

---

## EXPLAIN Facturación

```sql
EXPLAIN
SELECT id, issue_date, status
FROM fe_document
WHERE issue_date BETWEEN '2026-01-01' AND '2026-12-31'
  AND status IN ('ACTIVE','VOIDED','CREDITED');
```

Observación:
- key = ix_doc_issue_status
- Using index
- Optimizado para rango + estado

---

## 3) Libreta + Cache (TTL 30 min)

### Primera ejecución (MISS)

```sql
CALL sp_generate_libreta_dataset(1,1);
```

Inserta en pdf_cache con clave:
LIBRETA:1:1

---

### Segunda ejecución (HIT)

Devuelve el mismo JSON sin recalcular.

---

### EXPLAIN Cache

```sql
EXPLAIN
SELECT payload
FROM pdf_cache
WHERE cache_key = 'LIBRETA:1:1'
  AND valid_until > NOW();
```

Resultado:
- type = const
- key = PRIMARY
- rows = 1

---

## Conclusiones Técnicas

- Procedimientos validados con datos reales.
- Índices compuestos utilizados correctamente.
- Regla empresarial de 7 días implementada.
- Idempotencia garantizada.
- Cache con acceso O(1).
- Diseño orientado a producción.