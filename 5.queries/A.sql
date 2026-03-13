SELECT 
    d.FullDate, 
    SUM(f.NetAmount) AS DailyRevenue, 
    SUM(SUM(f.NetAmount)) OVER (ORDER BY d.FullDate) AS CumulativeDailyRevenue
FROM FactOrders f
JOIN DimDate d ON f.DateKey = d.DateKey
GROUP BY d.FullDate;



-------------

SELECT 
    d.Year, 
    d.Month, 
    d.FullDate, 
    SUM(f.ProfitAmount) AS DailyProfit, 
    SUM(SUM(f.ProfitAmount)) OVER (
        PARTITION BY d.Year, d.Month 
        ORDER BY d.FullDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS MonthToDateProfit
FROM FactOrders f
JOIN DimDate d ON f.DateKey = d.DateKey
GROUP BY d.Year, d.Month, d.FullDate
ORDER BY d.Year, d.Month, d.FullDate;


------------

SELECT 
    d.Year, 
    d.Month, 
    d.FullDate, 
    SUM(f.ProfitAmount) AS DailyProfit, 
    SUM(SUM(f.ProfitAmount)) OVER (
        PARTITION BY d.Year 
        ORDER BY d.FullDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS YearToDateProfit
FROM FactOrders f
JOIN DimDate d ON f.DateKey = d.DateKey
GROUP BY d.Year, d.Month, d.FullDate
ORDER BY d.Year, d.Month, d.FullDate;


--------------

SELECT 
    d.FullDate, 
    SUM(f.ProfitAmount) AS DailyProfit, 
    AVG(SUM(f.ProfitAmount)) OVER (
        ORDER BY d.FullDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAverageProfit
FROM FactOrders f
JOIN DimDate d ON f.DateKey = d.DateKey
GROUP BY d.FullDate
ORDER BY d.FullDate;

-----------------

WITH MonthlyRevenue AS (
    SELECT 
        d.Year, 
        d.MonthName,
        d.Month, 
        SUM(f.NetAmount) AS CurrentMonthRevenue
    FROM FactOrders f
    JOIN DimDate d ON f.DateKey = d.DateKey
    GROUP BY d.Year, d.MonthName, d.Month
),
Comparison AS (
    SELECT 
        Year,
        MonthName,
		Month,
        CurrentMonthRevenue,
        LAG(CurrentMonthRevenue, 1, 0) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue
    FROM MonthlyRevenue
)
SELECT 
    Year,
    MonthName,
    CurrentMonthRevenue,
    PreviousMonthRevenue,
    CASE 
        WHEN CurrentMonthRevenue > PreviousMonthRevenue THEN 'Growth' 
        WHEN CurrentMonthRevenue < PreviousMonthRevenue THEN 'Decline' 
        ELSE 'No Change' 
    END AS PerformanceTrend
FROM Comparison
ORDER BY Year, Month;


------------


WITH DailyRevenue AS (
    SELECT 
        d.FullDate, 
        SUM(f.NetAmount) AS DailyRevenue
    FROM FactOrders f
    JOIN DimDate d ON f.DateKey = d.DateKey
    GROUP BY d.FullDate
),
RevenueChange AS (
    SELECT 
        FullDate, 
        DailyRevenue, 
        DailyRevenue - LAG(DailyRevenue, 1, 0) OVER (ORDER BY FullDate) AS RevenueChange
    FROM DailyRevenue
),
RevenueAcceleration AS (
    SELECT 
        FullDate, 
        DailyRevenue, 
        RevenueChange, 
        RevenueChange - LAG(RevenueChange, 1, 0) OVER (ORDER BY FullDate) AS Acceleration
    FROM RevenueChange
)
SELECT 
    *, 
    CASE 
        WHEN Acceleration > 0 THEN 'Acceleration' 
        WHEN Acceleration < 0 THEN 'Deceleration' 
        ELSE 'No Change' 
    END AS AccelerationTrend
FROM RevenueAcceleration
ORDER BY FullDate;

--------------

