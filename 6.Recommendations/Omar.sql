-- ============================================================
-- Recommendation System:
-- ============================================================
-- Omar: 
-- Indicator 1: Purchase Frequency Intensity How many times was Product B bought together with Product A


-- Self join on to find products bought together
WITH CoPurchase AS (
    SELECT
        F1.ProductKey                                           AS ProductA,
        F2.ProductKey                                           AS ProductB,
        COUNT(DISTINCT F1.SalesOrderID)                         AS CountCoPurchase
    FROM AdventureWorksDW.dbo.FactOrders     F1
    JOIN AdventureWorksDW.dbo.FactOrders     F2
        ON  F1.SalesOrderID = F2.SalesOrderID                  -- same order
        AND F1.ProductKey  != F2.ProductKey                    -- different products
    GROUP BY F1.ProductKey, F2.ProductKey
),


-- Normalize to create a score 
Normalized AS (
    SELECT
        ProductA,
        ProductB,
        CountCoPurchase,
        -- Normalize against max co-purchase count for ProductA
        ROUND(
            CAST(CountCoPurchase AS FLOAT) / NULLIF(MAX(CountCoPurchase) 
            OVER ( PARTITION BY ProductA), 0) -- to divide by the max count of each product
        , 4)                                                                AS FrequencyScore  -- 0 to 1
    FROM CoPurchase
)

-- Final query
SELECT
    N.ProductA,
    PA.ProductName                                              AS ProductA_Name,
    N.ProductB,
    PB.ProductName                                              AS ProductB_Name,
    N.CountCoPurchase,
    N.FrequencyScore,
    -- Rank Product B candidates for Product A
    RANK() OVER (
        PARTITION BY N.ProductA
        ORDER BY N.FrequencyScore DESC
    )                                                           AS FrequencyRank
FROM Normalized          N
JOIN DimProduct         PA  ON N.ProductA = PA.ProductKey
JOIN DimProduct         PB  ON N.ProductB = PB.ProductKey
ORDER BY
    N.ProductA,FrequencyRank;