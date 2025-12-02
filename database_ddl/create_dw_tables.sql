-- =====================================================
-- DATA WAREHOUSE - FORMULA 1
-- Modelo Estrella
-- =====================================================

-- =====================================================
-- DIMENSIONES
-- =====================================================

DROP TABLE IF EXISTS public.dim_driver CASCADE;
CREATE TABLE public.dim_driver (
    sk_driver SERIAL PRIMARY KEY,
    driver_id INTEGER NOT NULL,
    driver_ref VARCHAR(100),
    driver_number VARCHAR(10),
    driver_code VARCHAR(10),
    forename VARCHAR(100),
    surname VARCHAR(100),
    full_name VARCHAR(200),
    date_of_birth DATE,
    nationality VARCHAR(100),
    url TEXT,
    UNIQUE(driver_id)
);

DROP TABLE IF EXISTS public.dim_constructor CASCADE;
CREATE TABLE public.dim_constructor (
    sk_constructor SERIAL PRIMARY KEY,
    constructor_id INTEGER NOT NULL,
    constructor_ref VARCHAR(100),
    constructor_name VARCHAR(255),
    nationality VARCHAR(100),
    url TEXT,
    UNIQUE(constructor_id)
);

DROP TABLE IF EXISTS public.dim_circuit CASCADE;
CREATE TABLE public.dim_circuit (
    sk_circuit SERIAL PRIMARY KEY,
    circuit_id INTEGER NOT NULL,
    circuit_ref VARCHAR(100),
    circuit_name VARCHAR(255),
    location VARCHAR(100),
    country VARCHAR(100),
    continent VARCHAR(50),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    altitude INTEGER,
    url TEXT,
    UNIQUE(circuit_id)
);

DROP TABLE IF EXISTS public.dim_race CASCADE;
CREATE TABLE public.dim_race (
    sk_race SERIAL PRIMARY KEY,
    race_id INTEGER NOT NULL,
    race_year INTEGER,
    race_round INTEGER,
    race_name VARCHAR(255),
    race_date DATE,
    race_time TIME,
    circuit_id INTEGER,
    circuit_name VARCHAR(255),
    circuit_country VARCHAR(100),
    url TEXT,
    UNIQUE(race_id)
);

DROP TABLE IF EXISTS public.dim_status CASCADE;
CREATE TABLE public.dim_status (
    sk_status SERIAL PRIMARY KEY,
    status_id INTEGER NOT NULL,
    status_description VARCHAR(255),
    is_finished BOOLEAN,
    is_classified BOOLEAN,
    UNIQUE(status_id)
);

DROP TABLE IF EXISTS public.dim_date CASCADE;
CREATE TABLE public.dim_date (
    sk_date SERIAL PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    day INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    quarter INTEGER,
    week_of_year INTEGER,
    is_weekend BOOLEAN,
    UNIQUE(full_date)
);

DROP TABLE IF EXISTS public.dim_season CASCADE;
CREATE TABLE public.dim_season (
    sk_season SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    url TEXT,
    UNIQUE(year)
);

-- =====================================================
-- FACT TABLES
-- =====================================================

DROP TABLE IF EXISTS public.fact_results CASCADE;
CREATE TABLE public.fact_results (
    sk_result SERIAL PRIMARY KEY,
    result_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_constructor INTEGER REFERENCES public.dim_constructor(sk_constructor),
    sk_status INTEGER REFERENCES public.dim_status(sk_status),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    grid_position INTEGER,
    final_position INTEGER,
    position_text VARCHAR(10),
    position_order INTEGER,
    points DECIMAL(10, 2),
    laps_completed INTEGER,
    race_time VARCHAR(50),
    race_time_milliseconds BIGINT,
    fastest_lap INTEGER,
    fastest_lap_rank INTEGER,
    fastest_lap_time VARCHAR(20),
    fastest_lap_speed DECIMAL(10, 3),
    
    is_winner BOOLEAN,
    is_podium BOOLEAN,
    is_points_finish BOOLEAN,
    positions_gained INTEGER,
    
    race_year INTEGER,
    circuit_id INTEGER,
    driver_id INTEGER,
    constructor_id INTEGER
);

DROP TABLE IF EXISTS public.fact_pit_stops CASCADE;
CREATE TABLE public.fact_pit_stops (
    sk_pit_stop SERIAL PRIMARY KEY,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    stop_number INTEGER,
    lap INTEGER,
    pit_time TIME,
    duration_seconds DECIMAL(10, 3),
    duration_milliseconds INTEGER,
    
    race_year INTEGER,
    circuit_id INTEGER,
    driver_id INTEGER
);

DROP TABLE IF EXISTS public.fact_lap_times CASCADE;
CREATE TABLE public.fact_lap_times (
    sk_lap_time SERIAL PRIMARY KEY,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    lap_number INTEGER,
    position INTEGER,
    lap_time VARCHAR(20),
    lap_time_milliseconds INTEGER,
    
    total_laps_in_race INTEGER,
    lap_tercile INTEGER,
    is_fastest_lap BOOLEAN,
    
    race_year INTEGER,
    circuit_id INTEGER,
    driver_id INTEGER
);

DROP TABLE IF EXISTS public.fact_qualifying CASCADE;
CREATE TABLE public.fact_qualifying (
    sk_qualifying SERIAL PRIMARY KEY,
    qualify_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_constructor INTEGER REFERENCES public.dim_constructor(sk_constructor),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    driver_number INTEGER,
    qualifying_position INTEGER,
    q1_time VARCHAR(20),
    q2_time VARCHAR(20),
    q3_time VARCHAR(20),
    
    is_pole_position BOOLEAN,
    is_front_row BOOLEAN,
    is_top_ten BOOLEAN,
    
    race_year INTEGER,
    circuit_id INTEGER,
    driver_id INTEGER,
    constructor_id INTEGER
);

