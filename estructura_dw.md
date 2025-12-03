# Estructura del Data Warehouse - Fórmula 1

![Diagrama del Data Warehouse](diagrama_dw.png)

## Modelo de Datos

El Data Warehouse sigue un modelo **estrella** (star schema), donde las tablas de hecho están en el centro y las dimensiones se conectan mediante claves foráneas.

## Dimensiones

Las dimensiones son tablas que contienen información descriptiva y de contexto para analizar los eventos.

### `dim_driver` - Pilotos

Información de los pilotos de Fórmula 1.

- `sk_driver`: Clave primaria (surrogate key)
- `driver_id`: ID del piloto
- `driver_ref`: Referencia del piloto
- `driver_number`: Número del piloto
- `driver_code`: Código del piloto
- `forename`: Nombre
- `surname`: Apellido
- `full_name`: Nombre completo
- `date_of_birth`: Fecha de nacimiento
- `nationality`: Nacionalidad
- `url`: URL de referencia

### `dim_constructor` - Constructores

Información de los equipos (escuderías).

- `sk_constructor`: Clave primaria (surrogate key)
- `constructor_id`: ID del constructor
- `constructor_ref`: Referencia del constructor
- `constructor_name`: Nombre del constructor
- `nationality`: Nacionalidad
- `url`: URL de referencia

### `dim_circuit` - Circuitos

Datos de los circuitos donde se corren las carreras.

- `sk_circuit`: Clave primaria (surrogate key)
- `circuit_id`: ID del circuito
- `circuit_ref`: Referencia del circuito
- `circuit_name`: Nombre del circuito
- `location`: Ubicación
- `country`: País
- `continent`: Continente
- `latitude`: Latitud
- `longitude`: Longitud
- `altitude`: Altitud
- `url`: URL de referencia

### `dim_race` - Carreras

Detalles de cada carrera.

- `sk_race`: Clave primaria (surrogate key)
- `race_id`: ID de la carrera
- `race_year`: Año de la carrera
- `race_round`: Ronda de la temporada
- `race_name`: Nombre de la carrera
- `race_date`: Fecha de la carrera
- `race_time`: Hora de la carrera
- `circuit_id`: ID del circuito (FK a dim_circuit)
- `circuit_name`: Nombre del circuito
- `circuit_country`: País del circuito
- `url`: URL de referencia

### `dim_status` - Estados

Estados de resultados de carreras.

- `sk_status`: Clave primaria (surrogate key)
- `status_id`: ID del estado
- `status_description`: Descripción del estado
- `is_finished`: Indica si terminó la carrera
- `is_classified`: Indica si fue clasificado

### `dim_date` - Fechas

Dimensión temporal con información desglosada de fechas.

- `sk_date`: Clave primaria (surrogate key)
- `full_date`: Fecha completa
- `year`: Año
- `month`: Mes
- `month_name`: Nombre del mes
- `day`: Día
- `day_of_week`: Día de la semana (0-6)
- `day_name`: Nombre del día
- `quarter`: Trimestre
- `week_of_year`: Semana del año
- `is_weekend`: Indica si es fin de semana

### `dim_season` - Temporadas

Información de las temporadas (años) de Fórmula 1.

- `sk_season`: Clave primaria (surrogate key)
- `year`: Año de la temporada
- `url`: URL de referencia

## Tablas de Hecho

Las tablas de hecho contienen los eventos y medidas numéricas que se analizan. Cada tabla se conecta a las dimensiones mediante claves foráneas (`sk_*`).

### `fact_results` - Resultados de Carreras

Resultado de un piloto en una carrera específica.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_constructor` → `dim_constructor`
- `sk_status` → `dim_status`
- `sk_date` → `dim_date`

**Medidas principales:**

- `grid_position`: Posición de salida
- `final_position`: Posición final
- `points`: Puntos obtenidos
- `laps_completed`: Vueltas completadas
- `race_time`: Tiempo de carrera
- `fastest_lap`: Vuelta más rápida
- `is_winner`: Indica si ganó
- `is_podium`: Indica si llegó al podio
- `is_points_finish`: Indica si obtuvo puntos
- `positions_gained`: Posiciones ganadas

### `fact_pit_stops` - Paradas en Boxes

Registro de cada parada en boxes.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_date` → `dim_date`

