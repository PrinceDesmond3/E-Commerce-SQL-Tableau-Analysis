
/*
Calculating Total unique customers and customers growth by year
*/

-------------- Total Unique Customers------------
SELECT
	COUNT(DISTINCT customer_unique_id) total_customers
	FROM olist_customers_dataset c
	inner join olist_orders_dataset o
	on c.customer_id = o.customer_id
	WHERE delivery_status = 'Delivered';

-------------- Total unique Customers growth Percentage------------
WITH customer_year as
(
SELECT YEAR(order_purchase_timestamp) AS order_year,
	COUNT(DISTINCT customer_unique_id) total_customers
	FROM olist_customers_dataset c
	inner join olist_orders_dataset o
	on c.customer_id = o.customer_id
	WHERE delivery_status = 'Delivered' 
	group by YEAR(order_purchase_timestamp)
)
SELECT curr.order_year,
	curr.Total_customers,
	LAG(curr.Total_customers) OVER(ORDER BY curr.order_year) previous_year,
	ROUND(
        (CAST(curr.total_customers AS FLOAT) - LAG(curr.total_customers) OVER (ORDER BY curr.order_year))
        / NULLIF(LAG(curr.total_customers) OVER (ORDER BY curr.order_year), 0)
        * 100, 2
    ) AS growth_percentage
FROM customer_year curr;


 
-------------- Retention Rate------------

WITH cte_total_purchase as 
(
SELECT  ROUND(SUM(price + freight_value), 2) AS total_revenue,
	customer_unique_id,
	COUNT(DISTINCT o.order_id) total_order
	FROM olist_customers_dataset c
	INNER JOIN olist_orders_dataset o
	ON c.customer_id = o.customer_id
	INNER JOIN olist_order_items_dataset oi
	ON o.order_id = oi.order_id
WHERE delivery_status = 'Delivered' 
GROUP BY c.customer_unique_id
)
SELECT 
	(CASE WHEN total_order = 1 THEN 'One-Time Buyer' ELSE 'Recurring customer' END) Customer_category,
	COUNT(Distinct c.customer_unique_id)total_number,
	ROUND(100.0 * COUNT(Distinct c.customer_unique_id)/ SUM(COUNT(Distinct c.customer_unique_id)) OVER(), 1)
	AS retention_rate,
	ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM cte_total_purchase ctp
JOIN olist_customers_dataset c
JOIN olist_orders_dataset o
JOIN olist_order_items_dataset oi
ON o.order_id = oi.order_id
ON c.customer_id = o.customer_id
ON ctp.customer_unique_id = c.customer_unique_id
group by (CASE WHEN total_order = 1 THEN 'One-Time Buyer' ELSE 'Recurring customer' END
);

 ------------------Total Revenue-----------------------

SELECT 
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- ------------------Total Revenue percentage growth----
 
WITH revenue_year as 
(
SELECT YEAR(order_purchase_timestamp) AS order_year,
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
Group by YEAR(order_purchase_timestamp)
)
SELECT ry.order_year,
	ry.total_revenue,
	LAG(ry.total_revenue) OVER(ORDER BY ry.order_year) previous_year,
	ROUND(
        (CAST(ry.total_revenue AS FLOAT) - LAG(ry.total_revenue) OVER (ORDER BY ry.order_year))
        / NULLIF(LAG(ry.total_revenue) OVER (ORDER BY ry.order_year), 0) * 100, 2
    ) AS growth_percentage
FROM revenue_year ry;

--------------------- Average Order Value--------------------------

SELECT 
    ROUND(SUM(price) / COUNT(DISTINCT i.order_id), 2) AS avg_order_value
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered';


--------------------- Average Order Value percentage Growth--------------------------

WITH aov_growth as
(
SELECT YEAR(order_purchase_timestamp) AS order_year,
    ROUND(SUM(price) / COUNT(DISTINCT i.order_id), 2) AS avg_order_value
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
Group by YEAR (order_purchase_timestamp)
)
SELECT aov.order_year,
	aov.avg_order_value,
	LAG(aov.avg_order_value) OVER(ORDER BY aov.order_year) previous_avg,
	ROUND(
        (CAST(aov.avg_order_value AS FLOAT) - LAG(aov.avg_order_value) OVER (ORDER BY aov.order_year))
        / NULLIF(LAG(aov.avg_order_value) OVER (ORDER BY aov.order_year), 0) * 100, 2
    ) AS growth_percentage
FROM
aov_growth aov;


----------------- Average Delivery Time-------------------------

SELECT Avg(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)
	AS decimal(10,2))) avg_delivery_time
