-- Requirements:
-- Dim (product_key, product_id, product_name, brand, subcategory, launch_date)

-- Exploration
SELECT * FROM AdventureWorks.Production.Product;
-- Note: 
-- Makeflag 0 is an inhouse product while 1 is bought


-- Exploration: Our DimCategory
SELECT * FROM [AdventureWorksDW].[dbo].[DimCategory]; -- The category key here is the subcategory key in the OLTP.Products table

-- DDL
CREATE TABLE [AdventureWorksDW].[dbo].[DimProduct] (
    ProductKey          INT             PRIMARY KEY,
    ProductID           NVARCHAR(50),
    ProductName         NVARCHAR(100),
    ParentProductName   NVARCHAR(100),
    Brand               NVARCHAR(50),
    CategoryKey         INT             DEFAULT 0 REFERENCES [AdventureWorksDW].[dbo].[DimCategory](CategoryKey),
    Cost                MONEY,
    LaunchDate          DATETIME,
    EndDate             DATETIME,
    SafeStockQuantity   INT,
    StockQuantity       INT,
    StockStatus         NVARCHAR(20)    CHECK (StockStatus IN ('In-Stock', 'Critical', 'Out-of-Stock'))
);


-- Source table
TRUNCATE TABLE [AdventureWorksDW].[dbo].[DimProduct];

WITH T1 AS (
    SELECT
        APP.ProductID,
        APP.ProductNumber,
        APP.Name                                                        AS ProductName,
        APM.Name                                                        AS ParentProductName,
        CASE WHEN MakeFlag = 1 THEN 'Manufactured' ELSE 'In-House' END AS Brand,
        ProductSubcategoryID                                            AS CategoryKey,
        APP.StandardCost                                                AS Cost,
        APP.SellStartDate                                               AS LaunchDate,
        APP.SellEndDate                                                 AS EndDate,
        APP.SafetyStockLevel                                            AS SafeStockQuantity,
        INV.StockQuantity                                               -- from subquery
    FROM AdventureWorks.Production.Product APP
    LEFT JOIN AdventureWorks.Production.ProductModel APM
        ON APP.ProductModelID = APM.ProductModelID
    LEFT JOIN (
                SELECT ProductID, SUM(Quantity) AS StockQuantity       -- aggregating across al locations
                FROM AdventureWorks.Production.ProductInventory
                GROUP BY ProductID
              ) INV
        ON APP.ProductID = INV.ProductID
),
T2 AS (
    SELECT
        ProductID                              AS ProductKey,
        ProductNumber                          AS ProductID,
        ProductName,
        ISNULL(ParentProductName, ProductName) AS ParentProductName,
        Brand,
        ISNULL(CategoryKey, 0)                 AS CategoryKey,
        Cost,
        LaunchDate,
        EndDate,
        SafeStockQuantity,
        ISNULL(StockQuantity, 0)               AS StockQuantity,
        CASE
            WHEN ISNULL(StockQuantity, 0) = 0                 THEN 'Out-of-Stock'
            WHEN SafeStockQuantity > ISNULL(StockQuantity, 0) THEN 'Critical'
            ELSE                                                    'In-Stock'
        END                                                     AS StockStatus
    FROM T1
)

INSERT INTO [AdventureWorksDW].[dbo].[DimProduct] (
    ProductKey,
    ProductID,
    ProductName,
    ParentProductName,
    Brand,
    CategoryKey,
    Cost,
    LaunchDate,
    EndDate,
    SafeStockQuantity,
    StockQuantity,
    StockStatus
)
SELECT
    ProductKey,
    ProductID,
    ProductName,
    ParentProductName,
    Brand,
    CategoryKey,
    Cost,
    LaunchDate,
    EndDate,
    SafeStockQuantity,
    StockQuantity,
    StockStatus
FROM T2;

-- Validate:
SELECT * FROM [AdventureWorksDW].[dbo].[DimProduct];