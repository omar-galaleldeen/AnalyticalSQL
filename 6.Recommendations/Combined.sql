-- ============================================================
-- RECOMMENDATION SYSTEM — Final Scoring
-- ============================================================
USE AdventureWorksDW;

-- Omar: Bug fix: declare MaxDate as a variable to use inside aggregate inside subqueries
DECLARE @MaxDate DATE = (
    SELECT MAX(D.FullDate)
    FROM DimDate    D
    JOIN FactOrders F ON D.DateKey = F.DateKey
);

-- ============================================================
-- Indicator 1: Purchase Frequency Intensity
-- ============================================================
WITH CoPurchase AS (
    SELECT
        F1.ProductKey                                           AS ProductA,
        F2.ProductKey                                           AS ProductB,
        COUNT(DISTINCT F1.SalesOrderID)                         AS CountCoPurchase
    FROM FactOrders F1
    JOIN FactOrders F2
        ON  F1.SalesOrderID = F2.SalesOrderID
        AND F1.ProductKey  != F2.ProductKey
    GROUP BY F1.ProductKey, F2.ProductKey
),
FrequencyScore AS (
    SELECT
        ProductA,
        ProductB,
        CountCoPurchase,
        ROUND(
            CAST(CountCoPurchase AS FLOAT) /
            NULLIF(MAX(CountCoPurchase) OVER (PARTITION BY ProductA), 0)
        , 4)                                                    AS FrequencyScore
    FROM CoPurchase
),

-- ============================================================
-- Indicator 2: Recency of Customer Demand
-- ============================================================
RecencyRaw AS (
    SELECT
        F1.ProductKey                                           AS ProductA,
        F2.ProductKey                                           AS ProductB,
        SUM(CASE
            WHEN DATEDIFF(MONTH, D.FullDate, GETDATE()) <= 12  THEN 1.0
            WHEN DATEDIFF(MONTH, D.FullDate, GETDATE()) <= 18  THEN 0.6
            WHEN DATEDIFF(MONTH, D.FullDate, GETDATE()) <= 24  THEN 0.3
            ELSE                                                     0.1
        END)                                                    AS RecencyRaw
    FROM FactOrders     F1
    JOIN FactOrders     F2  ON  F1.SalesOrderID = F2.SalesOrderID
                            AND F1.ProductKey  != F2.ProductKey
    JOIN DimDate        D   ON  F1.DateKey      = D.DateKey
    GROUP BY F1.ProductKey, F2.ProductKey
),
RecencyScore AS (
    SELECT
        ProductA,
        ProductB,
        RecencyRaw,
        ROUND(
            CAST(RecencyRaw AS FLOAT) /
            NULLIF(MAX(RecencyRaw) OVER (PARTITION BY ProductA), 0)
        , 4)                                                    AS RecencyScore
    FROM RecencyRaw
),

-- ============================================================
-- Indicator 3: Category Trend Strength
-- Same subcategory = 1.0, same parent = 0.5, else 0.0
-- ============================================================
CategoryScore AS (
    SELECT
        P1.ProductKey                                           AS ProductA,
        P2.ProductKey                                           AS ProductB,
        CASE
            WHEN P1.CategoryKey    = P2.CategoryKey             THEN 1.0
            WHEN C1.ParentCategory = C2.ParentCategory          THEN 0.5
            ELSE                                                     0.0
        END                                                     AS CategoryScore
    FROM DimProduct         P1
    JOIN DimProduct         P2  ON  P1.ProductKey   != P2.ProductKey
    JOIN DimCategory        C1  ON  P1.CategoryKey   = C1.CategoryKey
    JOIN DimCategory        C2  ON  P2.CategoryKey   = C2.CategoryKey
),

-- ============================================================
-- Indicator 4: Cross-Product Association Strength
-- ============================================================
AssociationRaw AS (
    SELECT
        F1.ProductKey                                           AS ProductA,
        F2.ProductKey                                           AS ProductB,
        COUNT(DISTINCT F1.SalesOrderID)                         AS AssociationCount
    FROM FactOrders F1
    JOIN FactOrders F2  ON  F1.SalesOrderID = F2.SalesOrderID
                        AND F1.ProductKey  != F2.ProductKey
    GROUP BY F1.ProductKey, F2.ProductKey
),
AssociationScore AS (
    SELECT
        ProductA,
        ProductB,
        AssociationCount,
        ROUND(
            CAST(AssociationCount AS FLOAT) /
            NULLIF(MAX(AssociationCount) OVER (PARTITION BY ProductA), 0)
        , 4)                                                    AS AssociationScore
    FROM AssociationRaw
),

