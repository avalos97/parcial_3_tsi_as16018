-- =============================================
-- Create Schema for Data Warehouse
-- =============================================

-- Drop existing schema if needed
DROP SCHEMA IF EXISTS FlightDW;
GO

-- Create Schema for the Data Warehouse
CREATE SCHEMA FlightDW;
GO

-- =============================================
-- Create Dimension Tables
-- =============================================

-- Airline Dimension
CREATE TABLE FlightDW.AirlineDim (
    AirlineKey INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate Key
    AirlineCode VARCHAR(10) NOT NULL,          -- Airline Code (e.g., "02Q")
    AirlineDescription NVARCHAR(255) NOT NULL   -- Airline Name (e.g., "Titan Airways")
);

-- Date Dimension
CREATE TABLE FlightDW.DateDim (
    DateKey INT IDENTITY(1,1) PRIMARY KEY,      -- Surrogate Key
    Date DATE NOT NULL,                         -- Actual Date (e.g., '2018-01-23')
    Year INT NOT NULL,                          -- Year (e.g., 2018)
    Quarter INT NOT NULL,                       -- Quarter (1, 2, 3, 4)
    Month INT NOT NULL,                         -- Month (1-12)
    DayOfMonth INT NOT NULL,                    -- Day of the month (1-31)
    DayOfWeek INT NOT NULL                      -- Day of the week (1 = Monday, 7 = Sunday)
);

-- Airport Dimension
CREATE TABLE FlightDW.AirportDim (
    AirportKey INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate Key
    AirportID INT NOT NULL,                     -- Unique Airport ID
    AirportName NVARCHAR(255) NOT NULL,         -- Airport Name (e.g., Albany, GA)
    City NVARCHAR(255) NOT NULL,                -- City (e.g., Albany)
    State NVARCHAR(255) NOT NULL,               -- State (e.g., Georgia)
    StateFIPS NVARCHAR(10) NOT NULL,            -- State FIPS Code (e.g., 13)
    WAC INT NOT NULL                            -- World Area Code (e.g., 34)
);

-- Flight Dimension (for Flight/Tail Number)
CREATE TABLE FlightDW.FlightDim (
    FlightKey INT IDENTITY(1,1) PRIMARY KEY,    -- Surrogate Key
    FlightNumber NVARCHAR(20) NOT NULL,         -- Flight Number
    TailNumber NVARCHAR(20)                     -- Tail Number (aircraft identifier)
);

-- Cause Dimension (Optional, for reasons like weather, mechanical issues)
CREATE TABLE FlightDW.CauseDim (
    CauseKey INT IDENTITY(1,1) PRIMARY KEY,     -- Surrogate Key
    CauseDescription NVARCHAR(255) NOT NULL    -- Description of cause (e.g., "Weather", "Mechanical")
);

-- =============================================
-- Create Fact Table
-- =============================================

-- Fact Table: Flight Status Events
CREATE TABLE FlightDW.FlightStatusFact (
    FlightStatusFactKey INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate Key
    FlightDateKey INT NOT NULL,            -- Foreign Key to Date Dimension
    AirlineKey INT NOT NULL,               -- Foreign Key to Airline Dimension
    OriginAirportKey INT NOT NULL,         -- Foreign Key to Origin Airport Dimension
    DestAirportKey INT NOT NULL,           -- Foreign Key to Destination Airport Dimension
    FlightKey INT NOT NULL,                -- Foreign Key to Flight Dimension
    
    -- Flight Metrics
    CRSDepTime INT,                        -- Scheduled Departure Time
    DepTime INT,                           -- Actual Departure Time
    DepDelayMinutes INT,                   -- Departure Delay in Minutes
    ArrTime INT,                           -- Actual Arrival Time
    ArrDelayMinutes INT,                   -- Arrival Delay in Minutes
    Canceled BIT NOT NULL,                 -- Was the flight canceled? (1 = Yes, 0 = No)
    Diverted BIT NOT NULL,                 -- Was the flight diverted? (1 = Yes, 0 = No)
    AirTime INT,                           -- Time in Air (Minutes)
    Distance INT,                          -- Flight Distance (Miles)
    TaxiOut INT,                           -- Taxi Out Time (Minutes)
    TaxiIn INT,                            -- Taxi In Time (Minutes)
    ActualElapsedTime INT,                 -- Actual Elapsed Time
    CRSElapsedTime INT,                    -- Scheduled Elapsed Time
    CauseKey INT NULL,                     -- Foreign Key to Cause Dimension (NULL if no cause)

    -- Foreign key constraints
    CONSTRAINT FK_FlightStatusFact_Date FOREIGN KEY (FlightDateKey) REFERENCES FlightDW.DateDim(DateKey),
    CONSTRAINT FK_FlightStatusFact_Airline FOREIGN KEY (AirlineKey) REFERENCES FlightDW.AirlineDim(AirlineKey),
    CONSTRAINT FK_FlightStatusFact_OriginAirport FOREIGN KEY (OriginAirportKey) REFERENCES FlightDW.AirportDim(AirportKey),
    CONSTRAINT FK_FlightStatusFact_DestAirport FOREIGN KEY (DestAirportKey) REFERENCES FlightDW.AirportDim(AirportKey),
    CONSTRAINT FK_FlightStatusFact_Flight FOREIGN KEY (FlightKey) REFERENCES FlightDW.FlightDim(FlightKey),
    CONSTRAINT FK_FlightStatusFact_Cause FOREIGN KEY (CauseKey) REFERENCES FlightDW.CauseDim(CauseKey)
);


