-- =====================================================
-- ANÁLISIS DE DATOS - FORMULA 1 DATA WAREHOUSE
-- Queries para responder las preguntas del práctico
-- =====================================================

-- =====================================================
-- 1. PILOTOS CON MÁS CARRERAS
-- =====================================================
-- Top 20 pilotos con más participaciones en carreras
SELECT 
    dd.full_name as piloto,
    dd.nationality as nacionalidad,
    COUNT(DISTINCT fr.sk_race) as total_carreras,
    MIN(dr.race_year) as primera_temporada,
    MAX(dr.race_year) as ultima_temporada
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY dd.full_name, dd.nationality
ORDER BY total_carreras DESC
LIMIT 20;


-- =====================================================
-- 2. PILOTOS CON MÁS CARRERAS GANADAS EN UN PERÍODO
-- =====================================================
-- Top 20 pilotos con más victorias (parametrizable por año)
-- Cambiar los años según el período deseado
SELECT 
    dd.full_name as piloto,
    dd.nationality as nacionalidad,
    COUNT(*) as victorias,
    MIN(dr.race_year) as primera_victoria,
    MAX(dr.race_year) as ultima_victoria
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
WHERE fr.is_winner = true
  AND dr.race_year BETWEEN 2010 AND 2024  -- Modificar período aquí
GROUP BY dd.full_name, dd.nationality
ORDER BY victorias DESC
LIMIT 20;

-- Victorias por año y piloto
SELECT 
    dr.race_year as año,
    dd.full_name as piloto,
    COUNT(*) as victorias
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
WHERE fr.is_winner = true
GROUP BY dr.race_year, dd.full_name
ORDER BY dr.race_year DESC, victorias DESC;


-- =====================================================
-- 3. PILOTOS CON MÁS PARADAS EN UN PERÍODO
-- =====================================================
SELECT 
    dd.full_name as piloto,
    COUNT(*) as total_paradas,
    ROUND(AVG(fps.duration_seconds)::numeric, 3) as promedio_duracion_seg,
    MIN(fps.duration_seconds) as mejor_parada_seg,
    COUNT(DISTINCT fps.sk_race) as carreras_con_paradas
FROM fact_pit_stops fps
JOIN dim_driver dd ON fps.sk_driver = dd.sk_driver
WHERE fps.race_year BETWEEN 2011 AND 2024  -- Modificar período aquí
GROUP BY dd.full_name
ORDER BY total_paradas DESC
LIMIT 20;


-- =====================================================
-- 4. COMPARACIÓN DE PARADAS VS CARRERAS GANADAS
-- =====================================================
-- Análisis de correlación entre paradas y victorias
WITH paradas_piloto AS (
    SELECT 
        dd.driver_id,
        dd.full_name,
        COUNT(*) as total_paradas,
        ROUND(AVG(fps.duration_seconds)::numeric, 3) as promedio_parada
    FROM fact_pit_stops fps
    JOIN dim_driver dd ON fps.sk_driver = dd.sk_driver
    WHERE fps.duration_seconds IS NOT NULL
    GROUP BY dd.driver_id, dd.full_name
),
victorias_piloto AS (
    SELECT 
        dd.driver_id,
        COUNT(*) as victorias
    FROM fact_results fr
    JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
    WHERE fr.is_winner = true
      AND fr.race_year >= 2011  -- Era de pit stops registrados
    GROUP BY dd.driver_id
)
SELECT 
    pp.full_name as piloto,
    pp.total_paradas,
    pp.promedio_parada as promedio_duracion_parada,
    COALESCE(vp.victorias, 0) as victorias,
    ROUND((COALESCE(vp.victorias, 0)::numeric / pp.total_paradas * 100), 2) as ratio_victorias_por_parada
FROM paradas_piloto pp
LEFT JOIN victorias_piloto vp ON pp.driver_id = vp.driver_id
WHERE pp.total_paradas > 50
ORDER BY victorias DESC
LIMIT 30;


