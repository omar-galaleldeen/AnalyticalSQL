## The complete column mapping:


### 📋 Dimension Keys — Renamed Columns Reference

| Your DW Column | Original Column | Source Table |
|---|---|---|
| `CustomerKey` | `CustomerID` | `Sales.Customer` |
| `AccountID` | `AccountNumber` | `Sales.Customer` |
| `PersonID` | `PersonID` | `Sales.Customer` |
| `Zone` | `Name` | `Sales.SalesTerritory` |
| `Country` | `CountryRegionCode` | `Sales.SalesTerritory` |
| `Region` | `[Group]` | `Sales.SalesTerritory` |
| `RegistrationDate` | `ModifiedDate` | `Sales.Customer` |
| `ProductKey` | `ProductID` | `Production.Product` |
| `ProductID` | `ProductNumber` | `Production.Product` |
| `ParentProductName` | `Name` | `Production.ProductModel` |
| `Brand` | `MakeFlag` (derived) | `Production.Product` |
| `CategoryKey` | `ProductSubcategoryID` | `Production.Product` |
| `Cost` | `StandardCost` | `Production.Product` |
| `LaunchDate` | `SellStartDate` | `Production.Product` |
| `EndDate` | `SellEndDate` | `Production.Product` |
| `SafeStockQuantity` | `SafetyStockLevel` | `Production.Product` |
| `StockQuantity` | `SUM(Quantity)` | `Production.ProductInventory` |
| `CategoryName` | `Name` | `Production.ProductSubcategory` |
| `ParentCategory` | `Name` | `Production.ProductCategory` |
| `ShipMethodID` | `ShipMethodID` | `Purchasing.ShipMethod` |
| `PaymentMethodKey` | derived (CreditCardID NULL check) | `Sales.SalesOrderHeader` |
| `DateKey` | `YYYYMMDD` from `OrderDate` | `Sales.SalesOrderHeader` |

---

### 📋 Fact Table Source Columns

| Fact Measure | Original Column | Source Table | Notes |
|---|---|---|---|
| `SalesOrderID` | `SalesOrderID` | `Sales.SalesOrderHeader` | Order identifier |
| `SalesOrderDetailID` | `SalesOrderDetailID` | `Sales.SalesOrderDetail` | Line grain key |
| `OrderDate` | `OrderDate` | `Sales.SalesOrderHeader` | → DateKey |
| `CustomerKey` | `CustomerID` | `Sales.SalesOrderHeader` | FK |
| `ProductKey` | `ProductID` | `Sales.SalesOrderDetail` | FK |
| `ShipMethodKey` | `ShipMethodID` | `Sales.SalesOrderHeader` | FK |
| `PaymentMethodKey` | `CreditCardID` (NULL check) | `Sales.SalesOrderHeader` | FK simulated |
| `Quantity` | `OrderQty` | `Sales.SalesOrderDetail` | Measure |
| `UnitPrice` | `UnitPrice` | `Sales.SalesOrderDetail` | Measure |
| `DiscountAmount` | `UnitPriceDiscount * UnitPrice * OrderQty` | `Sales.SalesOrderDetail` | Derived |
| `GrossAmount` | `UnitPrice * OrderQty` | `Sales.SalesOrderDetail` | Derived |
| `NetAmount` | `LineTotal` | `Sales.SalesOrderDetail` | Already calculated |
| `CostAmount` | `StandardCost * OrderQty` | `Production.Product` | Need JOIN |
| `ProfitAmount` | `NetAmount - CostAmount` | Derived | Derived |

---

### Fact Table DDL

```sql
CREATE TABLE [AdventureWorksDW].[dbo].[FactOrders] (
    -- Surrogate Key
    FactKey             INT             IDENTITY(1,1)   PRIMARY KEY,
    -- Degenerate Dimension
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
    GrossAmount         MONEY           NOT NULL,
    DiscountAmount      MONEY           NOT NULL,
    NetAmount           MONEY           NOT NULL,
    CostAmount          MONEY           NOT NULL,
    ProfitAmount        MONEY           NOT NULL
);
GO
```

---

### Fact Table Ingestion Query

```sql
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
```

---
## Full Schema
---

### 📊 Star Schema — AdventureWorksDW

**Fact Table: `FactOrders`**
| Column | Type | Note |
|---|---|---|
| `FactKey` | INT IDENTITY | Surrogate PK |
| `SalesOrderID` | INT | Degenerate dimension |
| `DateKey` | INT | FK → DimDate |
| `CustomerKey` | INT | FK → DimCustomer |
| `ProductKey` | INT | FK → DimProduct |
| `CategoryKey` | INT | FK → DimCategory |
| `PaymentMethodKey` | TINYINT | FK → DimPaymentMethod |
| `ShipMethodKey` | INT | FK → DimShipMethod |
| `Quantity` | SMALLINT | Measure |
| `UnitPrice` | MONEY | Measure |
| `GrossAmount` | MONEY | UnitPrice × Quantity |
| `DiscountAmount` | MONEY | Discount applied |
| `NetAmount` | MONEY | After discount |
| `CostAmount` | MONEY | StandardCost × Quantity |
| `ProfitAmount` | MONEY | NetAmount - CostAmount |

---

**Dimensions:**

| Table | PK | Key Columns |
|---|---|---|
| `DimDate` | `DateKey` | FullDate, Day, Month, MonthName, Quarter, Year, WeekNumOfYear |
| `DimCustomer` | `CustomerKey` | AccountID, PersonID, Gender, Zone, Country, Region, RegistrationDate |
| `DimProduct` | `ProductKey` | ProductID, ProductName, ParentProductName, Brand, CategoryKey, Cost, LaunchDate, EndDate, SafeStockQuantity, StockQuantity, StockStatus |
| `DimCategory` | `CategoryKey` | CategoryName, ParentCategory, ModifiedDate |
| `DimPaymentMethod` | `PaymentMethodKey` | PaymentMethodName, IsActive |
| `DimShipMethod` | `ShipMethodKey` | Name, DeliveryDays, BasePrice, ShipRate |

---

**Key relationships:**
- `DimProduct` → `DimCategory` via `CategoryKey` ✅
- `FactOrders` → all 6 dimensions via FK constraints ✅
- `DimShipMethod.ShipMethodKey` is `IDENTITY(1,1)` — values 1–5 ✅
- `DimPaymentMethod.PaymentMethodKey` is `TINYINT` — values 1–4 ✅
- Gender is simulated on `DimCustomer` as `NCHAR(1)` — `M` or `F` ✅
- `StockStatus` has CHECK constraint: `In-Stock`, `Critical`, `Out-of-Stock` ✅