**Medidas principales:**

- `stop_number`: Número de parada
- `lap`: Vuelta en que ocurrió
- `pit_time`: Hora de la parada
- `duration_seconds`: Duración en segundos
- `duration_milliseconds`: Duración en milisegundos

### `fact_lap_times` - Tiempos por Vuelta

Tiempos de cada vuelta de cada piloto en cada carrera.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_date` → `dim_date`

**Medidas principales:**

- `lap_number`: Número de vuelta
- `position`: Posición en esa vuelta
- `lap_time`: Tiempo de vuelta
- `lap_time_milliseconds`: Tiempo en milisegundos
- `total_laps_in_race`: Total de vueltas en la carrera
- `lap_tercile`: Tercio de la carrera (1, 2, 3)
- `is_fastest_lap`: Indica si fue la vuelta más rápida

### `fact_qualifying` - Resultados de Clasificación

Resultados de las sesiones de clasificación.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_constructor` → `dim_constructor`
- `sk_date` → `dim_date`

**Medidas principales:**

- `qualifying_position`: Posición en clasificación
- `q1_time`: Tiempo en Q1
- `q2_time`: Tiempo en Q2
- `q3_time`: Tiempo en Q3
- `is_pole_position`: Indica si obtuvo la pole position
- `is_front_row`: Indica si salió en primera fila
- `is_top_ten`: Indica si quedó en top 10

### `fact_driver_standings` - Clasificación de Pilotos

Puntos y posición en el campeonato de pilotos después de cada carrera.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_date` → `dim_date`

**Medidas principales:**

- `points`: Puntos totales
- `position`: Posición en el campeonato
- `position_text`: Posición como texto
- `wins`: Número de victorias
- `is_leader`: Indica si es líder
- `is_champion`: Indica si es campeón

### `fact_constructor_standings` - Clasificación de Constructores

Puntos y posición en el campeonato de constructores después de cada carrera.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_constructor` → `dim_constructor`
- `sk_date` → `dim_date`

**Medidas principales:**

- `points`: Puntos totales
- `position`: Posición en el campeonato
- `position_text`: Posición como texto
- `wins`: Número de victorias
- `is_leader`: Indica si es líder
- `is_champion`: Indica si es campeón

### `fact_constructor_results` - Resultados de Constructores por Carrera

Resultados agregados de cada constructor en cada carrera.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_constructor` → `dim_constructor`
- `sk_date` → `dim_date`

**Medidas principales:**

- `points`: Puntos obtenidos
- `status`: Estado del resultado

### `fact_sprint_results` - Resultados de Sprints

Resultados de las carreras sprint.

**Claves foráneas:**

- `sk_race` → `dim_race`
- `sk_driver` → `dim_driver`
- `sk_constructor` → `dim_constructor`
- `sk_status` → `dim_status`
- `sk_date` → `dim_date`

**Medidas principales:**

- `grid_position`: Posición de salida
- `final_position`: Posición final
- `points`: Puntos obtenidos
- `laps_completed`: Vueltas completadas
- `race_time`: Tiempo de carrera
- `fastest_lap`: Vuelta más rápida
- `is_winner`: Indica si ganó
- `is_podium`: Indica si llegó al podio

## Relaciones entre Tablas

El modelo sigue un esquema estrella donde:

- Las tablas de hecho (`fact_*`) están en el centro
- Las dimensiones (`dim_*`) se conectan mediante claves foráneas `sk_*`
- Cada `sk_*` en una tabla de hecho apunta a la clave primaria correspondiente en la dimensión

**Ejemplo de relación:**

```
fact_results
    ├── sk_race → dim_race
    ├── sk_driver → dim_driver
    ├── sk_constructor → dim_constructor
    ├── sk_status → dim_status
    └── sk_date → dim_date

dim_race
    └── circuit_id → dim_circuit
```

## Índices

El esquema incluye índices en las columnas más consultadas para optimizar el rendimiento de las consultas:

- Índices en claves foráneas (`sk_race`, `sk_driver`, `sk_constructor`, etc.)
- Índices en campos de filtrado común (`race_year`, `is_winner`, `is_champion`, etc.)
- Índices en dimensiones para búsquedas rápidas (`country`, `nationality`, etc.)
