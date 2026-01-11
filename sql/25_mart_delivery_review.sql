--Grain : 1 row per order_id

DROP TABLE IF EXISTS mart.delivery_review;

CREATE TABLE mart.delivery_review AS
WITH order_agg AS (
    SELECT
        order_id,
        MIN(purchase_ts) AS purchase_ts,
        MAX(delivered_customer_ts) AS delivered_customer_ts,
        MAX(estimated_delivery_date) AS estimated_delivery_date,

        COUNT(*) AS items_count,
        SUM(price) AS price,
        SUM(freight_value) AS freight_value
    FROM dw.fact_order_items
    GROUP BY order_id
),
review_one AS (
    SELECT
        order_id,
        MAX(review_score) AS review_score
    FROM raw.olist_order_reviews
    GROUP BY order_id
)
SELECT
    a.order_id,
    r.review_score,
    (r.review_score <=2) AS is_low_review,
    CASE
        WHEN a.delivered_customer_ts IS NULL OR a.estimated_delivery_date IS NULL THEN NULL
        ELSE GREATEST((a.delivered_customer_ts::date - a.estimated_delivery_date),0)
    END AS delivery_delay_days,

    a.price,
    a.freight_value,
    a.items_count,

    EXTRACT(MONTH FROM a.purchase_ts)::int AS month
FROM order_agg a
JOIN review_one r