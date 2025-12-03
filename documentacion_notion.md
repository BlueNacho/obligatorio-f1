# Documentación Data Warehouse - Fórmula 1

---

## 📊 Estructura del Data Warehouse

### Dimensiones (Tablas de Referencia)

Las **dimensiones** son tablas que contienen información descriptiva y de contexto. Son como las "categorías" o "atributos" que nos ayudan a entender y filtrar los datos.

#### `dim_driver` - Información de Pilotos

Contiene datos de los pilotos: nombre completo, nacionalidad, fecha de nacimiento, número de piloto, etc.

#### `dim_constructor` - Información de Constructores

Almacena datos de los equipos (escuderías): nombre del constructor, nacionalidad, etc.

#### `dim_circuit` - Información de Circuitos

Datos de los circuitos donde se corren las carreras: nombre, ubicación, país, continente, coordenadas geográficas (latitud, longitud), altitud, etc.

#### `dim_race` - Información de Carreras

Detalles de cada carrera: año, ronda, nombre de la carrera, fecha, circuito asociado, etc.

#### `dim_status` - Estados de Resultados

Describe el estado final de un resultado: si terminó la carrera, si fue clasificado, etc.

#### `dim_date` - Dimensión Temporal

Tabla de fechas con información desglosada: año, mes, día, trimestre, día de la semana, etc. Facilita análisis temporales.

#### `dim_season` - Temporadas

Información de las temporadas (años) de Fórmula 1.

---

### Tablas de Hecho (Eventos y Medidas)

Las **tablas de hecho** contienen los eventos y medidas numéricas que queremos analizar. Son el "corazón" del data warehouse porque almacenan lo que realmente pasó.

#### `fact_results` - Resultados de Carreras

Cada fila representa el resultado de un piloto en una carrera específica. Contiene: posición de salida, posición final, puntos obtenidos, vueltas completadas, si ganó, si llegó al podio, tiempo de vuelta rápida, etc.

#### `fact_pit_stops` - Paradas en Boxes

Registra cada parada en boxes: número de parada, vuelta en que ocurrió, duración en segundos, etc.

#### `fact_lap_times` - Tiempos por Vuelta

Almacena los tiempos de cada vuelta de cada piloto en cada carrera, incluyendo si fue la vuelta más rápida y en qué tercio de la carrera ocurrió.

#### `fact_qualifying` - Resultados de Clasificación

Resultados de las sesiones de clasificación: posición, tiempos de Q1, Q2, Q3, si obtuvo la pole position, etc.

#### `fact_driver_standings` - Clasificación de Pilotos

Puntos y posición en el campeonato de pilotos después de cada carrera. Permite ver la evolución del campeonato.

#### `fact_constructor_standings` - Clasificación de Constructores

Similar a `fact_driver_standings` pero para equipos. Puntos y posición en el campeonato de constructores.

#### `fact_constructor_results` - Resultados de Constructores por Carrera

Resultados agregados de cada constructor en cada carrera.

#### `fact_sprint_results` - Resultados de Sprints

Resultados de las carreras sprint (formato introducido recientemente en F1).

---

### 🔗 Cómo se Relacionan las Tablas

El modelo sigue un esquema **estrella** (star schema):

- **Centro**: Las tablas de hecho (`fact_*`) están en el centro
- **Ramas**: Las dimensiones (`dim_*`) se conectan al centro mediante claves foráneas

**Ejemplo de relación:**

```text
fact_results (tabla de hecho)
    ↓ se conecta con ↓
dim_driver (dimensión) → mediante sk_driver
dim_race (dimensión) → mediante sk_race
dim_constructor (dimensión) → mediante sk_constructor
dim_status (dimensión) → mediante sk_status
```

**Cómo funciona:**

- Cada tabla de hecho tiene columnas que empiezan con `sk_` (surrogate key)
- Estas columnas `sk_*` son claves foráneas que apuntan a las claves primarias de las dimensiones
- Por ejemplo: `fact_results.sk_driver` → `dim_driver.sk_driver`
- Esto permite unir (JOIN) las tablas para obtener información completa

**Ventajas:**

- Consultas más rápidas
- Fácil de entender y usar
- Permite analizar eventos (hechos) desde múltiples perspectivas (dimensiones)

---

## 📈 Explicación de Visualizaciones

### 📄 PÁGINA 1: ANÁLISIS DE PILOTOS

#### Visualización 1.1: Top 20 Pilotos con Más Carreras

Muestra los 20 pilotos que han participado en más carreras a lo largo de su carrera, incluyendo información sobre sus victorias y puntos totales. Útil para identificar a los pilotos más experimentados y exitosos históricamente.

#### Visualización 1.2: Pilotos con Más Carreras Ganadas (Filtrable por Período)

Presenta cuántas carreras ganó cada piloto por año, permitiendo filtrar por período temporal. Ayuda a identificar patrones de dominación de pilotos en diferentes épocas.

#### Visualización 1.3: Pilotos con Más Paradas en Boxes

Analiza qué pilotos han realizado más paradas en boxes y sus tiempos promedio. Útil para entender estrategias de pit stops y rendimiento en boxes.

#### Visualización 1.4: Comparación Paradas vs Carreras Ganadas

Gráfico de dispersión que relaciona el número de paradas en boxes con las victorias de cada piloto. Permite identificar si existe correlación entre estrategias de pit stops y éxito en carreras.

