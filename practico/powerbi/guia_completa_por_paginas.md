# Guía Completa PowerBI - Fórmula 1 por Páginas Temáticas

## Estructura del Reporte

Este documento organiza todos los análisis en **8 páginas temáticas** en PowerBI, cada una con múltiples visualizaciones.

---

## 📄 PÁGINA 1: ANÁLISIS DE PILOTOS

### Visualización 1.1: Top 20 Pilotos con Más Carreras

**Tipo**: Tabla o Gráfico de barras horizontales

**Query SQL**:

```sql
SELECT
    dd.full_name as piloto,
    dd.nationality as nacionalidad,
    COUNT(DISTINCT fr.sk_race) as total_carreras,
    MIN(dr.race_year) as primera_temporada,
    MAX(dr.race_year) as ultima_temporada,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    SUM(fr.points) as puntos_totales
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY dd.full_name, dd.nationality
ORDER BY total_carreras DESC
LIMIT 20;
```

**En PowerBI**:

- **Tabla**: Arrastra todas las columnas
- **Gráfico de barras**:
  - Eje Y: `piloto`
  - Eje X: `total_carreras`
  - Tooltip: `nacionalidad`, `victorias`, `puntos_totales`

---

### Visualización 1.2: Pilotos con Más Carreras Ganadas (Filtrable por Período)

**Tipo**: Gráfico de barras + Filtro de año

**Query SQL**:

```sql
SELECT
    dr.race_year as año,
    dd.full_name as piloto,
    dd.nationality as nacionalidad,
    COUNT(*) as victorias
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
WHERE fr.is_winner = true
GROUP BY dr.race_year, dd.full_name, dd.nationality
ORDER BY dr.race_year DESC, victorias DESC;
```

**En PowerBI**:

- **Gráfico de barras agrupadas**:
  - Eje X: `año`
  - Eje Y: `victorias`
  - Leyenda: `piloto`
- **Filtro de segmentación**: `año` (rango de años)

---

### Visualización 1.3: Pilotos con Más Paradas en Boxes

**Tipo**: Tabla + Gráfico de barras

**Query SQL**:

```sql
SELECT
    dd.full_name as piloto,
    COUNT(*) as total_paradas,
    ROUND(AVG(fps.duration_seconds)::numeric, 3) as promedio_duracion_seg,
    MIN(fps.duration_seconds) as mejor_parada_seg,
    COUNT(DISTINCT fps.sk_race) as carreras_con_paradas,
    MAX(fps.race_year) as ultimo_año
FROM fact_pit_stops fps
JOIN dim_driver dd ON fps.sk_driver = dd.sk_driver
GROUP BY dd.full_name
ORDER BY total_paradas DESC
LIMIT 20;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de barras**:
  - Eje Y: `piloto`
  - Eje X: `total_paradas`
  - Color: `promedio_duracion_seg` (escala de colores)

---

### Visualización 1.4: Comparación Paradas vs Carreras Ganadas

**Tipo**: Gráfico de dispersión (Scatter Chart)

**Query SQL**:

```sql
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
      AND fr.race_year >= 2011
    GROUP BY dd.driver_id
)
SELECT
    pp.full_name as piloto,
    pp.total_paradas,
    pp.promedio_parada as promedio_duracion_parada,
    COALESCE(vp.victorias, 0) as victorias,
    ROUND((COALESCE(vp.victorias, 0)::numeric / NULLIF(pp.total_paradas, 0) * 100), 2) as ratio_victorias_por_parada
FROM paradas_piloto pp
LEFT JOIN victorias_piloto vp ON pp.driver_id = vp.driver_id
WHERE pp.total_paradas > 50
ORDER BY victorias DESC;
```

**En PowerBI**:

- **Gráfico de dispersión**:
  - Eje X: `total_paradas`
  - Eje Y: `victorias`
  - Tamaño: `promedio_duracion_parada`
  - Leyenda: `piloto`
  - Tooltip: `ratio_victorias_por_parada`

---

## 📄 PÁGINA 2: CAMPEONATOS Y RESULTADOS

### Visualización 2.1: Resultados Finales de Campeonatos - Pilotos

**Tipo**: Tabla + Gráfico de líneas temporal

**Query SQL**:

```sql
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
    fds.wins as victorias,
    fds.position as posicion_final
