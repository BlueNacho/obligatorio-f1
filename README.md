## Proyecto F1 – Setup rápido

### 1. Levantar los servicios

```bash
docker compose up -d
```

Servicios:

- Postgres **staging** en `localhost:5433` (db: `staging`, user/pass: `admin`/`admin`)
- Postgres **dw** en `localhost:5434` (db: `dw`, user/pass: `admin`/`admin`)
- pgAdmin en `http://localhost:5050` (email: `admin@admin.com`, pass: `admin`)

### 2. Crear estructuras de BD (usar DataGrip o pgAdmin)

En **staging**, ejecutar el script de staging:

- Script: `database_ddl/create_staging_tables.sql`

En **dw**, ejecutar el script del Data Warehouse:

- Script: `database_ddl/create_dw_tables.sql`

### 3. Ejecutar el ETL en Pentaho PDI (Spoon)

1. Abrir Spoon
2. `File → Open` y abrir el job:
   - `pdi_jobs/etl_f1_job.kjb`
3. Ejecutar el job (`Run`) y esperar que termine:
   - Paso 1: carga CSV → tablas `stg_*` (staging)
   - Paso 2: carga dimensiones (`dim_*`) en `dw`
   - Paso 3: carga tablas de hecho (`fact_*`) en `dw`

### 4. Conectar PowerBI (opcional)

- Servidor: `localhost`
- Puerto: `5434`
- Base de datos: `dw`
- Usuario: `admin`
- Password: `admin`

Usar las tablas `dim_*` y `fact_*` para crear los reportes.
