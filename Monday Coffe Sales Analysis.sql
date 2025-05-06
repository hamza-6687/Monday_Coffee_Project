

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

select * from city
select * from customers
select * from products
select * from sales


-- Reports & Data Analysis

-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select
	Round(population*0.25/1000000,2) as coffee_consumers_in_millions,
city_name,
city_rank
from city
order by population desc

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select
	ci.city_name,
	sum(total) as total_revenue
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ci
on ci.city_id=c.city_id
where DATEPART(year,sale_date)=2023
and
DATEPART(QUARTER,sale_date)=4
group by ci.city_name
order by total_revenue desc



-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?		

select 
	p.product_name,
	count(p.product_id) as total_coffe_sold
from products as p 
join sales as s
on p.product_id=s.product_id
group by p.product_name
order by total_coffe_sold desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
	count(distinct s.customer_id) as total_cx,
	 Round(
	 cast(SUM(s.total)as decimal (10,2))/
	 cast(count(distinct s.customer_id)as decimal (10,2)),2) as avg_sale_per_cx
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;


-- -- Q5
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from city
select * from customers
select * from sales
select * from products


select  * 
from (
	select 
		p.product_name, 
		ci.city_name,
		count(s.sale_id) as total_orders,
		DENSE_RANK()over(Partition By ci.city_name order by count(s.sale_id) desc  ) as rank
	from sales as s
	join products as p
	on s.product_id=p.product_id
	join customers as c
	on c.customer_id=s.customer_id
	join city as ci
	on ci.city_id=c.city_id
	group by p.product_name,ci.city_name 
	) as t1
	where rank<=3




-- Q.6
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?


select * from city
select * from customers
select * from sales
select * from products

select
	ci.city_name,
	count(distinct c.customer_id) as total_customers
from city as ci
join customers as c
on ci.city_id = c.city_id
join sales as s
on s.customer_id=c.customer_id
group by ci.city_name


SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
 JOIN customers AS c
    ON c.city_id = ci.city_id
 JOIN sales AS s
    ON s.customer_id = c.customer_id 
    AND s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY ci.city_name;


-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer


with city_table
as
(
	select
		ci.city_name,
		sum(s.total) as total_revenue,
		count(distinct c.customer_id) as total_cx,
		sum(s.total)/count(distinct c.customer_id) average_sale_per_cx
	from 
	city as ci
	join customers as c
	on c.city_id=ci.city_id
	join sales as s
	on s.customer_id=c.customer_id
	group by ci.city_name
),
city_rent
as 
(select 
	city_name,
	estimated_rent 
from city
)

select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.average_sale_per_cx,
	cr.estimated_rent/ct.total_cx as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on  cr.city_name=ct.city_name


-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthly_sales
AS
(
	select 
		ci.city_name,
		MONTH(s.sale_date) as Sale_Month,
		YEAR(s.sale_date) as Year,
		sum(s.total) as total_sale
	from sales as s
	join customers as c
	on c.customer_id=s.customer_id
	join city as ci
	on ci.city_id=c.city_id
	group by ci.city_name,	MONTH(s.sale_date),YEAR(s.sale_date)
	),
growth_ratio
AS
(
	select  
		city_name,
		Sale_Month,
		Year,
		total_sale as current_month_sale,
		LAG(total_sale,1) over(partition by city_name order by Year, Sale_Month ) as Last_month_sale
	from monthly_sales
)

select 
	city_name,
	Sale_Month,
	Year,
	current_month_sale	,
	Last_month_sale,
	ROUND((current_month_sale-Last_month_sale)/Last_month_sale*100 ,2)as growth_ratio
from growth_ratio
order by city_name,Year,Sale_Month


-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


with city_table
as
(
	select
		ci.city_name,
		sum(s.total) as total_revenue,
		count(distinct c.customer_id) as total_cx,
		sum(s.total)/count(distinct c.customer_id) average_sale_per_cx
	from 
	city as ci
	join customers as c
	on c.city_id=ci.city_id
	join sales as s
	on s.customer_id=c.customer_id
	group by ci.city_name
),
city_rent
as 
(select 
	city_name,
	estimated_rent 
from city
)

select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.average_sale_per_cx,
	cr.estimated_rent/ct.total_cx as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on  cr.city_name=ct.city_name


-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with city_table
as
(
	select
		ci.city_name,
		sum(s.total) as total_revenue,
		count(distinct c.customer_id) as total_cx,
		sum(s.total)/count(distinct c.customer_id) average_sale_per_cx
	from 
	city as ci
	join customers as c
	on c.city_id=ci.city_id
	join sales as s
	on s.customer_id=c.customer_id
	group by ci.city_name
),
city_rent
as 
(select 
	city_name,
	estimated_rent ,
	ROUND((population*0.25)/1000000,2) as estimated_coffee_consumers_in_millions
from city
)

select 
	cr.city_name,
	total_revenue,
	cr.estimated_rent,
	ct.total_cx,
	estimated_coffee_consumers_in_millions,
	ct.average_sale_per_cx,
	cr.estimated_rent/ct.total_cx as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on  cr.city_name=ct.city_name
order by total_revenue desc


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.




