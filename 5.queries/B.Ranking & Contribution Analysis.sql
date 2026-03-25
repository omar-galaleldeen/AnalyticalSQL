--===============================-=========================================
-- 7.Rank products within each category based on revenue performance
--=========================================================================
SELECT 
    c.CategoryName AS Category,
    p.ProductName AS Product,
    SUM(f.NetAmount) AS TotalRevenue,
    RANK() OVER (
        PARTITION BY c.CategoryName 
        ORDER BY SUM(f.NetAmount) DESC
    ) AS RevenueRank
FROM AdventureWorksDW.dbo.FactOrders f
JOIN AdventureWorksDW.dbo.DimProduct p ON f.ProductKey = p.ProductKey
JOIN AdventureWorksDW.dbo.DimCategory c ON f.CategoryKey = c.CategoryKey
GROUP BY 
    c.CategoryName, 
    p.ProductName;


--===============================-=========================================
--8. Determine each product’s contribution to its category’s total revenue.
--=========================================================================

WITH ProductRevenue AS (
    SELECT 
        c.CategoryName AS Category,
        p.ProductName AS Product,
        SUM(f.NetAmount) AS Revenue
    FROM AdventureWorksDW.dbo.FactOrders f
    JOIN AdventureWorksDW.dbo.DimProduct p ON f.ProductKey = p.ProductKey
    JOIN AdventureWorksDW.dbo.DimCategory c ON f.CategoryKey = c.CategoryKey
    GROUP BY 
        c.CategoryName, 
        p.ProductName
)
SELECT 
    Category,
    Product,
    Revenue,
    SUM(Revenue) OVER (PARTITION BY Category) AS CategoryTotalRevenue,
    (Revenue / NULLIF(SUM(Revenue) OVER (PARTITION BY Category), 0)) * 100 AS ContributionPercentage
FROM ProductRevenue
ORDER BY Category, ContributionPercentage DESC;


--===============================-=========================================
--9. Identify high-impact products contributing to the majority of revenue (Pareto analysis).
--=========================================================================
WITH ProductRevenue AS (
    SELECT 
        p.ProductName AS Product,
        SUM(f.NetAmount) AS Revenue
    FROM AdventureWorksDW.dbo.FactOrders f
    JOIN AdventureWorksDW.dbo.DimProduct p ON f.ProductKey = p.ProductKey
    GROUP BY p.ProductName
),
CumulativeRevenue AS (
    SELECT 
        Product,
        Revenue,
        SUM(Revenue) OVER (ORDER BY Revenue DESC) AS RunningTotal,
        SUM(Revenue) OVER () AS GrandTotal
    FROM ProductRevenue
)
SELECT 
    Product,
    Revenue,
    RunningTotal,
    (RunningTotal / NULLIF(GrandTotal, 0)) * 100 AS CumulativePercentage
FROM CumulativeRevenue
WHERE (RunningTotal / NULLIF(GrandTotal, 0)) <= 0.80 
ORDER BY Revenue DESC;

--===============================-=========================================
--10. Rank regions according to profitability.
--=========================================================================

SELECT 
    c.Region,
    SUM(f.ProfitAmount) AS TotalProfit,
    RANK() OVER (ORDER BY SUM(f.ProfitAmount) DESC) AS ProfitabilityRank
FROM AdventureWorksDW.dbo.FactOrders f
JOIN AdventureWorksDW.dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.Region;


--===============================-=========================================
--11. Rank brands inside each category based on total profit generation.
--=========================================================================


SELECT 
    c.CategoryName AS Category,
    p.Brand,
    SUM(f.ProfitAmount) AS TotalProfit,
    RANK() OVER (
        PARTITION BY c.CategoryName 
        ORDER BY SUM(f.ProfitAmount) DESC
    ) AS BrandProfitRank
FROM AdventureWorksDW.dbo.FactOrders f
JOIN AdventureWorksDW.dbo.DimProduct p ON f.ProductKey = p.ProductKey
JOIN AdventureWorksDW.dbo.DimCategory c ON f.CategoryKey = c.CategoryKey
GROUP BY 
    c.CategoryName, 
    p.Brand;

