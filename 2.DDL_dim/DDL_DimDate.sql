-- ##########################################################################################
-- 1. Creating the Date dimension


-- a. find the The minimum Date in the data
--> It is 2014
SELECT min(ModifiedDate) From AdventureWorks.Person.Person
union all
SELECT min(ModifiedDate) From AdventureWorks.HumanResources.employee
union all
SELECT min(ModifiedDate) From AdventureWorks.Sales.Customer


-- b. DDL: we will use this format:
USE AdventureWorksDW
GO
CREATE TABLE [dbo].[DimDate](
    [DateKey] [int] NOT NULL,
    [FullDate] [date] NOT NULL,
    [Day] [tinyint] NOT NULL,
    [DayName] [nvarchar](10) NOT NULL,
    [DayNumOfWeek] [tinyint] NOT NULL,
    [DayNumOfYear] [smallint] NOT NULL,
    [Month] [tinyint] NOT NULL,
    [MonthName] [nvarchar](10) NOT NULL,
    [Quarter] [tinyint] NOT NULL,
    [Year] [smallint] NOT NULL,
    [WeekNumOfYear] [tinyint] NOT NULL,
    CONSTRAINT [PK_DimDate_DateKey] PRIMARY KEY CLUSTERED 
    (
        [DateKey] ASC
    )
)


-- c. DML: we will generate data from 2010 to 2030 
-- Nested CTE
DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WITH DateCTE AS (
    SELECT @StartDate AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateCTE
    WHERE FullDate < @EndDate
)
INSERT INTO [AdventureWorksDW].[dbo].[DimDate] (
    [DateKey],
    [FullDate],
    [Day],
    [DayName],
    [DayNumOfWeek],
    [DayNumOfYear],
    [Month],
    [MonthName],
    [Quarter],
    [Year],
    [WeekNumOfYear]
)
SELECT 
    -- DateKey in YYYYMMDD format
    CAST(CONVERT(VARCHAR(8), FullDate, 112) AS INT) AS DateKey,
    -- FullDate
    FullDate AS FullDate,
    -- Day of Month
    DATEPART(DAY, FullDate) AS [Day],
    -- Day Name
    DATENAME(WEEKDAY, FullDate) AS [DayName],
    -- Day Number of Week (1-7)
    DATEPART(WEEKDAY, FullDate) AS [DayNumOfWeek],
    -- Day Number of Year (1-366)
    DATEPART(DAYOFYEAR, FullDate) AS [DayNumOfYear],
    -- Month Number (1-12)
    DATEPART(MONTH, FullDate) AS [Month],
    -- Month Name
    DATENAME(MONTH, FullDate) AS [MonthName],
    -- Calendar Quarter (1-4)
    DATEPART(QUARTER, FullDate) AS [Quarter],
    -- Calendar Year
    DATEPART(YEAR, FullDate) AS [Year],
    -- Week Number of Year (1-53)
    DATEPART(WEEK, FullDate) AS [WeekNumOfYear]
FROM DateCTE
OPTION (MAXRECURSION 0);

-- d. Validate
SELECT 
    COUNT(*) AS TotalRows,
    MIN([Year]) AS EarliestYear,
    MAX([Year]) AS LatestYear,
    MIN([FullDate]) AS EarliestDate,
    MAX([FullDate]) AS LatestDate
FROM [AdventureWorksDW].[dbo].[DimDate];

SELECT TOP 20 * FROM [AdventureWorksDW].[dbo].[DimDate] ORDER BY [DateKey];