DROP TABLE IF EXISTS public.fact_driver_standings CASCADE;
CREATE TABLE public.fact_driver_standings (
    sk_driver_standing SERIAL PRIMARY KEY,
    driver_standing_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    points DECIMAL(10, 2),
    position INTEGER,
    position_text VARCHAR(10),
    wins INTEGER,
    
    is_leader BOOLEAN,
    is_champion BOOLEAN,
    
    race_year INTEGER,
    race_round INTEGER,
    driver_id INTEGER
);

DROP TABLE IF EXISTS public.fact_constructor_standings CASCADE;
CREATE TABLE public.fact_constructor_standings (
    sk_constructor_standing SERIAL PRIMARY KEY,
    constructor_standing_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_constructor INTEGER REFERENCES public.dim_constructor(sk_constructor),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    points DECIMAL(10, 2),
    position INTEGER,
    position_text VARCHAR(10),
    wins INTEGER,
    
    is_leader BOOLEAN,
    is_champion BOOLEAN,
    
    race_year INTEGER,
    race_round INTEGER,
    constructor_id INTEGER
);

DROP TABLE IF EXISTS public.fact_constructor_results CASCADE;
CREATE TABLE public.fact_constructor_results (
    sk_constructor_result SERIAL PRIMARY KEY,
    constructor_result_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_constructor INTEGER REFERENCES public.dim_constructor(sk_constructor),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    points DECIMAL(10, 2),
    status VARCHAR(50),
    
    race_year INTEGER,
    constructor_id INTEGER
);

DROP TABLE IF EXISTS public.fact_sprint_results CASCADE;
CREATE TABLE public.fact_sprint_results (
    sk_sprint_result SERIAL PRIMARY KEY,
    result_id INTEGER,
    
    sk_race INTEGER REFERENCES public.dim_race(sk_race),
    sk_driver INTEGER REFERENCES public.dim_driver(sk_driver),
    sk_constructor INTEGER REFERENCES public.dim_constructor(sk_constructor),
    sk_status INTEGER REFERENCES public.dim_status(sk_status),
    sk_date INTEGER REFERENCES public.dim_date(sk_date),
    
    grid_position INTEGER,
    final_position INTEGER,
    position_text VARCHAR(10),
    position_order INTEGER,
    points INTEGER,
    laps_completed INTEGER,
    race_time VARCHAR(50),
    race_time_milliseconds BIGINT,
    fastest_lap INTEGER,
    fastest_lap_time VARCHAR(20),
    
    is_winner BOOLEAN,
    is_podium BOOLEAN,
    
    race_year INTEGER,
    driver_id INTEGER,
    constructor_id INTEGER
);

-- =====================================================
-- INDICES para mejorar performance de queries
-- =====================================================

CREATE INDEX idx_fact_results_race ON public.fact_results(sk_race);
CREATE INDEX idx_fact_results_driver ON public.fact_results(sk_driver);
CREATE INDEX idx_fact_results_constructor ON public.fact_results(sk_constructor);
CREATE INDEX idx_fact_results_year ON public.fact_results(race_year);
CREATE INDEX idx_fact_results_winner ON public.fact_results(is_winner);

CREATE INDEX idx_fact_pit_stops_race ON public.fact_pit_stops(sk_race);
CREATE INDEX idx_fact_pit_stops_driver ON public.fact_pit_stops(sk_driver);
CREATE INDEX idx_fact_pit_stops_year ON public.fact_pit_stops(race_year);

CREATE INDEX idx_fact_lap_times_race ON public.fact_lap_times(sk_race);
CREATE INDEX idx_fact_lap_times_driver ON public.fact_lap_times(sk_driver);
CREATE INDEX idx_fact_lap_times_tercile ON public.fact_lap_times(lap_tercile);

CREATE INDEX idx_fact_qualifying_race ON public.fact_qualifying(sk_race);
CREATE INDEX idx_fact_qualifying_driver ON public.fact_qualifying(sk_driver);

CREATE INDEX idx_fact_driver_standings_race ON public.fact_driver_standings(sk_race);
CREATE INDEX idx_fact_driver_standings_driver ON public.fact_driver_standings(sk_driver);
CREATE INDEX idx_fact_driver_standings_champion ON public.fact_driver_standings(is_champion);

CREATE INDEX idx_fact_constructor_standings_race ON public.fact_constructor_standings(sk_race);
CREATE INDEX idx_fact_constructor_standings_constructor ON public.fact_constructor_standings(sk_constructor);

CREATE INDEX idx_dim_circuit_country ON public.dim_circuit(country);
CREATE INDEX idx_dim_circuit_continent ON public.dim_circuit(continent);
CREATE INDEX idx_dim_driver_nationality ON public.dim_driver(nationality);
CREATE INDEX idx_dim_race_year ON public.dim_race(race_year);

INSERT INTO public.dim_date (full_date, year, month, month_name, day, day_of_week, day_name, quarter, week_of_year, is_weekend)
SELECT 
    d::date as full_date,
    EXTRACT(YEAR FROM d)::integer as year,
    EXTRACT(MONTH FROM d)::integer as month,
    TO_CHAR(d, 'Month') as month_name,
    EXTRACT(DAY FROM d)::integer as day,
    EXTRACT(DOW FROM d)::integer as day_of_week,
    TO_CHAR(d, 'Day') as day_name,
    EXTRACT(QUARTER FROM d)::integer as quarter,
    EXTRACT(WEEK FROM d)::integer as week_of_year,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN true ELSE false END as is_weekend
FROM generate_series('1950-01-01'::date, '2030-12-31'::date, '1 day'::interval) d
ON CONFLICT (full_date) DO NOTHING;

