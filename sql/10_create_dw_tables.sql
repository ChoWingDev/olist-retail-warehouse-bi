--dimension tables
CREATE TABLE IF NOT EXISTS dw.dim_customer(
    customer_id           TEXT PRIMARY KEY,
    customer_unique_id    TEXT,
    customer_city         TEXT,
    customer_state        TEXT,
    customer_zip_code_prefix TEXT
);

CREATE TABLE IF NOT EXISTS dw.dim_sellers (
  seller_id              TEXT PRIMARY KEY,
  seller_zip_code_prefix TEXT,
  seller_city            TEXT,
  seller_state           TEXT
);

CREATE TABLE IF NOT EXISTS dw.dim_products (
  product_id                 TEXT PRIMARY KEY,
  product_category_name      TEXT,
  product_category_name_english TEXT,
  product_weight_g           INTEGER,
  product_length_cm          INTEGER,
  product_height_cm          INTEGER,
  product_width_cm           INTEGER
);

CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_key DATE PRIMARY KEY,
    year    INTEGER,
    month  INTEGER,
    day   INTEGER,
    day_of_week INTEGER
);

--Fact Table
CREATE TABLE IF NOT EXISTS dw.fact_order_items (
  order_id            TEXT NOT NULL,
  order_item_id       INTEGER NOT NULL,

  customer_id         TEXT,
  seller_id           TEXT,
  product_id          TEXT,

  order_status        TEXT,
  purchase_ts        TIMESTAMP,
  approved_ts       TIMESTAMP,
  delivered_carrier_ts TIMESTAMP,
  delivered_customer_ts TIMESTAMP,
  estimated_delivery_date DATE,

  shipping_limit_ts TIMESTAMP,

  price               NUMERIC(12,2),
  freight_value       NUMERIC(12,2),

  PRIMARY KEY (order_id, order_item_id)
);
