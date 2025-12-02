DROP TABLE IF EXISTS public.stg_circuits CASCADE;
CREATE TABLE public.stg_circuits (
    circuitId TEXT,
    circuitRef TEXT,
    name TEXT,
    location TEXT,
    country TEXT,
    lat TEXT,
    lng TEXT,
    alt TEXT,
    url TEXT
);

DROP TABLE IF EXISTS public.stg_constructor_results CASCADE;
CREATE TABLE public.stg_constructor_results (
    constructorResultsId TEXT,
    raceId TEXT,
    constructorId TEXT,
    points TEXT,
    status TEXT
);

DROP TABLE IF EXISTS public.stg_constructor_standings CASCADE;
CREATE TABLE public.stg_constructor_standings (
    constructorStandingsId TEXT,
    raceId TEXT,
    constructorId TEXT,
    points TEXT,
    position TEXT,
    positionText TEXT,
    wins TEXT
);

DROP TABLE IF EXISTS public.stg_constructors CASCADE;
CREATE TABLE public.stg_constructors (
    constructorId TEXT,
    constructorRef TEXT,
    name TEXT,
    nationality TEXT,
    url TEXT
);

DROP TABLE IF EXISTS public.stg_driver_standings CASCADE;
CREATE TABLE public.stg_driver_standings (
    driverStandingsId TEXT,
    raceId TEXT,
    driverId TEXT,
    points TEXT,
    position TEXT,
    positionText TEXT,
    wins TEXT
);

DROP TABLE IF EXISTS public.stg_drivers CASCADE;
CREATE TABLE public.stg_drivers (
    driverId TEXT,
    driverRef TEXT,
    number TEXT,
    code TEXT,
    forename TEXT,
    surname TEXT,
    dob TEXT,
    nationality TEXT,
    url TEXT
);

DROP TABLE IF EXISTS public.stg_lap_times CASCADE;
CREATE TABLE public.stg_lap_times (
    raceId TEXT,
    driverId TEXT,
    lap TEXT,
    position TEXT,
    time TEXT,
    milliseconds TEXT
);

DROP TABLE IF EXISTS public.stg_pit_stops CASCADE;
CREATE TABLE public.stg_pit_stops (
    raceId TEXT,
    driverId TEXT,
    stop TEXT,
    lap TEXT,
    time TEXT,
    duration TEXT,
    milliseconds TEXT
);

DROP TABLE IF EXISTS public.stg_qualifying CASCADE;
CREATE TABLE public.stg_qualifying (
    qualifyId TEXT,
    raceId TEXT,
    driverId TEXT,
    constructorId TEXT,
    number TEXT,
    position TEXT,
    q1 TEXT,
    q2 TEXT,
    q3 TEXT
);

DROP TABLE IF EXISTS public.stg_races CASCADE;
CREATE TABLE public.stg_races (
    raceId TEXT,
    year TEXT,
    round TEXT,
    circuitId TEXT,
    name TEXT,
    date TEXT,
    time TEXT,
    url TEXT,
    fp1_date TEXT,
    fp1_time TEXT,
    fp2_date TEXT,
    fp2_time TEXT,
    fp3_date TEXT,
    fp3_time TEXT,
    quali_date TEXT,
    quali_time TEXT,
    sprint_date TEXT,
    sprint_time TEXT
);

DROP TABLE IF EXISTS public.stg_results CASCADE;
CREATE TABLE public.stg_results (
    resultId TEXT,
    raceId TEXT,
    driverId TEXT,
    constructorId TEXT,
    number TEXT,
    grid TEXT,
    position TEXT,
    positionText TEXT,
    positionOrder TEXT,
    points TEXT,
    laps TEXT,
    time TEXT,
    milliseconds TEXT,
    fastestLap TEXT,
    rank TEXT,
    fastestLapTime TEXT,
    fastestLapSpeed TEXT,
    statusId TEXT
);

DROP TABLE IF EXISTS public.stg_seasons CASCADE;
CREATE TABLE public.stg_seasons (
    year TEXT,
    url TEXT
);

DROP TABLE IF EXISTS public.stg_sprint_results CASCADE;
CREATE TABLE public.stg_sprint_results (
    resultId TEXT,
    raceId TEXT,
    driverId TEXT,
    constructorId TEXT,
    number TEXT,
    grid TEXT,
    position TEXT,
    positionText TEXT,
    positionOrder TEXT,
    points TEXT,
    laps TEXT,
    time TEXT,
    milliseconds TEXT,
    fastestLap TEXT,
    fastestLapTime TEXT,
    statusId TEXT
);

DROP TABLE IF EXISTS public.stg_status CASCADE;
CREATE TABLE public.stg_status (
    statusId TEXT,
    status TEXT
);
