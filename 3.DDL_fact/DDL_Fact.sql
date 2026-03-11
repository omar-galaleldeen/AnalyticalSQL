-- Exploring Data:
SELECT * 
FROM AdventureWorks.Sales.SalesOrderHeader soh 
JOIN  AdventureWorks.Sales.SalesOrderDetail  sod
ON soh.SalesOrderID = sod.SalesOrderID

-- Same row count
SELECT count(distinct SalesOrderID)  FROM AdventureWorks.Sales.SalesOrderHeader
UNION ALL
SELECT count(distinct SalesOrderID)  FROM AdventureWorks.Sales.SalesOrderDetail
UNION ALL
SELECT count(*)FROM AdventureWorks.Sales.SalesOrderDetail

-- DDL:
CREATE TABLE [AdventureWorksDW].[dbo].[FactOrders](
    -- Surrogate Key
    FactKey             INT             IDENTITY(1,1)   PRIMARY KEY,

    -- Degenerate Dimensions (no dimension table)
    SalesOrderID        INT             NOT NULL, 

    -- Foreign Keys
    DateKey             INT             NOT NULL REFERENCES [dbo].[DimDate](DateKey),
    CustomerKey         INT             NOT NULL REFERENCES [dbo].[DimCustomer](CustomerKey),
    ProductKey          INT             NOT NULL REFERENCES [dbo].[DimProduct](ProductKey),
    CategoryKey         INT             NOT NULL REFERENCES [dbo].[DimCategory](CategoryKey),
    PaymentMethodKey    TINYINT         NOT NULL REFERENCES [dbo].[DimPaymentMethod](PaymentMethodKey),
    ShipMethodKey       INT             NOT NULL REFERENCES [dbo].[DimShipMethod](ShipMethodKey),
    
    
    -- Measures
    Quantity            SMALLINT        NOT NULL,
    UnitPrice           MONEY           NOT NULL,
    GrossAmount         MONEY           NOT NULL,   -- UnitPrice * Quantity
    DiscountAmount      MONEY           NOT NULL,   -- UnitPriceDiscount * UnitPrice * Quantity
    NetAmount           MONEY           NOT NULL,   -- LineTotal (after discount)
    CostAmount          MONEY           NOT NULL,   -- StandardCost * Quantity
    ProfitAmount        MONEY           NOT NULL    -- NetAmount - CostAmount

);
GO

-- Ingestion
WITH T1 AS (
    SELECT
        CAST(CONVERT(VARCHAR(8), soh.OrderDate, 112) AS INT)        AS DateKey,
        soh.CustomerID                                               AS CustomerKey,
        sod.ProductID                                                AS ProductKey,
        ISNULL(pp.ProductSubcategoryID, 0)                          AS CategoryKey,
        soh.ShipMethodID                                             AS ShipMethodKey,
        CASE
            WHEN soh.CreditCardID IS NULL THEN 2
            ELSE 1
        END                                                          AS PaymentMethodKey,
        soh.SalesOrderID                                             AS SalesOrderID,
        sod.OrderQty                                                 AS Quantity,
        sod.UnitPrice                                                AS UnitPrice,
        sod.UnitPrice * sod.OrderQty                                 AS GrossAmount,
        sod.UnitPriceDiscount * sod.UnitPrice * sod.OrderQty        AS DiscountAmount,
        sod.LineTotal                                                AS NetAmount,
        pp.StandardCost * sod.OrderQty                              AS CostAmount
    FROM AdventureWorks.Sales.SalesOrderHeader   soh
    JOIN AdventureWorks.Sales.SalesOrderDetail   sod
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN AdventureWorks.Production.Product       pp
        ON sod.ProductID = pp.ProductID
),
T2 AS (
    SELECT
        DateKey,
        CustomerKey,
        ProductKey,
        CategoryKey,
        ShipMethodKey,
        PaymentMethodKey,
        SalesOrderID,
        Quantity,
        UnitPrice,
        GrossAmount,
        DiscountAmount,
        NetAmount,
        CostAmount,
        NetAmount - CostAmount  AS ProfitAmount
    FROM T1
)
INSERT INTO [AdventureWorksDW].[dbo].[FactOrders] (
    DateKey,
    CustomerKey,
    ProductKey,
    CategoryKey,
    ShipMethodKey,
    PaymentMethodKey,
    SalesOrderID,
    Quantity,
    UnitPrice,
    GrossAmount,
    DiscountAmount,
    NetAmount,
    CostAmount,
    ProfitAmount
)
SELECT
    DateKey,
    CustomerKey,
    ProductKey,
    CategoryKey,
    ShipMethodKey,
    PaymentMethodKey,
    SalesOrderID,
    Quantity,
    UnitPrice,
    GrossAmount,
    DiscountAmount,
    NetAmount,
    CostAmount,
    ProfitAmount