FROM olist_orders_dataset
WHERE delivery_status = 'delivered' 
AND order_delivered_customer_date Is NOT NULL;


----------------- Average Delivery Time perc_growth-------------------------

WITH avg_delivery_growth as
(
SELECT YEAR(order_purchase_timestamp) AS order_year,
	Avg(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) 
	AS decimal(10,2))) avg_delivery_time
FROM olist_orders_dataset
WHERE delivery_status = 'delivered' 
AND order_delivered_customer_date Is NOT NULL
Group by YEAR (order_purchase_timestamp)
)

SELECT adg.order_year,
	adg.avg_delivery_time,
	LAG(adg.avg_delivery_time) OVER(ORDER BY adg.order_year) previous_avg,
	ROUND(
        (CAST(LAG(adg.avg_delivery_time) OVER (ORDER BY adg.order_year) - adg.avg_delivery_time AS FLOAT)  )
        / NULLIF(LAG(adg.avg_delivery_time) OVER (ORDER BY adg.order_year), 0) * 100, 2
    ) AS growth_percentage
FROM
avg_delivery_growth adg;


----------------- Average Review Score-------------------------

SELECT AVG(CAST(review_score AS DECIMAL(10,2))) avg_rev_score
FROM olist_order_reviews_dataset r
inner join olist_orders_dataset o
on r.order_id = o.order_id
WHERE delivery_status = 'Delivered'




----------------- Average Review Score Percentage Growth-------------------------

WITH avg_sc_rev_perc AS
(
SELECT YEAR(order_purchase_timestamp) AS order_year,
	AVG(CAST(review_score AS DECIMAL(10,2))) avg_rev_score
FROM olist_order_reviews_dataset r
inner join olist_orders_dataset o
ON r.order_id = o.order_id
WHERE delivery_status = 'Delivered'
Group by YEAR (order_purchase_timestamp)
)
SELECT asr.order_year,
	asr.avg_rev_score,
	LAG(asr.avg_rev_score) OVER(ORDER BY asr.order_year) previous_avg,
	ROUND(
        (CAST(asr.avg_rev_score AS FLOAT) - LAG(asr.avg_rev_score) OVER (ORDER BY asr.order_year))
        / NULLIF(LAG(asr.avg_rev_score) OVER (ORDER BY asr.order_year), 0) * 100, 2
    ) AS growth_percentage
FROM
avg_sc_rev_perc asr;

----------------- Top Rated Sellers -------------------------


WITH seller_performance AS (
    SELECT 
        i.seller_id,
        COUNT(DISTINCT i.order_id) AS total_orders,
        ROUND(AVG(r.review_score), 2) AS avg_review_score
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
        ON i.order_id = o.order_id
    JOIN olist_order_reviews_dataset r
        ON i.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY i.seller_id
),
total_orders_cte AS (
    SELECT COUNT(DISTINCT order_id) AS total_orders_all
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
)
SELECT 
    s.seller_id,
    s.total_orders,
    s.avg_review_score,
    ROUND((CAST(s.total_orders AS FLOAT) / t.total_orders_all) * 100, 2) AS order_share_percentage
FROM seller_performance s
CROSS JOIN total_orders_cte t
WHERE avg_review_score >= 4


----------------- Top States by orders, revenue etc -------------------------

WITH state_summary AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(price + freight_value) AS total_revenue,
        ROUND(SUM(price + freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    total_orders,
    total_revenue,
    avg_order_value,
    ROUND((CAST(total_revenue AS FLOAT) / SUM(total_revenue) OVER()) * 100, 2) AS revenue_percentage,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM state_summary
;

----------Monthly Sales trend--------------

SELECT 
    FORMAT(o.order_purchase_timestamp, 'yyyy-MMM') AS month,
    ROUND(SUM(price + freight_value), 2) AS monthly_sales
FROM olist_order_items_dataset i
JOIN olist_orders_dataset o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MMM')
ORDER BY month;


---------DELIVERY DELAY RATE-----------------------

SELECT 
    COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) * 100.0 / COUNT(*) AS delay_rate
FROM olist_orders_dataset
WHERE order_status = 'delivered';

---------Top products by sales-----------------------

SELECT 
    p.product_category_name,
    ROUND(SUM(i.price + i.freight_value), 2) AS total_sales
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN olist_orders_dataset o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_sales DESC;

---------Top products by profit-----------------------

SELECT 
    p.product_category_name,
    ROUND(SUM(i.price - i.freight_value), 2) AS profit
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN olist_orders_dataset o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY profit DESC;
