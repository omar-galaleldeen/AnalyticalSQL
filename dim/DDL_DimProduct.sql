-- Requirements:
-- Dim (product_key, product_id, product_name, brand, subcategory, launch_date)

-- Exploration
SELECT * FROM AdventureWorks.Production.Product;
-- Note: 
-- Makeflag 0 is an inhouse product while 1 is bought


-- Exploration: Our DimCategory
SELECT * FROM [AdventureWorksDW].[dbo].[DimCategory]; -- The category key here is the subcategory key in the OLTP.Products table

-- Source table
WITH t1 as(
SELECT
	APP.ProductID,
	APP.ProductNumber, --Candidate Key: contains product + specific version
    APP.Name as ProductName,  -- Product Name + specific version i.e. Small, Medium, Large
    APM.Name as ParentProductName,
	CASE WHEN MakeFlag = 1 THEN 'Manufactured' ELSE 'In-House' end as Brand,
	ProductSubcategoryID as CategoryKey,
    APP.StandardCost as Cost,
    -- APP.ListPrice as Price, -- Price will be excluded as it is calculated from fact table.
    APP.SellStartdate as LaunchDate,
    APP.SellEndDate as EndDate,
    APP.SafetyStockLevel as SafeStockQuantity,
    INV.quantity as StockQuantity,
    -- Stock classifier
    CASE WHEN inv.quantity = 0 then 'Out-of-Stock'
         WHEN APP.SafetyStockLevel >  INV.quantity Then 'Critical' 
         else 'In-Stock' end as 'StockStatus'
FROM AdventureWorks.Production.Product APP
LEFT JoIN AdventureWorks.Production.ProductModel APM
ON APP.ProductModelID = APM.ProductModelID
LEFT  JOIN AdventureWorks.Production.ProductInventory INV
ON APP.productID = INV.productID)


-- Handle Nulls in T1 
SELECT 
    ProductID,
    ProductNumber,
    ProductName,
    ISNULL(ParentProductName, ProductName) AS ParentProductName,
    Brand,
    ISNULL(CategoryKey, 0) as CategoryKey,
    Cost,
    LaunchDate,
    EndDate,
    SafeStockQuantity,
    StockQuantity,
    StockStatus
FROM T1





SELECT TOP (1000) [ProductModelID]
      ,[Name]
      ,[CatalogDescription]
      ,[Instructions]
      ,[rowguid]
      ,[ModifiedDate]
  FROM [AdventureWorks].[Production].[ProductModel]