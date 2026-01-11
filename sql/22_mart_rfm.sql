BEGIN;
CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.customer_rfm;

CREATE TABLE mart.customer_rfm AS
WITH 
params AS (
    SELECT 
        MAX(purchase_ts)::date AS as_of_date
    FROM mart.order_facts
    WHERE purchase_ts IS NOT NULL
),
base AS (
    SELECT 
        c.customer_unique_id AS customer_id,
        of.order_id,
        of.purchase_ts :: date AS purchase_date,
        of.payment_value_total
    FROM mart.order_facts of 
    JOIN raw.olist_customers c ON of.customer_id = c.customer_id
    WHERE of.purchase_ts IS NOT NULL 
        AND of.customer_id IS NOT NULL
        AND of.order_status = 'delivered'
),
rfm_raw AS (
    SELECT 
        customer_id,
        MAX(purchase_date) AS last_purchase_date,
        COUNT(order_id) AS frequency,
        SUM(payment_value_total) AS monetary_value
    FROM base
    GROUP BY 1
),
rfm AS (
    SELECT 
        r.customer_id,
        p.as_of_date,
        (p.as_of_date - r.last_purchase_date) AS recency_days,
        r.last_purchase_date,
        r.frequency,
        r.monetary_value
    FROM rfm_raw r
    CROSS JOIN params p
),
scored AS (
    SELECT
        r.*,
        (6 - NTILE(5) OVER (ORDER BY r.recency_days ASC)) AS r_score,
        NTILE(5) OVER (ORDER BY r.frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY r.monetary_value ASC) AS m_score
    FROM rfm r
)

SELECT 
    customer_id,
    as_of_date,
    last_purchase_date,
    recency_days,
    frequency,
    monetary_value,
    r_score,
    f_score,
    m_score,
    (r_score::text || f_score::text || m_score::text) AS rfm_score,
    CASE
        WHEN r_score >=4 AND f_score >=4 AND m_score >=4 THEN 'champions'
        WHEN r_score >=4 AND f_score >=3 THEN 'loyal_customers'
        --new customer vs new_high_value 
        WHEN frequency =1 AND r_score >=4 AND m_score >=4 THEN 'new_high_value'
        WHEN frequency =1 AND r_score >=4 THEN 'new_customers'
        --at risk
        WHEN r_score <=2 AND f_score >=4  THEN 'at_risk_loyal'
        WHEN r_score <=2 AND m_score >=4 THEN 'big_spenders_at_risk'
        WHEN r_score =1 THEN 'lost'
        ELSE 'others'
    END AS rfm_segment
FROM scored;

CREATE INDEX IF NOT EXISTS ix_customer_rfm_customer_id ON mart.customer_rfm(customer_id);
CREATE INDEX IF NOT EXISTS ix_customer_rfm_segment ON mart.customer_rfm(rfm_segment);

COMMIT;