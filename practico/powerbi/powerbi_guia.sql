-- =====================================================
-- GUÍA DE POWERBI - FORMULA 1 DATA WAREHOUSE
-- Queries e instrucciones para armar los reportes
-- =====================================================

/*
=======================================================
CONEXIÓN A POSTGRESQL DESDE POWERBI
=======================================================

1. Abrir PowerBI Desktop
2. Inicio → Obtener datos → Base de datos → PostgreSQL
3. Configurar conexión:
   - Servidor: localhost
   - Puerto: 5434
   - Base de datos: dw
   - Usuario: admin
   - Contraseña: admin
4. Elegir \"Import\" (suficiente para el práctico)
5. Usar estas queries como \"Consulta SQL\" o importar tablas y recrear en DAX
*/

-- =====================================================
-- REPORTE 1: MAPA DE CIRCUITOS
-- Visual: Mapa
-- =====================================================

SELECT 
    dc.circuit_id,
    dc.circuit_name AS circuito,
    dc.location AS ciudad,
    dc.country AS pais,
    dc.continent AS continente,
    dc.latitude AS latitud,
    dc.longitude AS longitud,
    dc.altitude AS altitud,
    COUNT(DISTINCT dr.race_id) AS carreras_en_circuito
FROM dim_circuit dc
LEFT JOIN dim_race dr ON dc.circuit_id = dr.circuit_id
WHERE dc.latitude IS NOT NULL 
  AND dc.longitude IS NOT NULL
GROUP BY dc.circuit_id, dc.circuit_name, dc.location, dc.country,
         dc.continent, dc.latitude, dc.longitude, dc.altitude;

/*
En PowerBI:
- Visualización: Mapa
- Latitud: latitud
- Longitud: longitud
- Leyenda: continente
- Tamaño (Size): carreras_en_circuito
- Tooltips: circuito, pais, altitud
*/


-- =====================================================
-- REPORTE 2: PILOTOS × ESCUDERÍAS × AÑO
-- Visual: Matriz + Barras apiladas
-- =====================================================

SELECT 
    dr.race_year AS anio,
    dd.full_name AS piloto,
    dd.nationality AS nacionalidad_piloto,
    dc.constructor_name AS escuderia,
    dc.nationality AS nacionalidad_escuderia,
    COUNT(DISTINCT fr.sk_race) AS carreras,
    SUM(fr.points) AS puntos,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) AS victorias,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) AS podios
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY dr.race_year, dd.full_name, dd.nationality,
         dc.constructor_name, dc.nationality;

/*
En PowerBI:
- Visual 1: Matriz
  - Filas: piloto
  - Columnas: anio
  - Valores: puntos, victorias, podios
  - Filtros: escuderia

- Visual 2: Barras apiladas
  - Eje X: anio
  - Eje Y: puntos
  - Leyenda: escuderia
*/


-- =====================================================
-- REPORTE 3: CAMPEONES MUNDIALES (PILOTOS Y ESCUDERÍAS)
-- Visual: Tabla + Barras
-- =====================================================

-- Campeones de pilotos por año
WITH ultima_carrera AS (
  SELECT race_year, MAX(race_round) AS ultimo_round
  FROM dim_race
  GROUP BY race_year
)
SELECT 
  dr.race_year AS anio,
  dd.full_name AS campeon,
  dd.nationality AS nacionalidad,
  fds.points AS puntos_campeonato,
  fds.wins AS victorias_campeonato
FROM fact_driver_standings fds
JOIN dim_driver dd ON fds.sk_driver = dd.sk_driver
JOIN dim_race dr ON fds.sk_race = dr.sk_race
JOIN ultima_carrera uc 
  ON dr.race_year = uc.race_year AND dr.race_round = uc.ultimo_round
WHERE fds.position = 1
ORDER BY anio;

/*
Visual sugerido:
- Tabla: anio, campeon, nacionalidad, puntos_campeonato, victorias_campeonato
- Barras horizontales: 
  - Eje Y: campeon
  - Eje X: COUNT(anio) (número de campeonatos)
*/


-- =====================================================
-- REPORTE 4: ESCUDERÍAS MÁS GANADORAS (HISTORIA vs ÚLTIMOS 10 AÑOS)
-- Visual: Barras agrupadas
-- =====================================================

SELECT 
  dc.constructor_name AS escuderia,
  SUM(CASE WHEN fr.is_winner THEN 1 ELSE 0 END) AS victorias_historicas,
  SUM(CASE WHEN fr.is_winner AND fr.race_year >= (EXTRACT(YEAR FROM CURRENT_DATE) - 10)
           THEN 1 ELSE 0 END) AS victorias_ultimos_10,
  SUM(fr.points) AS puntos_totales
FROM fact_results fr
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
GROUP BY dc.constructor_name;

/*
En PowerBI:
- Barras agrupadas:
  - Eje X: escuderia
  - Valores: victorias_historicas, victorias_ultimos_10
  - Ordenar por: victorias_historicas desc
*/


-- =====================================================
-- REPORTE 5: TOP 10 PILOTOS GANADORES EUROPA vs AMÉRICA
-- Visual: Barras apiladas (por piloto)
-- =====================================================

SELECT 
  dd.full_name AS piloto,
  dd.nationality AS nacionalidad,
  SUM(CASE WHEN dc.continent = 'Europe' AND fr.is_winner THEN 1 ELSE 0 END) AS victorias_europa,
  SUM(CASE WHEN dc.continent IN ('North America','South America') AND fr.is_winner 
           THEN 1 ELSE 0 END) AS victorias_america,
  SUM(CASE WHEN fr.is_winner THEN 1 ELSE 0 END) AS victorias_totales
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_circuit dc ON dr.circuit_id = dc.circuit_id
GROUP BY dd.full_name, dd.nationality
HAVING SUM(CASE WHEN fr.is_winner THEN 1 ELSE 0 END) >= 5
ORDER BY victorias_totales DESC
LIMIT 10;

/*
Visual:
- Barras apiladas:
  - Eje Y: piloto
  - Valores: victorias_europa, victorias_america
  - Tooltip: nacionalidad, victorias_totales
*/


-- =====================================================
-- KPIs GENERALES (para tarjetas en el dashboard)
-- =====================================================

SELECT 
  COUNT(DISTINCT driver_id) AS total_pilotos,
  COUNT(DISTINCT constructor_id) AS total_escuderias,
  COUNT(DISTINCT sk_race) AS total_carreras,
  SUM(points) AS puntos_totales,
  COUNT(CASE WHEN is_winner THEN 1 END) AS total_victorias
FROM fact_results;

/*
En PowerBI:
- Crear \"Tarjetas\" (Card visual) para cada KPI:
  - total_pilotos, total_escuderias, total_carreras, puntos_totales, total_victorias
*/


