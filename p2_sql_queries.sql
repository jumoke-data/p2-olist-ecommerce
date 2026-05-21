-- olist_orders
CREATE TABLE olist_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

SELECT *
FROM olist_orders;

-- olist_order_items
CREATE TABLE olist_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

SELECT *
FROM olist_order_items;

-- olist_order_payments
CREATE TABLE olist_order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2)
);

SELECT *
FROM olist_order_payments;


-- olist_order_reviews
CREATE TABLE olist_order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

SELECT *
FROM olist_order_reviews;


-- olist_customers
CREATE TABLE olist_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

SELECT *
FROM olist_customers;


-- olist_sellers
CREATE TABLE olist_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

SELECT *
FROM olist_sellers;

-- olist_products
CREATE TABLE olist_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g NUMERIC(10,2),
    product_length_cm NUMERIC(10,2),
    product_height_cm NUMERIC(10,2),
    product_width_cm NUMERIC(10,2)
);

SELECT *
FROM olist_products;

-- product_category_name_translation
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

SELECT *
FROM product_category_name_translation;


--KPIs
-- KPI 1: Total Revenue
SELECT 
    SUM(p.payment_value) AS total_revenue
FROM olist_orders AS o
JOIN olist_order_payments AS p 
ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';



-- KPI 2: Total Orders
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_order_payments AS p 
ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


-- KPI 3: Total Sellers
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM olist_sellers ;


-- KPI 4: Average Review Score
SELECT ROUND (AVG(review_score), 2) AS average_review_score
FROM olist_order_reviews ;


-- KPI 5: Average Delivery Time.
SELECT ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400), 2)
AS avg_delivery_days
FROM olist_orders
WHERE order_status = 'delivered';


--BUSINESS QUESTIONS
--1. Orders and Revenue by State
SELECT 
    q.customer_state,
    SUM(p.payment_value) AS total_revenue, 
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_order_payments AS p ON o.order_id = p.order_id
JOIN olist_customers AS q ON o.customer_id = q.customer_id
WHERE o.order_status = 'delivered'
GROUP BY q.customer_state
ORDER BY total_revenue DESC;


--2. Revenue by Product Category
SELECT  s.product_category_name_english,
    SUM(i.price) AS total_revenue, 
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_products AS r
JOIN olist_order_items AS i ON r.product_id = i.product_id
JOIN product_category_name_translation AS s ON r.product_category_name = s.product_category_name
JOIN olist_orders AS o ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.product_category_name_english
ORDER BY total_revenue DESC;


--3. Best Sellers
SELECT i.seller_id,
    SUM(i.price) AS total_revenue, 
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_order_items AS i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY i.seller_id
ORDER BY total_revenue DESC;


--4. Worst Sellers
SELECT i.seller_id,
    SUM(i.price) AS total_revenue, 
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_order_items AS i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY i.seller_id
ORDER BY total_revenue ASC;


--5. Delivery Performance — Actual vs Estimated delivery time.
SELECT CASE 
    WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
    ELSE 'On Time'
END AS delivery_status, 
COUNT(DISTINCT order_id) AS total_orders
FROM olist_orders
WHERE order_status = 'delivered'
GROUP BY (CASE 
    WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
    ELSE 'On Time'
END);


--6.Average Review Score by Category
SELECT ROUND (AVG(review_score), 2) AS average_review_score,
    n.product_category_name_english,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_order_reviews AS r ON o.order_id = r.order_id
JOIN olist_order_items AS i ON o.order_id = i.order_id
JOIN olist_products AS p ON i.product_id = p.product_id
JOIN product_category_name_translation AS n 
     ON p.product_category_name = n.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY n.product_category_name_english
ORDER BY average_review_score DESC;




