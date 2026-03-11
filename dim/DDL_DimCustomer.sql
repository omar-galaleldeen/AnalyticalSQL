
-- Add gender column
ALTER TABLE AdventureWorks.Person.Person
ADD Gender CHAR(1) NOT NULL
CONSTRAINT DF_Person_gender DEFAULT 'M' WITH VALUES;

ALTER TABLE AdventureWorks.Person.Person
ADD CONSTRAINT CK_Person_gender CHECK (gender IN ('M', 'F'));

-- #############################################################################
-- Brute forcing and assigning the gender
-- > use script in repo
-- #############################################################################


-- Customer Table
SELECT * FROM AdventureWorks.Sales.Customer; -- No D.O.B

-- Person Table:
-- It contains: PersonTypeIN = Individual customer, SC = Store Contact, SP = Salesperson, EM = Employee, VC = Vendor contact
SELECT * FROM AdventureWorks.Person.Person;

-- Territory Table:
SELECT * FROM AdventureWorks.Sales.SalesTerritory;


-- Creating source table
SELECT 
	cst.CustomerID as CustomerKey,
	cst.AccountNumber as AccountID,
	cst.PersonID as PersonID,
	CASE 
		WHEN prs.Gender is null AND cst.CustomerID % 2 = 0 THEN 'M'
		WHEN prs.Gender is null AND cst.CustomerID % 2 != 0 THEN 'F'
		ELSE prs.Gender  -- randomizing the 700 records that do not have person data
	END as Gender, 
	area.Name as Zone,
	area.CountryRegionCode as Country,
	area.[Group] as Region,
	cst.ModifiedDate as RegisterationDate
FROM AdventureWorks.Sales.Customer AS cst
LEFT JOIN AdventureWorks.Person.Person as prs
	ON cst.PersonID = prs.BusinessEntityID
LEFT JOIN AdventureWorks.Sales.SalesTerritory as area
	ON cst.TerritoryID = area.TerritoryID
 
-- DDL:
CREATE TABLE [AdventureWorksDW].[dbo].[DimCustomer](
    [CustomerKey] INT NOT NULL,
    [AccountID] NVARCHAR(10) NOT NULL,  -- Based on AccountNumber computed column pattern
    [PersonID] INT NULL,
    [Gender] NCHAR(1) NULL,  -- 'M' or 'F'
    [Zone] NVARCHAR(50) NULL, 
    [Country] NVARCHAR(3) NULL,  -- Matches CountryRegionCode length
    [Region] NVARCHAR(50) NULL,  -- Matches [Group] column in SalesTerritory
    [RegistrationDate] DATETIME NOT NULL,
    CONSTRAINT [PK_CustomerAnalysis_CustomerKey] PRIMARY KEY CLUSTERED (
        [CustomerKey] ASC
    )
) 
GO


-- Insertion
WITH T1 as (
SELECT 
	cst.CustomerID as CustomerKey,
	cst.AccountNumber as AccountID,
	cst.PersonID as PersonID,
	CASE 
		WHEN prs.Gender is null AND cst.CustomerID % 2 = 0 THEN 'M'
		WHEN prs.Gender is null AND cst.CustomerID % 2 != 0 THEN 'F'
		ELSE prs.Gender  -- randomizing the 700 records that do not have person data
	END as Gender, 
	area.Name as Zone,
	area.CountryRegionCode as Country,
	area.[Group] as Region,
	cst.ModifiedDate as RegisterationDate
FROM AdventureWorks.Sales.Customer AS cst
LEFT JOIN AdventureWorks.Person.Person as prs
	ON cst.PersonID = prs.BusinessEntityID
LEFT JOIN AdventureWorks.Sales.SalesTerritory as area
	ON cst.TerritoryID = area.TerritoryID)

INSERT INTO [AdventureWorksDW].[dbo].[DimCustomer](
    CustomerKey,
    AccountID,
    PersonID,
    Gender,
    Zone,
    Country,
    Region,
    RegistrationDate)
SELECT 
    CustomerKey,
    AccountID,
    PersonID,
    Gender,
    Zone,
    Country,
    Region,
    RegisterationDate
FROM T1;
GO

-- Valudate:
SELECT TOP (1000) * FROM [AdventureWorksDW].[dbo].[DimCustomer];