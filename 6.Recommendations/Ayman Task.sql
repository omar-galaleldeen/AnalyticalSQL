WITH CrossProductAssociation AS (
    -- Cross-product association strength: Logically fitting together (Bought in the same order) 
    SELECT 
        f1.ProductKey AS TargetProductKey,
        f2.ProductKey AS AssociatedProductKey,
        COUNT(DISTINCT f1.SalesOrderID) AS AssociationStrength
    FROM FactOrders f1
    JOIN FactOrders f2 ON f1.SalesOrderID = f2.SalesOrderID 
        AND f1.ProductKey <> f2.ProductKey
    GROUP BY f1.ProductKey, f2.ProductKey
),
ProfitabilityAndTrending AS (
    -- Profitability stability: High profit %, high selling items, and trending (recent 30-day sales) 
    SELECT 
        f.ProductKey,
        (SUM(f.ProfitAmount) / NULLIF(SUM(f.NetAmount), 0)) * 100 AS ProfitMarginPct,
        SUM(f.Quantity) AS TotalVolumeSold,
        SUM(CASE WHEN d.FullDate >= DATEADD(day, -30, GETDATE()) THEN f.Quantity ELSE 0 END) AS RecentTrendVolume
    FROM FactOrders f
    JOIN DimDate d ON f.DateKey = d.DateKey
    GROUP BY f.ProductKey
)
SELECT 
    cpa.TargetProductKey,
    cpa.AssociatedProductKey,
    cpa.AssociationStrength,
    pt.ProfitMarginPct,
    pt.TotalVolumeSold,
    pt.RecentTrendVolume
FROM CrossProductAssociation cpa
JOIN ProfitabilityAndTrending pt ON cpa.AssociatedProductKey = pt.ProductKey;