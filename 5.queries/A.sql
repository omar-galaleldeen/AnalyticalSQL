--A. Time-Based Performance Analysis
use AdventureWorksDW
select * from FactOrders

--1. Produce cumulative revenue over time to understand long-term growth behavior.
select d.fulldate,sum(netamount) daily_revenue ,sum(sum(netamount)) over(order by d.fulldate) as comulative_daily_revenue
from factorders f
inner join dimdate d
on f.datekey = d.datekey
group by d.fulldate


--2. Measure Month-to-Date performance to evaluate intra-month trends.
select year(d.FullDate) as year, month(d.fulldate) as month, d.FullDate , sum(f.profitamount) monthly_revenue, 
sum(sum(Profitamount)) over(partition by year(d.fulldate), month(d.fulldate) order by d.fulldate rows between unbounded preceding and current row) as month_to_date_profit
from FactOrders f
join DimDate d
on f.DateKey = d.DateKey
group by year(d.FullDate), month(d.fulldate), d.FullDate
order by year(d.FullDate), month(d.fulldate), d.FullDate


--3. Measure Year-to-Date profit to assess annual performance progression.
select year(d.FullDate) as year, month(d.fulldate) as month, d.FullDate , sum(f.profitamount) monthly_revenue, 
sum(sum(Profitamount)) over(partition by year(d.fulldate) order by d.fulldate rows between unbounded preceding and current row) as year_to_date_profit
from FactOrders f
join DimDate d
on f.DateKey = d.DateKey
group by year(d.FullDate), month(d.fulldate), d.FullDate
order by year(d.FullDate), month(d.fulldate), d.FullDate

--4. Smooth short-term volatility using moving average trend analysis.
select year(d.FullDate) as year, month(d.fulldate) as month, d.FullDate , sum(f.profitamount) monthly_revenue, 
avg(sum(profitamount)) over(order by d.fulldate rows between 2 preceding and current row) as moving_average_profit
from FactOrders f
join DimDate d
on f.DateKey = d.DateKey
group by year(d.FullDate), month(d.fulldate), d.FullDate
order by year(d.FullDate), month(d.fulldate), d.FullDate


--5. Compare current month performance with previous month to detect growth or decline.
with comparison as (
select d.fulldate, sum(NetAmount) as current_month_revenue, 
lag(sum(netamount),1,0) over(order by year(d.fulldate), month(d.fulldate)) as previous_month_revenue
from FactOrders f
join DimDate d
on f.DateKey = d.DateKey
group by d.fulldate
)

select c.*, case when current_month_revenue > previous_month_revenue then 'Growth' 
when current_month_revenue < previous_month_revenue then 'Decline' 
else 'No Change' end as performance_trend
from comparison c


--6. Identify acceleration or deceleration in revenue dynamics.

with daily_revenue as (
select d.fulldate, sum(netamount) as daily_revenue
from FactOrders f
join DimDate d
on f.DateKey = d.DateKey
group by d.fulldate
),

revenue_change as (
select fulldate, daily_revenue, daily_revenue - lag(daily_revenue,1,0) over(order by fulldate) as revenue_change
from daily_revenue
),

revenue_acceleration as (
select fulldate, daily_revenue, revenue_change, revenue_change - lag(revenue_change,1,0) over(order by fulldate) as revenue_acceleration
from revenue_change d
)

select *, case when revenue_acceleration > 0 then 'Acceleration' 
when revenue_acceleration < 0 then 'Deceleration' 
else 'No Change' end as acceleration_trend
from revenue_acceleration