-- ============================================================
-- Indicator 5: Profitability Stability
-- ============================================================
-- Bug Fix: @MaxDate used instead of subquery inside aggregate
ProfitabilityRaw AS (
    SELECT
        F.ProductKey,
        ROUND((SUM(F.ProfitAmount) / NULLIF(SUM(F.NetAmount), 0)) * 100, 4)    AS ProfitMarginPct,
        SUM(F.Quantity)                                                          AS TotalVolumeSold,
        SUM(CASE
                WHEN D.FullDate >= DATEADD(DAY, -30, @MaxDate)                  -- ✅ variable instead of subquery
                THEN F.Quantity ELSE 0
            END)                                                                 AS RecentTrendVolume
    FROM FactOrders F
    JOIN DimDate    D ON F.DateKey = D.DateKey
    GROUP BY F.ProductKey
),
ProfitabilityScore AS (
    SELECT
        ProductKey,
        ProfitMarginPct,
        TotalVolumeSold,
        RecentTrendVolume,
        ROUND(ProfitMarginPct /
              NULLIF(MAX(ProfitMarginPct) OVER(), 0), 4)                         AS ProfitScore,
        ROUND(CAST(TotalVolumeSold AS FLOAT) /
              NULLIF(MAX(TotalVolumeSold) OVER(), 0), 4)                         AS VolumeScore,
        ROUND(CAST(ISNULL(RecentTrendVolume, 0) AS FLOAT) /
              NULLIF(MAX(ISNULL(RecentTrendVolume, 0)) OVER(), 0), 4)            AS TrendScore
    FROM ProfitabilityRaw
),

-- ============================================================
-- Indicator 6: Stock Availability
-- ============================================================
StockScore AS (
    SELECT
        ProductKey,
        StockQuantity,
        CASE
            WHEN StockQuantity >= 50 THEN 1.0
            WHEN StockQuantity >= 10 THEN 0.5
            WHEN StockQuantity >  0  THEN 0.3
            ELSE                          0.0
        END                                                     AS StockScore
    FROM DimProduct
),

-- ============================================================
-- Final Scoring
-- Frequency    30%
-- Recency      20%
-- Association  20%
-- Profitability 15%
-- Category     10%
-- Stock         5%
-- ============================================================
FinalScore AS (
    SELECT
        FS.ProductA,
        FS.ProductB,
        FS.FrequencyScore,
        RS.RecencyScore,
        CS.CategoryScore,
        ASC2.AssociationScore,
        PS.ProfitScore,
        PS.VolumeScore,
        PS.TrendScore,
        SS.StockScore,
        ROUND(
            (FS.FrequencyScore                                      * 0.30) +
            (RS.RecencyScore                                        * 0.20) +
            (ASC2.AssociationScore                                  * 0.20) +
            ((PS.ProfitScore +
              PS.VolumeScore +
              ISNULL(PS.TrendScore, 0))                             * 0.05) +
            (CS.CategoryScore                                       * 0.10) +
            (SS.StockScore                                          * 0.05)
        , 4)                                                        AS RecommendationScore
    FROM FrequencyScore         FS
    JOIN RecencyScore           RS      ON  FS.ProductA = RS.ProductA
                                        AND FS.ProductB = RS.ProductB
    JOIN CategoryScore          CS      ON  FS.ProductA = CS.ProductA
                                        AND FS.ProductB = CS.ProductB
    JOIN AssociationScore       ASC2    ON  FS.ProductA = ASC2.ProductA
                                        AND FS.ProductB = ASC2.ProductB
    JOIN ProfitabilityScore     PS      ON  FS.ProductB = PS.ProductKey
    JOIN StockScore             SS      ON  FS.ProductB = SS.ProductKey
    WHERE SS.StockScore > 0.0
),

-- ============================================================
-- Rank top 4 recommendations per product
-- ============================================================
Ranked AS (
    SELECT
        F.ProductA,
        PA.ProductName                                          AS BaseProduct,
        F.ProductB,
        PB.ProductName                                          AS RecommendedProduct,
        PB.StockStatus,
        F.FrequencyScore,
        F.RecencyScore,
        F.CategoryScore,
        F.AssociationScore,
        F.ProfitScore,
        F.VolumeScore,
        F.TrendScore,
        F.StockScore,
        F.RecommendationScore,
        RANK() OVER (
            PARTITION BY F.ProductA
            ORDER BY F.RecommendationScore DESC
        )                                                       AS RecommendationRank
    FROM FinalScore         F
    JOIN DimProduct         PA  ON F.ProductA = PA.ProductKey
    JOIN DimProduct         PB  ON F.ProductB = PB.ProductKey
)

-- ============================================================
-- Final Output: Top 4 recommendations per product
-- ============================================================
SELECT
    ProductA,
    BaseProduct,
    ProductB,
    RecommendedProduct,
    StockStatus,
    FrequencyScore,
    RecencyScore,
    CategoryScore,
    AssociationScore,
    ProfitScore,
    VolumeScore,
    TrendScore,
    StockScore,
    RecommendationScore,
    RecommendationRank
FROM Ranked
WHERE RecommendationRank <= 5
-- if you want this table to be for a specific product just specify ProductA = X
ORDER BY
    ProductA,
    RecommendationRank;