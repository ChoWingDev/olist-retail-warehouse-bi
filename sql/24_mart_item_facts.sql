-- Grain: 1 row per (order_id, order_item_id)
-- Source: dw.fact_order_items

DROP TABLE IF EXISTS mart.item_facts;

CREATE TABLE mart.item_facts AS
SELECT
  f.order_id,
  f.order_item_id,

  f.customer_id,
  f.seller_id,
  f.product_id,

  f.order_status,

  f.purchase_ts,
  f.approved_ts,
  f.delivered_carrier_ts,
  f.delivered_customer_ts,
  f.estimated_delivery_date,
  f.shipping_limit_ts,

  f.price,
  f.freight_value,
  (f.price + f.freight_value) AS item_total,

  (f.purchase_ts::date) AS purchase_date,
  (f.delivered_customer_ts::date) AS delivered_date,

  (f.delivered_customer_ts IS NOT NULL) AS is_delivered,

  CASE
    WHEN f.delivered_customer_ts IS NULL OR f.estimated_delivery_date IS NULL THEN NULL
    WHEN f.delivered_customer_ts::date > f.estimated_delivery_date THEN TRUE
    ELSE FALSE
  END AS is_late,

  CASE
    WHEN f.purchase_ts IS NULL OR f.delivered_customer_ts IS NULL THEN NULL
    ELSE (f.delivered_customer_ts::date - f.purchase_ts::date)
  END AS delivery_days

FROM dw.fact_order_items f;
