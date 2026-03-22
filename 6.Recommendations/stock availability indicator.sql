--Stock Availability of the product
with stock_availability as (
select 
	productkey,
	productname,
	stockquantity,
	case 
		when stockquantity >= 50 then 1.0   -- fully stocked scoring
		when stockquantity >= 10 then 0.5   -- moderate stock
		when stockquantity >  0  then 0.3   -- low stock
		else 0.0                            -- out of stock
	end as availability_status
from dimproduct
)

select * from stock_availability