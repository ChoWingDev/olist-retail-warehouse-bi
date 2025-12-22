TRUNCATE raw.olist_customers, 
         raw.olist_geolocation,
         raw.olist_orders,
         raw.olist_order_items,
         raw.olist_order_payments,
         raw.olist_order_reviews,
         raw.olist_products,
         raw.olist_sellers,
         raw.product_category_name_translation;

COPY raw.olist_customers
FROM '/data_raw/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_geolocation
FROM '/data_raw/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_orders
FROM '/data_raw/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_order_items
FROM '/data_raw/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_order_payments
FROM '/data_raw/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_order_reviews
FROM '/data_raw/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_products
FROM '/data_raw/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.olist_sellers
FROM '/data_raw/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true, QUOTE '"', ESCAPE '"');

COPY raw.product_category_name_translation
FROM '/data_raw/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true);