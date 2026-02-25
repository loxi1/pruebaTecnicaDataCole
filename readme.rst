===========================================
Examen Técnico Senior – Datacole (Enterprise)
===========================================

Este repositorio contiene la solución a la prueba técnica solicitada, usando:

- **MariaDB 10.3**
- **CodeIgniter 3** (mini backend opcional)
- **Docker Compose** (ambiente reproducible)

La solución incluye:
1) Script SQL completo (tablas, índices, vistas, funciones y procedimientos).
2) Documento explicativo con decisiones técnicas y justificación de índices.
3) Evidencias de pruebas (EXPLAIN, resultados y casos límite).
4) (Opcional) Mini backend que consume Stored Procedures (SP).

-------------------------------------------
1. Requisitos
-------------------------------------------

- Docker + Docker Compose
- Linux (probado en Arch Linux)
- Puertos libres:
  - **8079** (Web / Apache + CI3)
  - **3307** (MariaDB)

-------------------------------------------
2. Estructura del proyecto
-------------------------------------------

::

  .
  ├── docker-compose.yml
  ├── Dockerfile
  ├── apache/
  │   └── 000-default.conf
  ├── app/                       # CodeIgniter 3 (mini backend opcional)
  ├── 01_sql/
  │   ├── 01_schema.sql          # Tablas + PK/FK + índices base
  │   ├── 02_views.sql           # Vistas
  │   ├── 03_functions.sql       # Funciones
  │   ├── 04_procedures.sql      # Procedimientos (SP)
  │   ├── 05_indexes.sql         # Índices adicionales (producción/performance)
  │   └── 06_dataprueba.sql      # Data de prueba (académico + facturación)
  └── 02_evidencias/
      └── evidencias_explain.md  # EXPLAIN + resultados + casos límite (capturas reales)

-------------------------------------------
3. Levantar el proyecto (Docker)
-------------------------------------------

Desde la raíz del proyecto:

::

  docker compose up -d --build
  docker ps

Accesos:

- Web (Apache/CI3): http://localhost:8079
- MariaDB (host): 127.0.0.1:3307

Credenciales DB por defecto (docker-compose.yml):

- Database: **datacole**
- User: **datacole**
- Pass: **datacole123**
- Root pass: **root**

-------------------------------------------
4. Cargar la base de datos (SQL)
-------------------------------------------

Ejecutar los scripts en este orden:

::

  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/01_schema.sql
  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/02_views.sql
  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/03_functions.sql
  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/04_procedures.sql
  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/05_indexes.sql

Carga de data de prueba:

::

  docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/06_dataprueba.sql

Validación rápida:

::

  docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e "SHOW TABLES;"
  docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e "SHOW PROCEDURE STATUS WHERE Db='datacole';"
  docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e "SHOW FUNCTION STATUS WHERE Db='datacole';"

-------------------------------------------
5. Script SQL completo (entregable #1)
-------------------------------------------

Ubicación: **01_sql/**

- **01_schema.sql**
  - Tablas académicas y facturación
  - PK/FK
  - Índices base orientados a producción
- **02_views.sql**
  - Vistas para dataset / reportes
- **03_functions.sql**
  - Función de promedio ponderado
- **04_procedures.sql**
  - SP académicos (ranking, dataset)
  - SP facturación (regla de 7 días, idempotencia)
  - SP cache libreta (TTL 30 min)
- **05_indexes.sql**
  - Índices adicionales para performance y escalabilidad
- **06_dataprueba.sql**
  - Dataset reproducible para generar evidencias

-------------------------------------------
6. Evidencias de pruebas (entregable #3)
-------------------------------------------

Ubicación: **02_evidencias/evidencias_explain.md**

Incluye:

- Resultados funcionales:
  - Ranking por área
  - Promedio ponderado
  - Regla de 7 días (VOIDED vs CREDIT_NOTE)
  - Cache libreta (MISS/HIT con TTL)
- Evidencias de performance:
  - EXPLAIN para consultas principales
  - Uso de índices (PRIMARY/compuestos)
- Casos límite:
  - Idempotencia (reintentos no duplican NC)
  - Validación de unicidad por índice UNIQUE

-------------------------------------------
7. Documento explicativo (entregable #2)
-------------------------------------------

Este entregable corresponde al documento de decisiones técnicas y justificación
de índices. Debe incluir:

- Arquitectura y supuestos del modelo
- Justificación de índices (por patrón de consulta)
- Enfoque transaccional y control de concurrencia (FOR UPDATE)
- Idempotencia en facturación (evitar duplicados en reintentos)
- Estrategia de caching para libretas (TTL 30 min)
- Consideraciones de producción (integridad histórica, auditoría)

**Nota:** si el documento se entrega como archivo aparte (PDF/MD), referenciarlo aquí.

-------------------------------------------
8. Mini backend opcional (entregable #4)
-------------------------------------------

Ubicación: **app/** (CodeIgniter 3)

Endpoints sugeridos (según implementación):

- Ping DB:
  - http://localhost:8079/index.php/api/ping_db

- Procesar anulación / regla 7 días:
  - http://localhost:8079/index.php/api/void_request/{id}?request_id=abc

Ejemplo (según data de prueba, los IDs pueden variar):

::

  http://localhost:8079/index.php/api/void_request/5?request_id=test456

Respuesta esperada para >7 días:

- document_status = CREDITED
- credit_note_id != null
- credit_note_number = F001-10000001

-------------------------------------------
9. Notas importantes de operación
-------------------------------------------

- Los IDs pueden cambiar entre ejecuciones del seed (AUTO_INCREMENT). Para verificar
  el ID actual de facturas:

::

  docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e \
  "SELECT id, doc_type, serie, number, issue_date, status FROM fe_document ORDER BY id;"

- Regla de negocio 7 días:
  - Si ``DATEDIFF(CURDATE(), issue_date) <= 7`` => VOIDED
  - Si ``DATEDIFF(CURDATE(), issue_date) > 7`` => CREDITED + CREDIT_NOTE

-------------------------------------------
10. Limpieza / reinicio de entorno
-------------------------------------------

Para reiniciar desde cero (incluye volúmenes DB):

::

  docker compose down -v --remove-orphans
  docker compose up -d --build

-------------------------------------------
Autor
-------------------------------------------

Aníbal Cayetano (loxi1)