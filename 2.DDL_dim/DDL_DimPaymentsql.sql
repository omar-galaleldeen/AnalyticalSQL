-- Dim_Payment (payment_key, payment_method)

-- viewing the orders table we see that it either has a credit card number or not:
SELECT  * FROM [AdventureWorks].[Sales].[SalesOrderHeader]

-- exploring the data
SELECT 
    paymethod, COUNT(*) AS count
FROM (
    SELECT  CASE  WHEN CreditCardID IS NULL THEN 'cash' 
                  ELSE 'credit' END AS paymethod
    FROM [AdventureWorks].[Sales].[SalesOrderHeader]) AS t
GROUP BY paymethod;


-- Credit card types:
SELECT Distinct CardType FROM AdventureWorks.Sales.CreditCard;
--> result: SuperiorCard, Vista, Distinguish, ColonialVoice

-- Creating the paymethod DDL
CREATE TABLE AdventureWorksDW.dbo.DimPaymentMethod (
    PaymentMethodKey tinyint PRIMARY KEY,
    PaymentMethodName VARCHAR(50) NOT NULL, 
    --PaymentCategory VARCHAR(20) NOT NULL, -- could be added as a junk dimension (i.e. the specific card type: VISA, MASTERCARd, or AMEX)
    IsActive BIT NOT NULL DEFAULT 1
);
GO

-- Insert common payment methods
INSERT INTO dbo.DimPaymentMethod (PaymentMethodKEy, PaymentMethodName, IsActive)
VALUES
    (1, 'Credit Card',1), 
    (2, 'Cash',1), 
    (3, 'Digital',1),
    (4, 'Gift Card',1)
GO

--Validate
Select * 
from AdventureWorksDW.dbo.DimPaymentMethod