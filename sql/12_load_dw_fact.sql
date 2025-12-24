TRUNCATE dw.fact_order_items;

INSERT INTO dw.fact_order_items (
  order_id,
  order_item_id,
  customer_id,
  seller_id,
  product_id,
  order_status,
  purchase_ts,
  approved_ts,
  delivered_carrier_ts,
  delivered_customer_ts,
  estimated_delivery_date,
  shipping_limit_ts,
  price,
  freight_value
)
SELECT
  i.order_id,
  i.order_item_id,
  o.customer_id,
  i.seller_id,
  i.product_id,
  o.order_status,
  NULLIF(o.order_purchase_timestamp :: text, '')::TIMESTAMP AS purchase_ts,
  NULLIF(o.order_approved_at :: text, '')::TIMESTAMP AS approved_ts,
  NULLIF(o.order_delivered_carrier_date :: text, '')::TIMESTAMP AS delivered_carrier_ts,
  NULLIF(o.order_delivered_customer_date :: text, '')::TIMESTAMP AS delivered_customer_ts,
  NULLIF(o.order_estimated_delivery_date :: text, '')::TIMESTAMP :: date AS estimated_delivery_date,
  NULLIF(i.shipping_limit_date :: text, '')::TIMESTAMP AS shipping_limit_ts,
  i.price,
  i.freight_value
FROM raw.olist_order_items i
JOIN raw.olist_orders o
ON i.order_id = o.order_id;