-- 6. Dim shipping

-- Exploring the Data
SELECT  * FROM AdventureWorks.Purchasing.ShipMethod; 
-- has the method and base order price and shipping price, we need to calclate the delivery days or assume it


-- Exploring the sales order header
SELECT TOP (1000) * FROM [AdventureWorks].[Sales].[SalesOrderHeader];
-- Note: 'Status' is a degenerate dimension
/*
Status Value	Description
1	In process
2	Approved
3	Back ordered
4	Rejected
5	Shipped
6	Canceled
*/


-- Calculating Avg days for each shipping method
WITH t1 as(
SELECT
    SalesOrderID,
    OrderDate,
    DueDate,
    ShipDate,
    shipmethodid,
    status,
    -- Calculate days between shipping and the due date for delivered orders
    DATEDIFF(day, ShipDate, DueDate) AS earlyDelivery,
    DATEDIFF(day, OrderDate, ShipDate)  as daysofdelivery
    
FROM adventureworks.Sales.SalesOrderHeader
WHERE ShipDate IS NOT NULL  -- Exclude orders that haven't been shipped
    AND Status = 5          -- Status 5 typically means shipped and delivered
)

select shipmethodid, avg(daysofdelivery)
from t1
group by shipmethodid

-- Results:
-- Method | number of days to delivery
-- 1      |  7
-- 5      |  7



-- Viewing the Shipping methods:
SELECT  * FROM AdventureWorks.Purchasing.ShipMethod; 


SELECT * FROM [AdventureWorksDW].[dbo].[DimShipMethod]

--DDL: DimShipMethod:
USE [AdventureWorksDW]
GO
CREATE TABLE [dbo].[DimShipMethod](
	[ShipMethodKey] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
    [DeliveryDays] smallint NOT NULL,
	[BasePrice] [money] NOT NULL,
	[ShipRate] [money] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ShipMethod_ShipMethodID] PRIMARY KEY CLUSTERED 
    (
	[ShipMethodKey] ASC
    )
)
GO

-- Insertion:
INSERT INTO [AdventureWorksDW].[dbo].[DimShipMethod] (
    [Name],
    [DeliveryDays],
    [BasePrice],
    [ShipRate],
    [ModifiedDate]
)
VALUES
    ('XRQ - TRUCK GROUND', 7, 3.95, 0.99, '2019-04-30 00:00:00.000'),
    ('ZY - EXPRESS', 3, 9.95, 1.99, '2019-04-30 00:00:00.000'),
    ('OVERSEAS - DELUXE', 7, 29.95, 2.99, '2019-04-30 00:00:00.000'),
    ('OVERNIGHT J-FAST', 1, 21.95, 1.29, '2019-04-30 00:00:00.000'),
    ('CARGO TRANSPORT 5', 7, 8.99, 1.49, '2019-04-30 00:00:00.000');

-- Verify the results
SELECT * FROM [AdventureWorksDW].[dbo].[DimShipMethod] ORDER BY [ShipMethodKey];



-- Populate:
/*
-- Insert using subquery -> limited editing
INSERT INTO [AdventureWorksDW].[dbo].[DimShipMethod] (
    [Name],
    [DeliveryDays],
    [BasePrice],
    [ShipRate],
    [ModifiedDate]
)
SELECT 
    Name, 7, ShipBase, ShipRate, modifiedDate
FROM [AdventureWorks].[Purchasing].[ShipMethod] 
ORDER BY ShipMethodID;
*/