CREATE TABLE StagingFlights (
    FlightDate DATE,                   -- Fecha del vuelo
    AirlineCode VARCHAR(50),          -- Código de la aerolínea (relacionado con AirlineDim)
    Origin VARCHAR(50),               -- Código del aeropuerto de origen
    Destination VARCHAR(50),          -- Código del aeropuerto de destino
    Cancelled BIT,                     -- Vuelo cancelado (0 = No, 1 = Sí)
    Diverted BIT,                      -- Vuelo desviado (0 = No, 1 = Sí)
    CRSDepTime INT,                    -- Hora programada de salida
    DepTime INT,                       -- Hora real de salida
    DepDelayMinutes INT,               -- Minutos de retraso en la salida
    DepDelay INT,                      -- Indicador de retraso en la salida
    ArrTime INT,                       -- Hora real de llegada
    ArrDelayMinutes INT,               -- Minutos de retraso en la llegada
    AirTime INT,                       -- Tiempo total en el aire
    CRSElapsedTime INT,                -- Tiempo estimado del vuelo
    ActualElapsedTime INT,             -- Tiempo real transcurrido del vuelo
    Distance INT,                      -- Distancia del vuelo
    Year INT,                          -- Año del vuelo
    Quarter INT,                       -- Trimestre del año
    Month INT,                         -- Mes del vuelo
    DayOfMonth INT,                    -- Día del mes
    DayOfWeek INT,                     -- Día de la semana
    MarketingAirlineNetwork VARCHAR(50), -- Código de la aerolínea de marketing (puede ser diferente a la operativa)
    OperatedCodeSharePartners VARCHAR(50), -- Detalles sobre si es operado por socios de código compartido
    FlightNumber VARCHAR(50),         -- Número de vuelo de la aerolínea
    TailNumber VARCHAR(50),           -- Número de registro de la aeronave (tail number)
    OriginAirportID INT,               -- ID del aeropuerto de origen
    OriginCityMarketID INT,            -- ID del mercado de la ciudad de origen
    OriginCityName VARCHAR(100),      -- Nombre de la ciudad de origen
    OriginState VARCHAR(2),           -- Código del estado de origen
    DestAirportID INT,                 -- ID del aeropuerto de destino
    DestCityMarketID INT,              -- ID del mercado de la ciudad de destino
    DestCityName VARCHAR(100),        -- Nombre de la ciudad de destino
    DestState VARCHAR(20),             -- Código del estado de destino
    DepDel15 BIT,                      -- Indicador de retraso mayor a 15 minutos en la salida
    DepartureDelayGroups INT,          -- Grupos de retraso de la salida
    DepTimeBlk VARCHAR(50),           -- Bloque de tiempo de salida
    TaxiOut INT,                       -- Tiempo de taxi al salir
    WheelsOff INT,                     -- Hora en que el avión despegó
    WheelsOn INT,                      -- Hora en que el avión aterrizó
    TaxiIn INT,                        -- Tiempo de taxi al llegar
    CRSArrTime INT,                    -- Hora programada de llegada
    ArrDel15 BIT,                      -- Indicador de retraso mayor a 15 minutos en la llegada
    ArrivalDelayGroups INT,            -- Grupos de retraso de la llegada
    ArrTimeBlk VARCHAR(20),           -- Bloque de tiempo de llegada
    DistanceGroup INT,                 -- Grupo de distancia
    DivAirportLandings INT             -- Número de aterrizajes en aeropuertos de desvío (si aplica)
);
