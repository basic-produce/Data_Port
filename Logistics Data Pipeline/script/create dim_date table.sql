-- Create the dim_date table
CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    full_date DATE,
    day_of_month INT,
    day_name VARCHAR(9),
    month_number INT,
    month_name VARCHAR(9),
    year INT,
    quarter VARCHAR(2),
    is_weekend BIT
);

-- Variables for date range
DECLARE @start_date DATE = '2022-01-01';
DECLARE @end_date DATE = '2023-05-01';

-- Temporary table to hold the date range
CREATE TABLE #temp_dates (date_value DATE);

-- Insert the date range into the temporary table
WHILE @start_date <= @end_date
BEGIN
    INSERT INTO #temp_dates (date_value) VALUES (@start_date);
    SET @start_date = DATEADD(DAY, 1, @start_date);
END;

-- Insert data into the dim_date table from the temporary table
INSERT INTO dim_date (date_key, full_date, day_of_month, day_name, month_number, month_name, year, quarter, is_weekend)
SELECT
    date_value,
    date_value,
    DAY(date_value),
    DATENAME(WEEKDAY, date_value),
    MONTH(date_value),
    DATENAME(MONTH, date_value),
    YEAR(date_value),
    'Q' + CAST(DATEPART(QUARTER, date_value) AS VARCHAR(1)),
    CASE WHEN DATENAME(WEEKDAY, date_value) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
FROM
    #temp_dates;	

-- Drop the temporary table
DROP TABLE #temp_dates;

-- Variables for extended date range
DECLARE @start_date_extend DATE = '2023-05-02'; -- Start from May 2, 2023
DECLARE @end_date_extend DATE = '2023-12-31'; -- End on December 31, 2023

-- Temporary table to hold the extended date range
CREATE TABLE #temp_dates_extend (date_value DATE);

-- Insert the extended date range into the temporary table
WHILE @start_date_extend <= @end_date_extend
BEGIN
    INSERT INTO #temp_dates_extend (date_value) VALUES (@start_date_extend);
    SET @start_date_extend = DATEADD(DAY, 1, @start_date_extend);
END;

-- Insert data into the dim_date table for the extended date range
INSERT INTO dim_date (date_key, full_date, day_of_month, day_name, month_number, month_name, year, quarter, is_weekend)
SELECT
    date_value,
    date_value,
    DAY(date_value),
    DATENAME(WEEKDAY, date_value),
    MONTH(date_value),
    DATENAME(MONTH, date_value),
    YEAR(date_value),
    'Q' + CAST(DATEPART(QUARTER, date_value) AS VARCHAR(1)),
    CASE WHEN DATENAME(WEEKDAY, date_value) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
FROM
    #temp_dates_extend;	

-- Drop the temporary table for the extended date range
DROP TABLE #temp_dates_extend;

SELECT * FROM dim_date
order by date_key desc
