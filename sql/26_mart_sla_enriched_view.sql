--Purpose : One enriched order-lever view for dashabord + risk scoring

CREATE OR REPLACE VIEW mart.v_sla_order_enriched AS
WITH base AS (
    SELECT
        s.order_id,
        s.customer_id,
        s.order_status,

        s.purchase_ts,
        s.approved_ts,
        s.delivered_carrier_ts,
        s.delivered_customer_ts,
        s.estimated_delivery_date,

        s.purchase_date,
        s.delivered_date,

        s.is_delivered,
        s.is_late,

        s.delivery_days,
        s.approval_days,
        s.ship_days,

        --day_late: keep as int (can be null)
        s.days_late::int AS days_late,

        --delivery delay days: clamp to >=0 for bucket usage
        CASE
            WHEN s.days_late IS NULL THEN NULL
            ELSE GREATEST(s.days_late::int, 0)
        END AS delay_days,
        --cap at 30 for stability ( same logic with R script)
        CASE 
            WHEN s.days_late IS NULL THEN NULL
            ELSE LEAST(GREATEST(s.days_late::int, 0), 30)
        END AS delay_cap,

        --WBR week fields (delivered week is the main one)
        date_trunc('week', s.delivered_date)::date AS delivered_week_start,
        date_trunc('week', s.purchase_date)::date AS purchase_week_start,
        date_trunc('month', s.delivered_date)::date AS delivered_month_start

        FROM mart.sla_orders s
),
bucket AS (
    SELECT
        b.*,
        CASE
            WHEN b.delay_cap IS NULL THEN NULL
            WHEN b.delay_cap = 0 THEN '0'
            WHEN b.delay_cap BETWEEN 1 AND 3 THEN '1-3'
            WHEN b.delay_cap BETWEEN 4 AND 7 THEN '4-7'
            WHEN b.delay_cap BETWEEN 8 AND 14 THEN '8-14'
            ELSE '15-30'
    END AS delay_bucket,
        CASE 
            WHEN b.is_delivered IS TRUE THEN NOT b.is_late
            ELSE NULL
        END AS is_ontime
    FROM base b
)

SELECT 
    x.*,

    --bring in modeling features + review label
    dr.review_score,
    dr.is_low_review,
    dr.delivery_delay_days,
    dr.price,
    dr.freight_value,
    dr.items_count,
    dr.month
FROM bucket x
LEFT JOIN mart.delivery_review dr
    ON x.order_id = dr.order_id;