-- =====================================================
-- 5. RESULTADOS FINALES DE CAMPEONATOS
-- =====================================================
-- Campeones de pilotos por año (última carrera de cada temporada)
WITH ultima_carrera AS (
    SELECT race_year, MAX(race_round) as ultimo_round
    FROM dim_race
    GROUP BY race_year
)
SELECT 
    dr.race_year as temporada,
    dd.full_name as campeon,
    dd.nationality as nacionalidad,
    fds.points as puntos_totales,
    fds.wins as victorias
FROM fact_driver_standings fds
JOIN dim_driver dd ON fds.sk_driver = dd.sk_driver
JOIN dim_race dr ON fds.sk_race = dr.sk_race
JOIN ultima_carrera uc ON dr.race_year = uc.race_year AND dr.race_round = uc.ultimo_round
WHERE fds.position = 1
ORDER BY dr.race_year DESC;

-- Campeones de constructores por año
WITH ultima_carrera AS (
    SELECT race_year, MAX(race_round) as ultimo_round
    FROM dim_race
    GROUP BY race_year
)
SELECT 
    dr.race_year as temporada,
    dc.constructor_name as constructor_campeon,
    dc.nationality as nacionalidad,
    fcs.points as puntos_totales,
    fcs.wins as victorias
FROM fact_constructor_standings fcs
JOIN dim_constructor dc ON fcs.sk_constructor = dc.sk_constructor
JOIN dim_race dr ON fcs.sk_race = dr.sk_race
JOIN ultima_carrera uc ON dr.race_year = uc.race_year AND dr.race_round = uc.ultimo_round
WHERE fcs.position = 1
ORDER BY dr.race_year DESC;


-- =====================================================
-- 6. RESULTADOS DE CONSTRUCTORES
-- =====================================================
-- Historial de constructores con más victorias
SELECT 
    dc.constructor_name as constructor,
    dc.nationality as nacionalidad,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios,
    SUM(fr.points) as puntos_totales,
    COUNT(DISTINCT fr.sk_race) as carreras_participadas,
    MIN(dr.race_year) as desde,
    MAX(dr.race_year) as hasta
FROM fact_results fr
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY dc.constructor_name, dc.nationality
ORDER BY victorias DESC
LIMIT 20;


-- =====================================================
-- 7. MEJOR ESTRATEGIA DE PARADA POR CIRCUITO
-- =====================================================
-- Análisis de pit stops por circuito para estrategia óptima
SELECT 
    dc.circuit_name as circuito,
    dc.country as pais,
    ROUND(AVG(paradas.num_paradas)::numeric, 1) as promedio_paradas,
    MODE() WITHIN GROUP (ORDER BY paradas.num_paradas) as paradas_mas_comun,
    ROUND(AVG(paradas.duracion_total)::numeric, 2) as duracion_promedio_total,
    COUNT(DISTINCT paradas.race_id) as carreras_analizadas
FROM (
    SELECT 
        fps.race_id,
        dr.circuit_id,
        fps.driver_id,
        COUNT(*) as num_paradas,
        SUM(fps.duration_seconds) as duracion_total
    FROM fact_pit_stops fps
    JOIN dim_race dr ON fps.sk_race = dr.sk_race
    WHERE fps.duration_seconds IS NOT NULL
    GROUP BY fps.race_id, dr.circuit_id, fps.driver_id
) paradas
JOIN dim_circuit dc ON paradas.circuit_id = dc.circuit_id
GROUP BY dc.circuit_name, dc.country
ORDER BY promedio_paradas DESC;

-- Estrategia ganadora por circuito
WITH estrategia_ganadores AS (
    SELECT 
        dr.circuit_id,
        fps.race_id,
        fps.driver_id,
        COUNT(*) as num_paradas
    FROM fact_pit_stops fps
    JOIN fact_results fr ON fps.sk_race = fr.sk_race AND fps.sk_driver = fr.sk_driver
    JOIN dim_race dr ON fps.sk_race = dr.sk_race
    WHERE fr.is_winner = true
    GROUP BY dr.circuit_id, fps.race_id, fps.driver_id
)
SELECT 
    dc.circuit_name as circuito,
    dc.country as pais,
    ROUND(AVG(eg.num_paradas)::numeric, 1) as paradas_promedio_ganadores,
    MODE() WITHIN GROUP (ORDER BY eg.num_paradas) as paradas_ganadoras_mas_comun,
    COUNT(*) as carreras_analizadas