FROM T2;

-- Validate
SELECT TOP 100 * FROM [AdventureWorksDW].[dbo].[FactOrders];
SELECT COUNT(*) AS TotalRows FROM [AdventureWorksDW].[dbo].[FactOrders];








-- DDL:


-- Ingestion:
TRUNCATE TABLE [AdventureWorksDW].[dbo].[FactOrders];

WITH T1 AS (
    SELECT
        CAST(CONVERT(VARCHAR(8), soh.OrderDate, 112) AS INT)        AS DateKey,
        soh.CustomerID                                               AS CustomerKey,
        sod.ProductID                                                AS ProductKey,
        ISNULL(pp.ProductSubcategoryID, 0)                          AS CategoryKey,
        soh.ShipMethodID                                             AS ShipMethodKey,
        CASE
            WHEN soh.CreditCardID IS NULL THEN 2
            ELSE 1
        END                                                          AS PaymentMethodKey,
        soh.SalesOrderID                                             AS SalesOrderID,
        sod.OrderQty                                                 AS Quantity,
        sod.UnitPrice                                                AS UnitPrice,
        sod.UnitPrice * sod.OrderQty                                 AS GrossAmount,
        sod.UnitPriceDiscount * sod.UnitPrice * sod.OrderQty        AS DiscountAmount,
        sod.LineTotal                                                AS NetAmount,
        pp.StandardCost * sod.OrderQty                              AS CostAmount
    FROM AdventureWorks.Sales.SalesOrderHeader   soh
    JOIN AdventureWorks.Sales.SalesOrderDetail   sod
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN AdventureWorks.Production.Product       pp
        ON sod.ProductID = pp.ProductID
),
T2 AS (
    SELECT
        DateKey,
        CustomerKey,
        ProductKey,
        CategoryKey,
        ShipMethodKey,
        PaymentMethodKey,
        SalesOrderID,
        Quantity,
        UnitPrice,
        GrossAmount,
        DiscountAmount,
        NetAmount,
        CostAmount,
        NetAmount - CostAmount                                       AS ProfitAmount
    FROM T1
)
INSERT INTO [AdventureWorksDW].[dbo].[FactOrders] (
    DateKey,
    CustomerKey,
    ProductKey,
    CategoryKey,
    ShipMethodKey,
    PaymentMethodKey,
    SalesOrderID,
    Quantity,
    UnitPrice,
    GrossAmount,
    DiscountAmount,
    NetAmount,
    CostAmount,
    ProfitAmount
)
SELECT
    DateKey,
    CustomerKey,
    ProductKey,
    CategoryKey,
    ShipMethodKey,
    PaymentMethodKey,
    SalesOrderID,
    Quantity,
    UnitPrice,
    GrossAmount,
    DiscountAmount,
    NetAmount,
    CostAmount,
    ProfitAmount
FROM T2;

-- Validate
SELECT TOP 20 * FROM [AdventureWorksDW].[dbo].[FactOrders];
SELECT COUNT(*) AS TotalRows FROM [AdventureWorksDW].[dbo].[FactOrders];