create database HousingData;
use HousingData;
show tables;
select * from property_details;
select * from property_price_details;

FLUSH privileges;
grant all privileges on *.* to root@localhost with grant option;

-- Use the cleaned local database to fetch the following results:

-- 1) Retrieve properties that have a price greater than 1 million and are located in "Estados Unidos" (l1).

select * 
from property_details pd
where l1 = "Estados Unidos" and id in 
(select id 
from property_price_details
where price>1000000);


-- 2) Categorize properties based on their surface area as 'Small' if it's less than 50 square meters, 'Medium' if it's
-- between 50 and 100 square meters, and 'Large' if it's greater than 100 square meters:

select id, 
case when surface_total<50 then 'Small'
when surface_total between 50 and 100 then 'Medium'
else 'Great' end as surface_area_category
from property_details;

-- 3) List all properties (id) in the "Belgrano" neighborhood (l3) that have the same number of bedrooms and
-- bathrooms as another property in the dataset:

select id,bedrooms,bathrooms from property_details
where l3='Belgrano';


Select Distinct pr1.id, pr1.bedrooms, pr1.bathrooms
from property_details pr1
left join property_details pr2
on  pr1.bedrooms = pr2.bedrooms and pr1.bathrooms = pr2.bathrooms
where pr1.l3 = 'Belgrano' and pr1.id <> pr2.id;

-- 4) Calculate the average price per square meter (price / surface_total) for each property type (property_type) in
-- the "Belgrano" neighborhood (l3):
select property_type,round(avg(price/surface_total),2) as Average_price_belgrano
from property_details pd
join property_price_details as ppd
using(id)
where pd.l3 = 'Belgrano' 
group by property_type;

-- 5) Identify properties that have a higher price than the average price of properties with the same number of
-- bedrooms and bathrooms.
select id,price,round(avg(price),2) as average_price
from property_details as pd
join property_price_details ppd
using(id)
where bedrooms=bathrooms
group by id,price
having price>average_price ;

select avg(price) from property_price_details;

-- 6) Calculate the cumulative price for each property type, ordered by the creation date.
select property_type,sum(price) as cumulative_price, max(created_on)
from property_price_details ppd
join property_details pd
using(id)
group by property_type
order by created_on;

-- 7) Identify the 10 locations (l3) with the highest total surface area (sum of surface_total) of properties listed for
-- sale (operation_type = 'Venta'):

select * from (select l3,rank() over(order by total_surface_area) as top
from(
select *,sum(surface_total) as total_surface_area
from property_details pd
join property_price_details ppd
using(id)
where operation_type='Venta'
group by l3) as t1) as t2
where top<=10;
-- can also use dense_rank

-- 8) Find the top 5 most expensive properties (based on price) in the "Palermo" neighborhood (l3) that were listed
-- in August 2020:

select * from(
select id,dense_rank() over(order by price desc) as expense_order,created_on
from property_details as pd
join property_price_details as ppd
using(id)
where l3='Palermo' and month(created_on) = 8 and year(created_on)=2020) as t
where expense_order<=5 ;

-- 9) Find the top 3 properties with the highest price per square meter (price divided by surface area) within each
-- property type.

select * from (
select property_type,id, dense_rank() over(partition by property_type order by (price/surface_total) desc) as top3
from property_details pd
join property_price_details ppd
using(id)) as t
where top3<=3;

-- 10) Find the top 3 locations (l1, l2, l3) with the highest average price per square meter (price / surface_total) for
-- properties listed for sale (operation_type = 'Venta') in the year 2020. Exclude locations with fewer than 10
-- properties listed for sale in 2020 from the results.

select * from(
select *,dense_rank() over(order by average_price desc) as top3 from (
select l1,l2,l3,round(avg(price/surface_total),2) as average_price
from property_details pd
join property_price_details ppd
using(id)
where operation_type='Venta' and year(start_date)=2020 and l3 is not null
group by l1,l2,l3
having count(id)>10) as t1) as t2
where top3<=3;

ALTER USER 'user'@'localhost' identified by 'root';