FROM estrategia_ganadores eg
JOIN dim_circuit dc ON eg.circuit_id = dc.circuit_id
GROUP BY dc.circuit_name, dc.country
HAVING COUNT(*) >= 3
ORDER BY paradas_promedio_ganadores;


-- =====================================================
-- 8. PILOTOS QUE GANARON EN CIRCUITOS ESPECÍFICOS Y CAMPEONATOS
-- =====================================================
-- "Aquellos pilotos que siempre ganaron en Canadá, han terminado ganando el campeonato mundial"

-- Pilotos que ganaron en Canadá
WITH ganadores_canada AS (
    SELECT DISTINCT dd.driver_id, dd.full_name
    FROM fact_results fr
    JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
    JOIN dim_race dr ON fr.sk_race = dr.sk_race
    WHERE fr.is_winner = true
      AND dr.race_name ILIKE '%Canada%'
),
-- Campeones mundiales
campeones AS (
    SELECT DISTINCT fds.driver_id
    FROM fact_driver_standings fds
    JOIN dim_race dr ON fds.sk_race = dr.sk_race
    WHERE fds.position = 1
      AND dr.race_round = (
          SELECT MAX(race_round) FROM dim_race dr2 WHERE dr2.race_year = dr.race_year
      )
)
SELECT 
    gc.full_name as piloto,
    CASE WHEN c.driver_id IS NOT NULL THEN 'Sí' ELSE 'No' END as es_campeon_mundial
FROM ganadores_canada gc
LEFT JOIN campeones c ON gc.driver_id = c.driver_id
ORDER BY es_campeon_mundial DESC, gc.full_name;

-- Análisis más complejo: Pilotos que ganaron en múltiples circuitos específicos
WITH ganadores_por_circuito AS (
    SELECT 
        dd.driver_id,
        dd.full_name,
        dr.race_name,
        COUNT(*) as victorias_circuito
    FROM fact_results fr
    JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
    JOIN dim_race dr ON fr.sk_race = dr.sk_race
    WHERE fr.is_winner = true
    GROUP BY dd.driver_id, dd.full_name, dr.race_name
),
campeones AS (
    SELECT DISTINCT fds.driver_id
    FROM fact_driver_standings fds
    JOIN dim_race dr ON fds.sk_race = dr.sk_race
    WHERE fds.position = 1
      AND dr.race_round = (
          SELECT MAX(race_round) FROM dim_race dr2 WHERE dr2.race_year = dr.race_year
      )
)
SELECT 
    gpc.full_name as piloto,
    STRING_AGG(DISTINCT gpc.race_name, ', ' ORDER BY gpc.race_name) as circuitos_ganados,
    COUNT(DISTINCT gpc.race_name) as num_circuitos_diferentes,
    CASE WHEN c.driver_id IS NOT NULL THEN 'Sí' ELSE 'No' END as es_campeon_mundial
FROM ganadores_por_circuito gpc
LEFT JOIN campeones c ON gpc.driver_id = c.driver_id
GROUP BY gpc.driver_id, gpc.full_name, c.driver_id
HAVING COUNT(DISTINCT gpc.race_name) >= 5
ORDER BY es_campeon_mundial DESC, num_circuitos_diferentes DESC;


-- =====================================================
-- 9. PILOTOS CON MEJOR TIEMPO VS RESULTADO DE CARRERA
-- =====================================================
-- ¿Los pilotos con vuelta más rápida ganan la carrera?
WITH vuelta_rapida AS (
    SELECT 
        fr.sk_race,
        fr.sk_driver,
        fr.fastest_lap_rank
    FROM fact_results fr
    WHERE fr.fastest_lap_rank = 1
)
SELECT 
    CASE 
        WHEN fr.is_winner THEN 'Ganó la carrera'
        WHEN fr.is_podium THEN 'Top 3 (no ganó)'
        ELSE 'Fuera del podio'
    END as resultado,
    COUNT(*) as cantidad,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as porcentaje