FROM fact_driver_standings fds
JOIN dim_driver dd ON fds.sk_driver = dd.sk_driver
JOIN dim_race dr ON fds.sk_race = dr.sk_race
JOIN ultima_carrera uc ON dr.race_year = uc.race_year AND dr.race_round = uc.ultimo_round
WHERE fds.position <= 3
ORDER BY dr.race_year DESC, fds.position ASC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas, filtrar por `posicion_final = 1` para campeones
- **Gráfico de líneas**:
  - Eje X: `temporada`
  - Eje Y: `puntos_totales`
  - Leyenda: `campeon`
- **Gráfico de barras horizontales**:
  - Eje Y: `campeon`
  - Eje X: Medida `COUNT(temporada)` (número de campeonatos)

---

### Visualización 2.2: Resultados de Constructores

**Tipo**: Tabla + Gráfico de barras

**Query SQL**:

```sql
SELECT
    dc.constructor_name as constructor,
    dc.nationality as nacionalidad,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios,
    SUM(fr.points) as puntos_totales,
    COUNT(DISTINCT fr.sk_race) as carreras_participadas,
    MIN(dr.race_year) as desde,
    MAX(dr.race_year) as hasta,
    ROUND(SUM(fr.points)::numeric / NULLIF(COUNT(DISTINCT fr.sk_race), 0), 2) as puntos_por_carrera
FROM fact_results fr
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY dc.constructor_name, dc.nationality
ORDER BY victorias DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de barras**:
  - Eje X: `constructor`
  - Valores: `victorias`, `podios`
  - Ordenar por: `victorias` DESC

---

### Visualización 2.3: Campeones de Constructores por Año

**Tipo**: Tabla

**Query SQL**:

```sql
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
```

**En PowerBI**:

- **Tabla**: Todas las columnas

---

## 📄 PÁGINA 3: ESTRATEGIAS DE PIT STOPS

### Visualización 3.1: Mejor Estrategia de Parada por Circuito

**Tipo**: Tabla + Gráfico de barras

**Query SQL**:

```sql
WITH estrategia_ganadores AS (
    SELECT
        dr.circuit_id,
        dr.race_id,
        fps.driver_id,
        COUNT(*) as num_paradas,
        ROUND(AVG(fps.duration_seconds)::numeric, 3) as duracion_promedio
    FROM fact_pit_stops fps
    JOIN fact_results fr ON fps.sk_race = fr.sk_race AND fps.sk_driver = fr.sk_driver
    JOIN dim_race dr ON fps.sk_race = dr.sk_race
    WHERE fr.is_winner = true
    GROUP BY dr.circuit_id, dr.race_id, fps.driver_id
)
SELECT
    dc.circuit_name as circuito,
    dc.country as pais,
    ROUND(AVG(eg.num_paradas)::numeric, 1) as paradas_promedio_ganadores,
    MODE() WITHIN GROUP (ORDER BY eg.num_paradas) as paradas_ganadoras_mas_comun,
    ROUND(AVG(eg.duracion_promedio)::numeric, 3) as duracion_promedio_paradas,
    COUNT(*) as carreras_analizadas
FROM estrategia_ganadores eg
JOIN dim_circuit dc ON eg.circuit_id = dc.circuit_id
GROUP BY dc.circuit_name, dc.country
HAVING COUNT(*) >= 3
ORDER BY paradas_promedio_ganadores;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de barras**:
  - Eje X: `circuito`
  - Eje Y: `paradas_ganadoras_mas_comun`
  - Color: `paradas_promedio_ganadores` (escala)

---

