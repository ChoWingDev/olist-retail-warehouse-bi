--dim_customer
INSERT INTO dw.dim_customer (
  customer_id, customer_unique_id, customer_city, customer_state, customer_zip_code_prefix
)
SELECT DISTINCT 
  customer_id,
  customer_unique_id,
  customer_city,
  customer_state,
  customer_zip_code_prefix
FROM raw.olist_customers
WHERE customer_id IS NOT NULL
ON CONFLICT (customer_id) DO NOTHING;

--dim_sellers
INSERT INTO dw.dim_sellers (
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.olist_sellers
WHERE seller_id IS NOT NULL
ON CONFLICT (seller_id) DO NOTHING;

--dim_products
INSERT INTO dw.dim_products (
    product_id,
    product_category_name,
    product_category_name_english,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT DISTINCT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM raw.olist_products p
LEFT JOIN raw.product_category_name_translation t
ON p.product_category_name = t.product_category_name
WHERE p.product_id IS NOT NULL
ON CONFLICT (product_id) DO NOTHING;

--dim_date
INSERT INTO dw.dim_date (
  date_key, year, month, day, day_of_week
)
SELECT 
    d::date AS date_key,
    EXTRACT(YEAR FROM d) :: INTEGER AS year,
    EXTRACT(MONTH FROM d) :: INTEGER AS month,
    EXTRACT(DAY FROM d) :: INTEGER AS day,
    EXTRACT(DOW FROM d) :: INTEGER AS day_of_week
FROM(
    SELECT DISTINCT (NULLIF(order_purchase_timestamp :: text, '')::TIMESTAMP) :: date AS d
    FROM raw.olist_orders
    UNION
    SELECT DISTINCT (NULLIF(order_approved_at :: text, '')::TIMESTAMP) :: date
    FROM raw.olist_orders
    UNION
    SELECT DISTINCT (NULLIF(order_delivered_carrier_date :: text, '')::TIMESTAMP) :: date
    FROM raw.olist_orders
    UNION
    SELECT DISTINCT (NULLIF(order_delivered_customer_date :: text, '')::TIMESTAMP) :: date
    FROM raw.olist_orders
    UNION
    SELECT DISTINCT (NULLIF(order_estimated_delivery_date :: text, '')::TIMESTAMP) :: date
    FROM raw.olist_orders
) x
WHERE d IS NOT NULL
ON CONFLICT (date_key) DO NOTHING;