FROM fact_results fr
JOIN vuelta_rapida vr ON fr.sk_race = vr.sk_race AND fr.sk_driver = vr.sk_driver
GROUP BY 
    CASE 
        WHEN fr.is_winner THEN 'Ganó la carrera'
        WHEN fr.is_podium THEN 'Top 3 (no ganó)'
        ELSE 'Fuera del podio'
    END
ORDER BY porcentaje DESC;


-- =====================================================
-- 10. RÉCORDS DE VUELTA POR TERCIO DE CARRERA
-- =====================================================
-- En qué tercio de la carrera se dan más vueltas rápidas
SELECT 
    CASE lap_tercile
        WHEN 1 THEN 'Primer tercio (inicio)'
        WHEN 2 THEN 'Segundo tercio (medio)'
        WHEN 3 THEN 'Tercer tercio (final)'
        ELSE 'Sin clasificar'
    END as tercio_carrera,
    COUNT(*) as vueltas_rapidas,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as porcentaje
FROM fact_lap_times
WHERE is_fastest_lap = true
  AND lap_tercile IS NOT NULL
GROUP BY lap_tercile
ORDER BY lap_tercile;


-- =====================================================
-- 11. PILOTOS QUE REMONTARON AL PODIO
-- =====================================================
-- Pilotos que clasificaron fuera del top 3 pero terminaron en podio
-- y su posición en récord de vuelta
SELECT 
    dd.full_name as piloto,
    COUNT(*) as remontadas_al_podio,
    ROUND(AVG(fr.fastest_lap_rank)::numeric, 1) as posicion_promedio_vuelta_rapida,
    MIN(fr.fastest_lap_rank) as mejor_posicion_vuelta_rapida,
    ROUND(AVG(fr.grid_position)::numeric, 1) as posicion_promedio_salida,
    ROUND(AVG(fr.positions_gained)::numeric, 1) as posiciones_ganadas_promedio
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
WHERE fr.grid_position > 3  -- No clasificó en top 3
  AND fr.is_podium = true   -- Pero terminó en podio
  AND fr.fastest_lap_rank IS NOT NULL
GROUP BY dd.full_name
HAVING COUNT(*) >= 3
ORDER BY remontadas_al_podio DESC
LIMIT 20;


-- =====================================================
-- 12. NACIONALIDAD DE PILOTOS MÁS EXITOSOS
-- =====================================================
-- Si fuera director de equipo, ¿de qué nacionalidad buscaría pilotos?
SELECT 
    dd.nationality as nacionalidad,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias_totales,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios_totales,
    SUM(fr.points) as puntos_totales,
    ROUND(SUM(fr.points)::numeric / COUNT(DISTINCT dd.driver_id), 2) as puntos_por_piloto,
    ROUND(COUNT(CASE WHEN fr.is_winner THEN 1 END)::numeric / COUNT(DISTINCT dd.driver_id), 2) as victorias_por_piloto
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
GROUP BY dd.nationality
HAVING COUNT(DISTINCT dd.driver_id) >= 5
ORDER BY victorias_por_piloto DESC
LIMIT 20;

-- Rendimiento por nacionalidad en los últimos 10 años
SELECT 
    dd.nationality as nacionalidad,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    ROUND(AVG(fr.final_position)::numeric, 2) as posicion_promedio,
    SUM(fr.points) as puntos_totales
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
WHERE fr.race_year >= 2014
  AND fr.final_position IS NOT NULL
GROUP BY dd.nationality
HAVING COUNT(DISTINCT dd.driver_id) >= 2
ORDER BY victorias DESC, posicion_promedio ASC
LIMIT 15;


