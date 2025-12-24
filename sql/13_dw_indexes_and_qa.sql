--Indexs (speed up joins & time filtering)
CREATE INDEX IF NOT EXISTS idx_fact_customer_id ON dw.fact_order_items (customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_seller_id ON dw.fact_order_items (seller_id);
CREATE INDEX IF NOT EXISTS idx_fact_product_id ON dw.fact_order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_fact_purchase_ts ON dw.fact_order_items (purchase_ts);   
CREATE INDEX IF NOT EXISTS idx_fact_order_status ON dw.fact_order_items (order_status);

--QA Queries: date ranges and null rates for key timestamps
SELECT 
    MIN(purchase_ts) AS min_purchase_ts,
    MAX(purchase_ts) AS max_purchase_ts,
    COUNT(*) AS total_records,
    SUM(CASE WHEN purchase_ts IS NULL THEN 1 ELSE 0 END) AS null_purchase_ts,
    SUM(CASE WHEN delivered_customer_ts IS NULL THEN 1 ELSE 0 END) AS delivered_customer_ts_nulls
FROM dw.fact_order_items;

--QA Queries: check that dims are unique by PK (should be always true)
SELECT 
    'dim_customer' AS t,
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS distinct_pk
    FROM dw.dim_customer
UNION ALL
SELECT 
    'dim_sellers',
    COUNT(*) AS total_records,
    COUNT(DISTINCT seller_id) AS distinct_pk
    FROM dw.dim_sellers
UNION ALL
SELECT 
    'dim_products',
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS distinct_pk
    FROM dw.dim_products
UNION ALL
SELECT 
    'dim_date',
    COUNT(*) AS total_records,
    COUNT(DISTINCT date_key) AS distinct_pk
    FROM dw.dim_date;   