### Visualización 3.2: Análisis de Paradas por Circuito (Todos los Resultados)

**Tipo**: Tabla

**Query SQL**:

```sql
SELECT
    dc.circuit_name as circuito,
    dc.country as pais,
    ROUND(AVG(paradas.num_paradas)::numeric, 1) as promedio_paradas,
    MODE() WITHIN GROUP (ORDER BY paradas.num_paradas) as paradas_mas_comun,
    ROUND(AVG(paradas.duracion_total)::numeric, 2) as duracion_promedio_total,
    COUNT(DISTINCT paradas.race_id) as carreras_analizadas
FROM (
    SELECT
        fps.sk_race,
        dr.circuit_id,
        fps.driver_id,
        COUNT(*) as num_paradas,
        SUM(fps.duration_seconds) as duracion_total
    FROM fact_pit_stops fps
    JOIN dim_race dr ON fps.sk_race = dr.sk_race
    WHERE fps.duration_seconds IS NOT NULL
    GROUP BY fps.sk_race, dr.circuit_id, fps.driver_id
) paradas
JOIN dim_circuit dc ON paradas.circuit_id = dc.circuit_id
GROUP BY dc.circuit_name, dc.country
ORDER BY promedio_paradas DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas

---

## 📄 PÁGINA 4: ANÁLISIS PREDICTIVO DE CIRCUITOS

### Visualización 4.1: Pilotos que Ganaron en Circuitos Específicos y Ganaron Campeonato

**Tipo**: Tabla interactiva con filtros

**Query SQL**:

```sql
WITH ganadores_circuito AS (
    SELECT
        dd.driver_id,
        dd.full_name as piloto,
        dr.race_name as circuito,
        COUNT(*) as victorias_circuito
    FROM fact_results fr
    JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
    JOIN dim_race dr ON fr.sk_race = dr.sk_race
    WHERE fr.is_winner = true
    GROUP BY dd.driver_id, dd.full_name, dr.race_name
),
total_circuitos AS (
    SELECT
        driver_id,
        COUNT(DISTINCT circuito) as total_circuitos_ganados
    FROM ganadores_circuito
    GROUP BY driver_id
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
    gc.piloto,
    gc.circuito,
    gc.victorias_circuito,
    CASE WHEN c.driver_id IS NOT NULL THEN 'Sí' ELSE 'No' END as es_campeon_mundial,
    tc.total_circuitos_ganados
FROM ganadores_circuito gc
LEFT JOIN campeones c ON gc.driver_id = c.driver_id
LEFT JOIN total_circuitos tc ON gc.driver_id = tc.driver_id
ORDER BY es_campeon_mundial DESC, gc.victorias_circuito DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Filtros**:
  - `circuito` (selección múltiple)
  - `es_campeon_mundial` (Sí/No)
- **Gráfico de barras**:
  - Eje Y: `piloto`
  - Eje X: `total_circuitos_ganados`
  - Color: `es_campeon_mundial`

---

### Visualización 4.2: Análisis Complejo - Múltiples Circuitos

**Tipo**: Tabla con lógica condicional

**Query SQL**:

```sql
WITH ganadores_por_circuito AS (
    SELECT
        dd.driver_id,
        dd.full_name as piloto,
        dr.race_name as circuito,
        COUNT(*) as victorias
    FROM fact_results fr
    JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
    JOIN dim_race dr ON fr.sk_race = dr.sk_race
    WHERE fr.is_winner = true
    GROUP BY dd.driver_id, dd.full_name, dr.race_name
),
circuitos_ganados AS (
    SELECT
        driver_id,
        piloto,
        STRING_AGG(DISTINCT circuito, ', ' ORDER BY circuito) as circuitos_ganados,
        COUNT(DISTINCT circuito) as num_circuitos_diferentes
    FROM ganadores_por_circuito
    GROUP BY driver_id, piloto
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
    cg.piloto,
    cg.circuitos_ganados,
    cg.num_circuitos_diferentes,
    CASE WHEN c.driver_id IS NOT NULL THEN 'Sí' ELSE 'No' END as es_campeon_mundial
FROM circuitos_ganados cg
LEFT JOIN campeones c ON cg.driver_id = c.driver_id
WHERE cg.num_circuitos_diferentes >= 5
ORDER BY es_campeon_mundial DESC, cg.num_circuitos_diferentes DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Filtro de texto**: Buscar circuitos específicos en `circuitos_ganados`

---

### Visualización 4.3: Circuitos Más Ganados por Campeones del Mundo

**Tipo**: Gráfico de barras horizontales + Tabla

**Objetivo**: Identificar qué circuitos han sido ganados más veces por pilotos que luego se convirtieron en campeones del mundo.

**Query SQL**:

```sql
WITH campeones AS (
    SELECT DISTINCT fds.driver_id
    FROM fact_driver_standings fds
    JOIN dim_race dr ON fds.sk_race = dr.sk_race
    WHERE fds.position = 1
      AND dr.race_round = (
          SELECT MAX(race_round) FROM dim_race dr2 WHERE dr2.race_year = dr.race_year
      )
),
victorias_campeones_circuito AS (
    SELECT
        dr.race_name as circuito,
        dc.circuit_name as nombre_circuito,
        dc.country as pais,
        dc.continent as continente,
        COUNT(*) as victorias_campeones,
        COUNT(DISTINCT fr.driver_id) as campeones_diferentes
    FROM fact_results fr
    JOIN dim_race dr ON fr.sk_race = dr.sk_race
    JOIN dim_circuit dc ON dr.circuit_id = dc.circuit_id
    JOIN campeones c ON fr.driver_id = c.driver_id
    WHERE fr.is_winner = true
    GROUP BY dr.race_name, dc.circuit_name, dc.country, dc.continent
)
SELECT
    circuito,
    nombre_circuito,
    pais,
    continente,
    victorias_campeones,
    campeones_diferentes,
    ROUND(victorias_campeones::numeric / NULLIF(campeones_diferentes, 0), 2) as promedio_victorias_por_campeon
FROM victorias_campeones_circuito
ORDER BY victorias_campeones DESC;
```

**En PowerBI**:

- **Gráfico de barras horizontales** (RECOMENDADO):

  - **Eje Y**: `circuito` o `nombre_circuito`
  - **Eje X**: `victorias_campeones`
  - **Color**: `continente` (leyenda)
  - **Tooltip**: `pais`, `campeones_diferentes`, `promedio_victorias_por_campeon`
  - **Ordenar por**: `victorias_campeones` DESC (descendente)
  - **Filtro**: Top N (ej: Top 15 o Top 20)

- **Tabla**: Todas las columnas, ordenada por `victorias_campeones` DESC

- **Gráfico de barras verticales** (alternativa):
  - **Eje X**: `circuito` (rotar etiquetas 45°)
  - **Eje Y**: `victorias_campeones`
  - **Leyenda**: `continente`

**Interpretación**:

- Los circuitos con más `victorias_campeones` son los que más veces han sido ganados por futuros campeones del mundo
- `campeones_diferentes` muestra cuántos campeones diferentes ganaron en ese circuito
- `promedio_victorias_por_campeon` indica si un circuito es dominado por pocos campeones o distribuido entre varios

**Ejemplo**: Si "Monaco" tiene 25 victorias de campeones y 8 campeones diferentes, significa que varios campeones han ganado múltiples veces allí.

---

## 📄 PÁGINA 5: RENDIMIENTO EN CARRERAS

### Visualización 5.1: Pilotos con Mejor Tiempo vs Resultado Final

**Tipo**: Gráfico de anillo (Donut) + Tabla

**Query SQL**:

```sql
SELECT
    CASE
        WHEN fr.is_winner THEN 'Ganó la carrera'
        WHEN fr.is_podium THEN 'Top 3 (no ganó)'
        ELSE 'Fuera del podio'
    END as resultado,
    COUNT(*) as cantidad,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as porcentaje
FROM fact_results fr
WHERE fr.fastest_lap_rank = 1
GROUP BY
    CASE
        WHEN fr.is_winner THEN 'Ganó la carrera'
        WHEN fr.is_podium THEN 'Top 3 (no ganó)'
        ELSE 'Fuera del podio'
    END
ORDER BY porcentaje DESC;
```

**En PowerBI**:

- **Gráfico de anillo**:
  - Valores: `cantidad`
  - Leyenda: `resultado`
- **Tarjeta KPI**: `porcentaje` para "Ganó la carrera"

---

### Visualización 5.2: Récords de Vuelta por Tercio de Carrera

**Tipo**: Gráfico de barras + Gráfico de anillo

**Query SQL**:

```sql
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
```

**En PowerBI**:

- **Gráfico de barras**:
  - Eje X: `tercio_carrera`
  - Eje Y: `vueltas_rapidas`
- **Gráfico de anillo**:
  - Valores: `vueltas_rapidas`
  - Leyenda: `tercio_carrera`

---

### Visualización 5.3: Pilotos que Remontaron al Podio

**Tipo**: Tabla + Gráfico de barras

**Query SQL**:

```sql
SELECT
    dd.full_name as piloto,
    COUNT(*) as remontadas_al_podio,
    ROUND(AVG(fr.fastest_lap_rank)::numeric, 1) as posicion_promedio_vuelta_rapida,
    MIN(fr.fastest_lap_rank) as mejor_posicion_vuelta_rapida,
    ROUND(AVG(fr.grid_position)::numeric, 1) as posicion_promedio_salida,
    ROUND(AVG(fr.positions_gained)::numeric, 1) as posiciones_ganadas_promedio
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
WHERE fr.grid_position > 3
  AND fr.is_podium = true
  AND fr.fastest_lap_rank IS NOT NULL
GROUP BY dd.full_name
HAVING COUNT(*) >= 3
ORDER BY remontadas_al_podio DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de barras**:
  - Eje Y: `piloto`
  - Eje X: `remontadas_al_podio`
  - Tooltip: `posiciones_ganadas_promedio`, `posicion_promedio_vuelta_rapida`

---

## 📄 PÁGINA 6: ANÁLISIS DE NACIONALIDADES

### Visualización 6.1: Nacionalidad de Pilotos Más Exitosos (Histórico)

**Tipo**: Gráfico de barras + Tabla

**Query SQL**:

```sql
SELECT
    dd.nationality as nacionalidad,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias_totales,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios_totales,
    SUM(fr.points) as puntos_totales,
    ROUND(SUM(fr.points)::numeric / NULLIF(COUNT(DISTINCT dd.driver_id), 0), 2) as puntos_por_piloto,
    ROUND(COUNT(CASE WHEN fr.is_winner THEN 1 END)::numeric / NULLIF(COUNT(DISTINCT dd.driver_id), 0), 2) as victorias_por_piloto
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
GROUP BY dd.nationality
HAVING COUNT(DISTINCT dd.driver_id) >= 5
ORDER BY victorias_por_piloto DESC;
```

**En PowerBI**:

- **Gráfico de barras**:
  - Eje X: `nacionalidad`
  - Eje Y: `victorias_por_piloto`
  - Color: `puntos_por_piloto` (escala)
- **Tabla**: Todas las columnas

---

### Visualización 6.2: Rendimiento por Nacionalidad (Últimos 10 Años)

**Tipo**: Gráfico de barras agrupadas

**Query SQL**:

```sql
SELECT
    dd.nationality as nacionalidad,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    ROUND(AVG(fr.final_position)::numeric, 2) as posicion_promedio,
    SUM(fr.points) as puntos_totales,
    ROUND(SUM(fr.points)::numeric / NULLIF(COUNT(DISTINCT dd.driver_id), 0), 2) as puntos_por_piloto
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
WHERE fr.race_year >= (EXTRACT(YEAR FROM CURRENT_DATE) - 10)
  AND fr.final_position IS NOT NULL
GROUP BY dd.nationality
HAVING COUNT(DISTINCT dd.driver_id) >= 2
ORDER BY victorias DESC, posicion_promedio ASC;
```

**En PowerBI**:

- **Gráfico de barras agrupadas**:
  - Eje X: `nacionalidad`
  - Valores: `victorias`, `puntos_por_piloto`
- **Tabla**: Todas las columnas

---

## 📄 PÁGINA 7: FACTORES AMBIENTALES

### Visualización 7.1: Impacto de la Altura en el Rendimiento

**Tipo**: Gráfico de barras + Tabla

**Query SQL**:

```sql
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
    COUNT(DISTINCT CASE WHEN ds.is_finished = false THEN fr.sk_result END) as abandonos,
    ROUND(COUNT(DISTINCT CASE WHEN ds.is_finished = false THEN fr.sk_result END) * 100.0 / COUNT(*), 2) as porcentaje_abandonos
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
```

**En PowerBI**:

- **Gráfico de barras**:
  - Eje X: `categoria_altitud`
  - Eje Y: `porcentaje_abandonos`
  - Color: `duracion_pit_stop_promedio` (escala)
- **Tabla**: Todas las columnas

---

### Visualización 7.2: Circuitos por Altitud con Métricas

**Tipo**: Tabla + Gráfico de dispersión

**Query SQL**:

```sql
SELECT
    dc.circuit_name as circuito,
    dc.country as pais,
    dc.altitude as altitud_metros,
    COUNT(DISTINCT fr.sk_race) as carreras,
    ROUND(AVG(fr.laps_completed)::numeric, 0) as vueltas_promedio,
    COUNT(CASE WHEN ds.is_finished = false THEN 1 END) as retiros_totales,
    ROUND(COUNT(CASE WHEN ds.is_finished = false THEN 1 END) * 100.0 / COUNT(*), 2) as porcentaje_retiros,
    ROUND(AVG(fps.duration_seconds)::numeric, 3) as duracion_pit_stop_promedio
FROM fact_results fr
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_circuit dc ON dr.circuit_id = dc.circuit_id
LEFT JOIN dim_status ds ON fr.sk_status = ds.sk_status
LEFT JOIN fact_pit_stops fps ON fr.sk_race = fps.sk_race AND fr.sk_driver = fps.sk_driver
WHERE dc.altitude IS NOT NULL
GROUP BY dc.circuit_name, dc.country, dc.altitude
ORDER BY dc.altitude DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de dispersión**:
  - Eje X: `altitud_metros`
  - Eje Y: `porcentaje_retiros`
  - Tamaño: `carreras`
  - Leyenda: `circuito`

---

## 📄 PÁGINA 8: ANÁLISIS ADICIONALES

### Visualización 8.1: Evolución Histórica de la Fórmula 1

**Tipo**: Gráfico de líneas múltiples

**Query SQL**:

```sql
SELECT
    dr.race_year as temporada,
    COUNT(DISTINCT dr.race_id) as num_carreras,
    COUNT(DISTINCT dd.driver_id) as num_pilotos,
    COUNT(DISTINCT dc.constructor_id) as num_constructores,
    SUM(fr.points) as puntos_totales_temporada,
    ROUND(AVG(fr.points)::numeric, 2) as puntos_promedio_por_resultado,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as total_victorias
FROM fact_results fr
JOIN dim_race dr ON fr.sk_race = dr.sk_race
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_constructor dc ON fr.sk_constructor = dc.sk_constructor
GROUP BY dr.race_year
ORDER BY dr.race_year DESC;
```

**En PowerBI**:

- **Gráfico de líneas múltiples**:
  - Eje X: `temporada`
  - Valores: `num_carreras`, `num_pilotos`, `num_constructores`
- **Gráfico de barras**:
  - Eje X: `temporada`
  - Eje Y: `puntos_totales_temporada`

---

### Visualización 8.2: Dominio por Década

**Tipo**: Tabla + Gráfico de barras

**Query SQL**:

```sql
SELECT
    CONCAT(FLOOR(dr.race_year / 10) * 10, 's') as decada,
    dd.full_name as piloto,
    COUNT(CASE WHEN fr.is_winner THEN 1 END) as victorias,
    COUNT(CASE WHEN fr.is_podium THEN 1 END) as podios,
    COUNT(DISTINCT fr.sk_race) as carreras,
    SUM(fr.points) as puntos_totales
FROM fact_results fr
JOIN dim_driver dd ON fr.sk_driver = dd.sk_driver
JOIN dim_race dr ON fr.sk_race = dr.sk_race
GROUP BY FLOOR(dr.race_year / 10) * 10, dd.full_name
HAVING COUNT(CASE WHEN fr.is_winner THEN 1 END) >= 5
ORDER BY decada DESC, victorias DESC;
```

**En PowerBI**:

- **Tabla**: Todas las columnas
- **Gráfico de barras apiladas**:
  - Eje X: `decada`
  - Eje Y: `victorias`
  - Leyenda: `piloto`

---

### Visualización 8.3: Mapa de Circuitos con Victorias

**Tipo**: Mapa

**Query SQL**:

```sql
SELECT
    dc.circuit_id,
    dc.circuit_name as circuito,
    dc.location as ciudad,
    dc.country as pais,
    dc.continent as continente,
    dc.latitude as latitud,
    dc.longitude as longitud,
    dc.altitude as altitud,
    COUNT(DISTINCT dr.race_id) as total_carreras,
    COUNT(CASE WHEN fr.is_winner = TRUE THEN 1 END) as total_victorias
FROM dim_circuit dc
LEFT JOIN dim_race dr ON dc.circuit_id = dr.circuit_id
LEFT JOIN fact_results fr ON dr.sk_race = fr.sk_race
WHERE dc.latitude IS NOT NULL
  AND dc.longitude IS NOT NULL
GROUP BY dc.circuit_id, dc.circuit_name, dc.location, dc.country,
         dc.continent, dc.latitude, dc.longitude, dc.altitude;
```

**En PowerBI**:

- **Visual: Mapa**
  - Latitud: `latitud`
  - Longitud: `longitud`
  - Leyenda: `continente`
  - Tamaño: `total_victorias`
  - Tooltip: `circuito`, `pais`, `total_carreras`, `altitud`

---

## 📋 RESUMEN DE PÁGINAS

1. **Página 1: Análisis de Pilotos** - 4 visualizaciones
2. **Página 2: Campeonatos y Resultados** - 3 visualizaciones
3. **Página 3: Estrategias de Pit Stops** - 2 visualizaciones
4. **Página 4: Análisis Predictivo de Circuitos** - 2 visualizaciones
5. **Página 5: Rendimiento en Carreras** - 3 visualizaciones
6. **Página 6: Análisis de Nacionalidades** - 2 visualizaciones
7. **Página 7: Factores Ambientales** - 2 visualizaciones
8. **Página 8: Análisis Adicionales** - 3 visualizaciones

**Total: 21 visualizaciones organizadas en 8 páginas temáticas**

---

## 🔧 CONFIGURACIÓN INICIAL EN POWERBI

1. **Conectar a PostgreSQL**:

   - Obtener datos → PostgreSQL
   - Servidor: localhost:5434
   - Base de datos: dw
   - Usuario: admin / Contraseña: admin

2. **Importar Queries**:

   - Para cada visualización, usar "Consulta SQL" en lugar de importar tablas
   - Copiar y pegar la query correspondiente

3. **Crear Páginas**:

   - Crear 8 páginas nuevas en PowerBI
   - Nombrarlas según las temáticas

4. **Filtros Globales** (Opcional):
   - Crear filtros de año en cada página para análisis temporal
   - Usar segmentaciones de datos para interactividad
