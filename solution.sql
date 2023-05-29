select * from customers;
select * from products;	
select * from order_items;
select * from orders;

--1. Which product has the highest price? Only return a single row.

with cte as
(
	select *, dense_rank() over(order by price desc) rnk
	from products
)
select product_id, product_name, price
from cte
where rnk = 1

--2. Which customer has made the most orders?

select o.customer_id, c.first_name, c.last_name, count(distinct o.order_id) order_count
from orders o
inner join customers c
on o.customer_id = c.customer_id
group by o.customer_id, c.first_name, c.last_name
order by 4 desc;

--3. What’s the total revenue per product?

with quantity_per_product_cte as
(
select product_id, sum(quantity) total_quantity
from order_items
group by product_id
)
select p.product_id, p.product_name, p.price * q.total_quantity total_revenue
from products p
inner join quantity_per_product_cte q
on p.product_id = q.product_id
order by 3 desc;

--4. Find the day with the highest revenue.

select o.order_date, sum(oi.quantity * p.price) total_revenue, dense_rank() over(order by sum(oi.quantity * p.price) desc) rnk
from orders o
inner join order_items oi
on o.order_id = oi.order_id
inner join products p
on oi.product_id = p.product_id
group by o.order_date;

--5. Find the first order (by date) for each customer.

with first_orders_cte as
(
	select customer_id, min(order_date) first_order_date
	from orders o 
	group by customer_id
)
select f.customer_id, c.first_name, c.last_name, f.first_order_date
from first_orders_cte f
inner join customers c
on f.customer_id = c.customer_id

--6. Find the top 3 customers who have ordered the most distinct products

with cte as
(
	select o.customer_id, count(distinct oi.product_id) cnt_dist_prod
	from orders o
	inner join order_items oi
	on o.order_id = oi.order_id
	group by o.customer_id
)
select top 3 c.customer_id, c.first_name, c.last_name, ct.cnt_dist_prod
from customers c
inner join cte ct
on c.customer_id = ct.customer_id
order by 4 desc;

--7. Which product has been bought the least in terms of quantity?

with cte as
(
	select product_id, sum(quantity) total_quantity, dense_rank() over(order by sum(quantity)) rnk
	from order_items
	group by product_id
)
select c.product_id, p.product_name, c.total_quantity
from cte c
inner join products p
on c.product_id = p.product_id
where c.rnk = 1;

--8. What is the median order total?

with cte as
(
	select oi.order_id, sum(oi.quantity  * p.price) order_price,
	row_number() over(order by sum(oi.quantity  * p.price) desc) rnk_asc,
	row_number() over(order by sum(oi.quantity  * p.price)) rnk_desc
	from order_items oi
	inner join products p
	on oi.product_id = p.product_id
	group by oi.order_id
)
select avg(order_price) median_order_total 
from cte
where abs(rnk_asc - rnk_desc) <= 1;

--9. For each order, determine if it was ‘Expensive’ (total over 300), ‘Affordable’ (total over 100), or ‘Cheap’.

with cte as
(
	select oi.order_id, sum(oi.quantity  * p.price) order_price
	from order_items oi
	inner join products p
	on oi.product_id = p.product_id
	group by oi.order_id
)
select *, case
			when order_price > 300 then 'Expensive'
			when order_price > 100 then 'Affordable'
			else 'Cheap'
		  end order_type
from cte;

--10. Find customers who have ordered the product with the highest price.

with costliest_product_cte as 
(
	select product_id
	from products
	where price = (select max(price) from products)
),
cte as
(
	select o.customer_id, oi.product_id
	from orders o 
	inner join order_items oi 
	on o.order_id = oi.order_id
)
select c.customer_id, c.first_name, c.last_name, ct.product_id
from cte ct
inner join customers c
on ct.customer_id = c.customer_id
where ct.product_id in (select product_id from costliest_product_cte);


