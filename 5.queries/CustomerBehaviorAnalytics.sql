use AdventureWorksDW

-- 12. Evaluate cumulative spending behavior per customer over time.
with DailySales as (
	select CustomerKey, DateKey, sum(NetAmount) as DailyAmount
	from FactOrders group by CustomerKey, DateKey
)
select CustomerKey, Datekey,
sum(DailyAmount)over(partition by CustomerKey order by Datekey) as Total_Spending
from DailySales

-- 13. Measure time intervals between consecutive purchases for each customer. 
with PurchaseDate as (
	select CustomerKey, FullDate
	from FactOrders f join DimDate d
	on f.DateKey = d.DateKey
	group by CustomerKey, FullDate
)
select CustomerKey, FullDate,
ISNULL( datediff(DAY,
				Lag(FullDate,1) over(partition by CustomerKey order by FullDate),
				FullDate)
		,'-') as Interval
from PurchaseDate

-- 14. Rank customers based on recency of activity. 
with LastPurchase as (
	select CustomerKey, max(FullDate) as LastPurchaseDate
	from FactOrders f join DimDate d
	on f.DateKey = d.DateKey
	group by CustomerKey
)
select CustomerKey, LastPurchaseDate, 
case when DATEDIFF(MONTH, LastPurchaseDate,GETDATE()) <= 12 then 1
	when DATEDIFF(MONTH, LastPurchaseDate,GETDATE()) <= 18 then 2
	when DATEDIFF(MONTH, LastPurchaseDate,GETDATE()) <= 24 then 3
	else 4 end as RecencyRank
from LastPurchase

-- 15. Segment customers into spending tiers (e.g., quartiles).
with TotalSpending as(
	select CustomerKey, sum(NetAmount) as TotalSpent
	from FactOrders group by CustomerKey
)
select CustomerKey, TotalSpent,
	NTILE(4) over(order by TotalSpent ASC) as SpendingQuartile
from TotalSpending
order by TotalSpent 

-- 16. Identify the top percentile of high-value customers. 
with TotalSpending as(
	select CustomerKey, sum(NetAmount) as TotalSpent
	from FactOrders group by CustomerKey
),
CustomerRanking as(
	select CustomerKey, TotalSpent,
	PERCENT_RANK() over(order by TotalSpent) as CustomerRank
	from TotalSpending
)
select * from CustomerRanking
where CustomerRank > 0.95