---

### 📄 PÁGINA 2: CAMPEONATOS Y RESULTADOS

#### Visualización 2.1: Resultados Finales de Campeonatos - Pilotos

Muestra los campeones, subcampeones y terceros lugares de cada temporada, con sus puntos totales y victorias. Permite ver la evolución histórica de los campeonatos y quiénes han sido los más exitosos.

#### Visualización 2.2: Resultados de Constructores

Compara el rendimiento de todos los constructores (equipos) en términos de victorias, podios, puntos totales y puntos por carrera. Identifica los equipos más exitosos de la historia.

#### Visualización 2.3: Campeones de Constructores por Año

Lista los campeones del mundial de constructores año por año, mostrando puntos y victorias. Complementa el análisis de campeonatos desde la perspectiva de equipos.

---

### 📄 PÁGINA 3: ESTRATEGIAS DE PIT STOPS

#### Visualización 3.1: Mejor Estrategia de Parada por Circuito

Analiza qué estrategia de pit stops (número de paradas) ha sido más exitosa en cada circuito, basándose en los ganadores. Ayuda a identificar patrones estratégicos específicos por circuito.

#### Visualización 3.2: Análisis de Paradas por Circuito (Todos los Resultados)

Proporciona estadísticas generales de paradas en boxes por circuito, incluyendo promedio de paradas y duración promedio. Ofrece una visión completa de las estrategias utilizadas en cada pista.

---

### 📄 PÁGINA 4: ANÁLISIS PREDICTIVO DE CIRCUITOS

#### Visualización 4.1: Pilotos que Ganaron en Circuitos Específicos y Ganaron Campeonato

Identifica qué pilotos ganaron en circuitos específicos y luego se convirtieron en campeones del mundo. Permite analizar si hay circuitos "predictivos" del éxito futuro.

#### Visualización 4.2: Análisis Complejo - Múltiples Circuitos

Muestra qué pilotos han ganado en múltiples circuitos diferentes (5 o más) y si son campeones del mundo. Ayuda a identificar pilotos versátiles que dominan en diferentes tipos de pistas.

#### Visualización 4.3: Circuitos Más Ganados por Campeones del Mundo

Identifica qué circuitos han sido ganados más veces por pilotos que luego se convirtieron en campeones del mundo. Útil para entender qué circuitos son "indicadores" de talento de clase mundial.

---

### 📄 PÁGINA 5: RENDIMIENTO EN CARRERAS

#### Visualización 5.1: Pilotos con Mejor Tiempo vs Resultado Final

Analiza qué porcentaje de veces el piloto con la vuelta rápida ganó la carrera, llegó al podio o quedó fuera. Muestra la relación entre velocidad pura y resultado final.

#### Visualización 5.2: Récords de Vuelta por Tercio de Carrera

Distribuye las vueltas rápidas según en qué tercio de la carrera ocurrieron (inicio, medio, final). Ayuda a entender cuándo los pilotos suelen hacer sus mejores tiempos.

#### Visualización 5.3: Pilotos que Remontaron al Podio

Identifica pilotos que lograron llegar al podio partiendo desde posiciones bajas (más allá de la 3ra posición). Muestra capacidad de remontada y estrategia durante la carrera.

---

### 📄 PÁGINA 6: ANÁLISIS DE NACIONALIDADES

#### Visualización 6.1: Nacionalidad de Pilotos Más Exitosos (Histórico)

Compara el rendimiento de pilotos agrupados por nacionalidad, mostrando victorias, podios y puntos promedio por piloto. Identifica qué países han producido los pilotos más exitosos históricamente.

#### Visualización 6.2: Rendimiento por Nacionalidad (Últimos 10 Años)

Análisis similar al anterior pero enfocado en los últimos 10 años. Permite ver tendencias recientes y qué nacionalidades están dominando actualmente.

---

### 📄 PÁGINA 7: FACTORES AMBIENTALES

#### Visualización 7.1: Impacto de la Altitud en el Rendimiento

Categoriza circuitos por altitud y analiza cómo afecta a métricas como abandonos, duración de pit stops y posición de salida de ganadores. Explora si la altitud influye en el rendimiento.

#### Visualización 7.2: Circuitos por Altitud con Métricas

Tabla detallada de cada circuito mostrando su altitud y métricas asociadas (carreras, vueltas promedio, retiros, pit stops). Permite análisis específico por circuito considerando factores ambientales.

---

### 📄 PÁGINA 8: ANÁLISIS ADICIONALES

#### Visualización 8.1: Evolución Histórica de la Fórmula 1

Muestra la evolución de la F1 a lo largo del tiempo: número de carreras, pilotos, constructores y puntos totales por temporada. Proporciona una visión macro de cómo ha crecido y cambiado el deporte.

#### Visualización 8.2: Dominio por Década

Agrupa el rendimiento de los pilotos por décadas (1950s, 1960s, etc.), mostrando victorias, podios y puntos totales de cada piloto en cada década. Permite identificar qué pilotos dominaron cada época y cómo ha evolucionado el dominio a lo largo de las décadas.

#### Visualización 8.3: Mapa de Circuitos con Victorias

Visualización geográfica de todos los circuitos en un mapa, mostrando ubicación, continente y número total de victorias. Permite análisis geográfico y visualización espacial de la distribución de carreras y éxito.