-- =====================================================
-- 13. IMPACTO DE LA ALTURA EN EL RENDIMIENTO
-- =====================================================
-- Análisis de rendimiento según altitud del circuito
SELECT 
    CASE 
        WHEN dc.altitude < 100 THEN 'Bajo nivel del mar (<100m)'
        WHEN dc.altitude BETWEEN 100 AND 500 THEN 'Baja altitud (100-500m)'
        WHEN dc.altitude BETWEEN 500 AND 1000 THEN 'Media altitud (500-1000m)'
        WHEN dc.altitude > 1000 THEN 'Alta altitud (>1000m)'
        ELSE 'Sin datos'
    END as categoria_altitud,
    COUNT(DISTINCT dc.circuit_id) as num_circuitos,
    COUNT(DISTINCT fr.sk_race) as num_carreras,
    ROUND(AVG(CASE WHEN fr.is_winner THEN fr.grid_position END)::numeric, 2) as posicion_salida_promedio_ganador,
    ROUND(AVG(fps.duration_seconds)::numeric, 3) as duracion_pit_stop_promedio,
    COUNT(DISTINCT CASE WHEN ds.status_description != 'Finished' THEN fr.sk_result END) as abandonos
FROM fact_results fr
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_circuit dc ON dr.circuit_id = dc.circuit_id
LEFT JOIN dim_status ds ON fr.sk_status = ds.sk_status
LEFT JOIN fact_pit_stops fps ON fr.sk_race = fps.sk_race AND fr.sk_driver = fps.sk_driver
WHERE dc.altitude IS NOT NULL
GROUP BY 
    CASE 
        WHEN dc.altitude < 100 THEN 'Bajo nivel del mar (<100m)'
        WHEN dc.altitude BETWEEN 100 AND 500 THEN 'Baja altitud (100-500m)'
        WHEN dc.altitude BETWEEN 500 AND 1000 THEN 'Media altitud (500-1000m)'
        WHEN dc.altitude > 1000 THEN 'Alta altitud (>1000m)'
        ELSE 'Sin datos'
    END
ORDER BY categoria_altitud;

-- Circuitos ordenados por altitud con métricas de rendimiento
SELECT 
    dc.circuit_name as circuito,
    dc.country as pais,
    dc.altitude as altitud_metros,
    COUNT(DISTINCT fr.sk_race) as carreras,
    ROUND(AVG(fr.laps_completed)::numeric, 0) as vueltas_promedio,
    COUNT(CASE WHEN ds.is_finished = false THEN 1 END) as retiros_totales,
    ROUND(COUNT(CASE WHEN ds.is_finished = false THEN 1 END) * 100.0 / COUNT(*), 2) as porcentaje_retiros
FROM fact_results fr
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_circuit dc ON dr.circuit_id = dc.circuit_id
LEFT JOIN dim_status ds ON fr.sk_status = ds.sk_status
WHERE dc.altitude IS NOT NULL
GROUP BY dc.circuit_name, dc.country, dc.altitude
ORDER BY dc.altitude DESC;


-- =====================================================
-- 14. ANÁLISIS ADICIONAL: EVOLUCIÓN HISTÓRICA
-- =====================================================
-- Evolución de puntos por temporada
SELECT 
    dr.race_year as temporada,
    COUNT(DISTINCT dr.race_id) as num_carreras,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(DISTINCT dc.constructor_id) as num_constructores,
    SUM(fr.points) as puntos_totales_temporada,
    ROUND(AVG(fr.points)::numeric, 2) as puntos_promedio_por_resultado
FROM fact_results fr
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
GROUP BY dr.race_year
ORDER BY dr.race_year DESC;


-- =====================================================
-- 15. ANÁLISIS ADICIONAL: DOMINIO POR ERA
-- =====================================================
-- Pilotos más dominantes por década
SELECT 
    CONCAT(FLOOR(dr.race_year / 10) * 10, 's') as decada,
    dd.full_name as piloto,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios,
    COUNT(DISTINCT fr.sk_race) as carreras
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY FLOOR(dr.race_year / 10) * 10, dd.full_name
HAVING COUNT(CASE WHEN fr.is_winner THEN 1 END) >= 5
ORDER BY decada DESC, victorias DESC;

