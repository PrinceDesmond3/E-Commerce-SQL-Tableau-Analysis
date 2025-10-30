/* 
Here I updated the olist_orders_dataset table where order_approved_at was missing but  
delivery dates existed, I inferred approval time as 5 minutes after purchase timestamp
*/

UPDATE olist_orders_dataset
SET 
order_approved_at = DATEADD(MINUTE, 5, order_purchase_timestamp)
WHERE 
order_approved_at IS NULL
AND 
(order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL);


/*
Here I added a column named 'deliver_status' to olist_orders_dataset table to show orders 
with approved date but missing order_delivered_customer_dates and it was tagged as ‘Shipped 
not delivered’ to preserve timeline accuracy while improving interpretability
*/

ALTER TABLE olist_orders_dataset
ADD delivery_status VARCHAR(50);
UPDATE olist_orders_dataset
SET delivery_status = 
    CASE 
        WHEN order_delivered_customer_date IS NULL 
             AND order_delivered_carrier_date IS NOT NULL THEN 'Shipped not delivered'
        WHEN order_delivered_customer_date IS NOT NULL THEN 'Delivered'
        ELSE 'Pending'
    END;


/*
Here I updated datetimes like switching columns so that the datetimes will be in this 
format : purchase < approval < shipped < delivered ≤ estimated delivery date
*/

UPDATE olist_orders_dataset
SET
order_approved_at = order_delivered_carrier_date,
order_delivered_carrier_date = order_approved_at
WHERE order_approved_at > order_delivered_carrier_date;


UPDATE olist_orders_dataset
SET
order_delivered_carrier_date = order_delivered_customer_date,
order_delivered_customer_date = order_delivered_carrier_date
WHERE order_delivered_carrier_date > order_delivered_customer_date;



/* --------------------------------------Standardization----------------------
Here I changed the first letters of customer_city in olist_customers_dataset table
from small letters to big letters
*/
UPDATE olist_customers_dataset
SET customer_city = CONCAT(
    UPPER(LEFT(customer_city, 1)),
    LOWER(SUBSTRING(customer_city, 2, LEN(customer_city))));

/* 
Here I changed the first letters of Seller_city in olist_sellers_dataset table
from small letters to big letters
*/

	UPDATE olist_sellers_dataset
SET seller_city = CONCAT(
    UPPER(LEFT(seller_city, 1)),
    LOWER(SUBSTRING(seller_city, 2, LEN(seller_city))));

/* 
Here I changed the first letters of product_category in olist_products_dataset table
from small letters to big letters
*/

UPDATE olist_products_dataset
SET product_category_name = CONCAT(
    UPPER(LEFT(product_category_name, 1)),
    LOWER(SUBSTRING(product_category_name, 2, LEN(product_category_name))));

	
/* 
Here I changed the first letters of product_category in product_category_name table
from small letters to big letters
*/
UPDATE product_category_name_translation
SET column1 = CONCAT(
    UPPER(LEFT(column1, 1)),
    LOWER(SUBSTRING(column1, 2, LEN(column1))));



-- Here I added a column to flag order_id that are unavailable as invalid while the rest are valid 

ALTER TABLE olist_orders_dataset
ADD order_validity VARCHAR(20);
	
UPDATE olist_orders_dataset
SET order_validity = 
    CASE 
        WHEN order_status IN ('unavailable', 'canceled', 'created') THEN 'Invalid'
        ELSE 'Valid'
    END; 



