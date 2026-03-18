use AdventureWorksDW;

with RecencyScoring as(
	select f1.ProductKey as BaseProduct, 
	f2.ProductKey as RecommendedProduct,
	sum(case when DATEDIFF(MONTH, d.FullDate,GETDATE()) <= 12 then 1
	when DATEDIFF(MONTH, d.FullDate,GETDATE()) <= 18 then 0.6
	when DATEDIFF(MONTH, d.FullDate,GETDATE()) <= 24 then 0.3
	else 0.1 end) as RecencyScore
	from FactOrders as f1 join DimDate d
	on f1.DateKey = d.DateKey join FactOrders f2
	on f1.SalesOrderID = f2.SalesOrderID
	and f1.ProductKey <> f2.ProductKey
	group by f1.ProductKey, f2.ProductKey
),
SameCategory as (
	select p1.ProductKey as BaseProduct,
	p2.ProductKey as RecommendedProduct,
	case when p1.CategoryKey = p2.CategoryKey then 10
	else 0 end as CategoryScore
	from DimProduct p1 join DimProduct as p2
	on p1.ProductKey <> p2.ProductKey
)
select r.BaseProduct , r.RecommendedProduct,
r.RecencyScore, c.CategoryScore 
from RecencyScoring r join SameCategory c
on r.BaseProduct = c.BaseProduct
and r.RecommendedProduct = c.RecommendedProduct