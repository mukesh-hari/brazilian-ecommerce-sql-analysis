-- ============================================
-- Brazilian E-commerce SQL Analysis Project
-- ============================================

-- create database
CREATE DATABASE brazilian_ecommerce;
USE brazilian_ecommerce;

-- ============================================
-- TABLE CREATION & DATA LOADING
-- ============================================

-- Customers Table: Stores customer demographic details
CREATE TABLE customers (
    customer_id VARCHAR(50) primary key,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

-- load data into customer table
load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_customers_dataset.csv"
into table customers
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Products Table: Contains product details and categories
create table products (product_id varchar(100), product_category_name varchar(100),
product_name_lenght varchar(10), product_description_lenght varchar(10), product_photos_qty	varchar(20),produdct_weight_g varchar(20), product_length_cm varchar(10),	product_height_cm varchar(10), product_width_cm varchar(10),PRIMARY KEY (product_id));
-- load data into products table
load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_products_dataset.csv"
into table products
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Orders Table: Contains order-level information
create table orders (order_id varchar(50), customer_id varchar(50), order_status char(20), order_purchase_timestamp datetime,
order_approved_at datetime, order_delivered_carrier_date datetime, order_delivered_customer_date datetime, order_estimated_delivery_date datetime,
PRIMARY KEY (order_id),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id));
-- load data into orders table with null handling 
load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_orders_dataset.csv"
into table orders
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows
(order_id, customer_id, order_status, @v_purchase, @v_approved, @v_carrier, @v_customer, @v_estimated)
set
order_purchase_timestamp = nullif(@v_purchase, ''),
order_approved_at = nullif(@v_approved, ''),
order_delivered_carrier_date = nullif(@v_carrier, ''),
order_delivered_customer_date = nullif(@v_customer, ''),
order_estimated_delivery_date = nullif(@v_estimated, '');

-- Order Items Table: Product-level details for each order
create table order_items(order_id varchar(100), order_item_id int, product_id varchar(225), seller_id varchar(100),
shipping_limit_date datetime, price decimal(10,5), freight_value decimal (10,5),
primary key(order_id, order_item_id), foreign key  (order_id) REFERENCES orders(order_id),
FOREIGN KEY (product_id) REFERENCES products(product_id));

-- load data into order_items table
load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_order_items_dataset.csv"
into table order_items
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;
-- Order Payments Table: Contains payment information for each order
CREATE TABLE order_payments(
    order_id VARCHAR(100), 
    payment_sequential INT, 
    payment_type CHAR(50), 
    payment_installments INT, 
    payment_value DECIMAL(10,2),FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
-- load data into order_payments table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_order_payments_dataset.csv' 
INTO TABLE order_payments 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

-- ============================================
-- ANALYSIS QUERIES
-- ============================================


-- 1. Analyze number of orders by order status
select order_status, count(order_id) as total_orders from orders
group by order_status
order by total_orders desc;

-- 2. Calculate total revenue by payment type
select payment_type, round(sum(payment_value),2) as total_revenue from order_payments
group by payment_type
order by total_revenue desc;

-- 3. Find top 5 cities with highest number of orders
select c.customer_city, count(o.order_id) as total_orders from customers c
join orders o on o.customer_id = c.customer_id
group by c.customer_city
order by total_orders desc
limit 5;

-- 4. Analyze price distribution (max, min, average)
select 
round(max(Price)) as highest,
round(min(price)) as lowest,
round(avg(price)) as average
from order_items;

-- 5. Monthly order distribution
select monthname(order_purchase_timestamp) as order_month, count(order_id) as total_orders from orders
group by order_month
order by total_orders;

-- 6. Calculate total revenue
select round(sum(payment_value),2) as total_revenue from order_payments;

-- 7. Identify top 10 customers based on spending
select o.customer_id, round(sum(p.payment_value),2) as payment_spent from orders o
join order_payments p on o.order_id = p.order_id
group by o.customer_id
order by payment_spent desc
limit 10;  

-- 8. Find top 10 best-selling products
select product_id, count(order_id) as total_sold from order_items
group by product_id
order by total_sold desc
limit 10;

-- 9. Monthly revenue analysis
select monthname(o.order_purchase_timestamp) as month, round(sum(p.payment_value),2) as total_revenue from orders o
join order_payments p on o.order_id = p.order_id
group by month
order by total_revenue
limit 10;

-- 10. Top cities by revenue
select c.customer_city, round(sum(p.payment_value),2) as total_revenue from customers c
join orders o on c.customer_id = o.customer_id
join order_payments p on o.order_id = p.order_id
group by c.customer_city
order by total_revenue desc
limit 10;

-- 11. Top 10 highest value orders
SELECT 
    o.order_id,
    ROUND(SUM(p.payment_value),2) AS order_value
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY o.order_id
ORDER BY order_value DESC
LIMIT 10;

-- 12. Average order value
select round((sum(payment_value))/ count(distinct order_id),2) as avearage_ordervalue from order_payments;
