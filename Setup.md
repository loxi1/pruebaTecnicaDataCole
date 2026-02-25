# 🚀 Guía Rápida – Levantar Proyecto Datacole

Este documento explica únicamente:

1. Cómo levantar el proyecto con Docker
2. Cómo crear la base de datos
3. Cómo cargar la data de prueba

---

## 🐳 1️⃣ Requisitos

- Docker
- Docker Compose
- Puertos libres:
  - 8079 → Aplicación Web
  - 3307 → Base de Datos

---

## ▶️ 2️⃣ Levantar el entorno

Desde la raíz del proyecto:

```bash
docker compose up -d --build
```

Verificar que los contenedores estén activos:

```bash
docker ps
```

Debe aparecer:

- datacole_ci3_web
- datacole_ci3_db

---

## 🌐 3️⃣ Accesos

Aplicación Web:
http://localhost:8079

Base de Datos:
- Host: 127.0.0.1
- Puerto: 3307
- Base de datos: datacole
- Usuario: datacole
- Password: datacole123

---

## 🗄️ 4️⃣ Crear estructura de base de datos

Ejecutar los scripts en el siguiente orden:

```bash
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/01_schema.sql
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/02_views.sql
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/03_functions.sql
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/04_procedures.sql
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/05_indexes.sql
```

---

## 📊 5️⃣ Cargar Data de Prueba

```bash
docker exec -i datacole_ci3_db mysql -udatacole -pdatacole123 datacole < 01_sql/06_dataprueba.sql
```

---

## ✅ 6️⃣ Validación rápida

Ver tablas creadas:

```bash
docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e "SHOW TABLES;"
```

Ver procedimientos creados:

```bash
docker exec -it datacole_ci3_db mysql -udatacole -pdatacole123 datacole -e "SHOW PROCEDURE STATUS WHERE Db='datacole';"
```

---

## 🔄 Reiniciar desde cero

Si deseas reiniciar completamente el entorno:

```bash
docker compose down -v --remove-orphans
docker compose up -d --build
```

Luego volver a ejecutar los scripts SQL.

---

**Autor:**
Aníbal Cayetano