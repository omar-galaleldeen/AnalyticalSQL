
-- Exploring the 2 Databases (AdventureWorks + AdventureWorksDW):

USE [master];
GO
SELECT TABLE_NAME 
FROM AdventureWorksDWV2.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT TABLE_NAME 
FROM AdventureWorks.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


-- Exploring AdventureWorks to create the required DWH:

-- 1. Datedim
-- Use a key as the following 20251207

-- 2. Customer Dim
-- Customer dimension source
SELECT TOP 5 * FROM AdventureWorks.Sales.Customer; -- No Gender, no D.O.B 
SELECT * FROM AdventureWorks.Person.Person; 
SELECT TOP 5 * FROM AdventureWorks.Sales.SalesTerritory;


-- 3. Product Dim
SELECT * FROM AdventureWorks.Production.Product;
SELECT TOP 5 * FROM AdventureWorks.Production.ProductSubcategory; --not all of them have a subcateg
SELECT TOP 5 * FROM AdventureWorks.Production.ProductCategory; -- no seasonal flag

-- 4. Dim Payment
SELECT TOP 5 * FROM AdventureWorks.Sales.CreditCard; -- Credit card types, if in the orders table it is null then cash
SELECT TOP 5 * FROM AdventureWorks.Sales.SalesOrderHeader; -- fact

select CAST(modifiedDAte as time) from AdventureWorks.Sales.SalesOrderHeader
group by (CAST(modifiedDAte as time))

select modifiedDAte from AdventureWorks.Sales.SalesOrderHeader


-- 6. Dim shipping
SELECT TOP 5 * FROM AdventureWorks.Purchasing.ShipMethod; -- has the method and base order price and shipping price, we need to calclate the delivery days or assume it
SELECT TOP 5 * FROM AdventureWorks.Sales.SalesOrderHeader; -- fact for ship date


-- Fact
SELECT TOP 5 * FROM AdventureWorks.Sales.SalesOrderHeader;
SELECT TOP 5 * FROM AdventureWorks.Sales.SalesOrderDetail; -- missing cost and profit











