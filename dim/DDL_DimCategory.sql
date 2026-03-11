-- Dim_Category (category_key, category_name, parent_category, seasonal_flag)

SELECT * FROM AdventureWorks.Production.ProductSubcategory; --not all of them have a subcateg
SELECT * FROM AdventureWorks.Production.ProductCategory; -- no seasonal flag


-- DDL
USE [AdventureWorksDW]
GO
CREATE TABLE [dbo].[DimCategory](
    [CategoryKey] [int] PRIMARY KEY,
    [CategoryName] [nvarchar](50) NOT NULL,
    [ParentCategory] [nvarchar](50) NULL,  -- Made NULLable for top-level categories
    [ModifiedDate] [datetime] NOT NULL CONSTRAINT DF_DimCategory_ModifiedDate DEFAULT GETDATE())
GO
-- Added an ndex for faster lookups on CategoryName
CREATE INDEX [IX_DimCategory_CategoryName] ON [dbo].[DimCategory]([CategoryName]);
GO

-- Ingestion
WITH t1 as (
SELECT 
	PSG.ProductSubcategoryID as CategoryKey, 
	PSG.Name                 as CategoryName,
	-- PSG.ProductCategoryID as ParentCategoryKey, -- just to check some data
	PG.Name as ParentCategory,
	PSG.ModifiedDate as ModifiedDate
FROM AdventureWorks.Production.ProductSubcategory as PSG
LEFT JOIN AdventureWorks.Production.ProductCategory as PG
ON PSG.ProductCategoryID = PG.ProductCategoryID)

-- Population
INSERT INTO [AdventureWorksDW].[dbo].[DimCategory] (
    [CategoryKey],
    [CategoryName],
    [ParentCategory],
    [ModifiedDate]
)
SELECT 
    CategoryKey,
    CategoryName,
    ParentCategory,
    ModifiedDate
FROM t1

-- Use category key 0 for no category
INSERT INTO [AdventureWorksDW].[dbo].[DimCategory] (
    [CategoryKey],
    [CategoryName],
    [ParentCategory],
    [ModifiedDate]
) VALUES (0, 'Unassigned', NULL, CONVERT(DATETIME, '20250101', 112));

-- View the populated data
SELECT * FROM [AdventureWorksDW].[dbo].[DimCategory] ORDER BY CategoryKey;
GO