-- created by Farida
use AdventureWorks2022
SELECT
    CONVERT(INT, FORMAT(soh.OrderDate,'yyyyMMdd'))      AS date_key,
    soh.CustomerID                                       AS customer_key,
    sod.ProductID                                        AS product_key,
    pc.ProductCategoryID                                 AS category_key,
    soh.ShipMethodID                                     AS shipping_key,
    sod.OrderQty                                         AS quantity,
    sod.OrderQty * sod.UnitPrice                         AS gross_amount,
    sod.OrderQty * sod.UnitPrice * sod.UnitPriceDiscount AS discount_amount,
    sod.LineTotal                                        AS net_amount,
    sod.OrderQty * p.StandardCost                        AS cost_amount,
    sod.LineTotal - (sod.OrderQty * p.StandardCost)      AS profit_amount

FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
    ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID;





    USE AdventureWorks
    GO
    SELECT
        date
        customer_key
        product_key
        category_key
        payment_key
        shipping_key
        quantity
        gross_amount
        discount_amount
        net_amount
        cost_amount
        profit_amount
    FROM AdventureWorks.Sales.SalesOrderHeader;
    JOIN    ON
    JOIN    ON
    JOIN    ON
    JOIN    ON
