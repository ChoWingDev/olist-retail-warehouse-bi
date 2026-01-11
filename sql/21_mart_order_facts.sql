DROP TABLE IF EXISTS mart.order_facts;
CREATE TABLE mart.order_facts AS 
WITH
--order-level timestamps/status
orders as (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp AS purchase_ts,
        o.order_approved_at AS approved_ts,
        o.order_delivered_carrier_date AS delivered_carrier_ts,
        o.order_delivered_customer_date AS delivered_customer_ts,
        o.order_estimated_delivery_date ::DATE AS estimated_delivery_date
    FROM raw.olist_orders o
),
-- product-level metrics aggregated to order
items AS (
    SELECT i.order_id,
        COUNT(*) AS items_cnt,
        SUM(i.price) AS items_revenue,
        SUM(i.freight_value) AS freight_total,
        SUM(i.price + i.freight_value) AS gmv
    FROM raw.olist_order_items i
    GROUP BY i.order_id
),

--payment-level metrics aggregated to order
payments AS(
    SELECT
        p.order_id,
        SUM(p.payment_value) AS payment_value_total,
        MAX(p.payment_installments) AS max_installments,
        MAX(CASE WHEN p.payment_sequential = 1 THEN p.payment_type END) AS primary_payment_type
    FROM raw.olist_order_payments p
    GROUP BY p.order_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.purchase_ts,
    o.approved_ts,
    o.delivered_carrier_ts,
    o.delivered_customer_ts,
    o.estimated_delivery_date,

    --delivery metrics
    CASE WHEN o.delivered_customer_ts IS NULL OR o.purchase_ts IS NULL THEN NULL
    ELSE EXTRACT(EPOCH FROM (o.delivered_customer_ts - o.purchase_ts)) / 86400.0 END AS delivery_days,
    CASE WHEN o.delivered_customer_ts IS NULL OR o.estimated_delivery_date IS NULL THEN NULL
         WHEN o.delivered_customer_ts :: DATE > o.estimated_delivery_date THEN TRUE ELSE FALSE END AS is_late,

-- items metrics
    COALESCE(i.items_cnt, 0) AS items_cnt,
    COALESCE(i.items_revenue, 0) AS items_revenue,
    COALESCE(i.freight_total, 0) AS freight_total,
    COALESCE(i.gmv, 0) AS gmv,

--payments metrics
    COALESCE(p.payment_value_total, 0) AS payment_value_total,
    COALESCE(p.max_installments, 0) AS max_installments,
    p.primary_payment_type

FROM orders o
LEFT JOIN items i ON o.order_id = i.order_id
LEFT JOIN payments p ON o.order_id = p.order_id;