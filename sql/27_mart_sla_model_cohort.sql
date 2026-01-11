-- Purchase: Match R "delivery_review_clean_df"

CREATE OR REPLACE VIEW mart.v_sla_model_cohort AS
SELECT
    order_id,

    --Target (match R: 0/1)
    CASE WHEN is_low_review IS TRUE THEN 1 ELSE 0 END AS is_low_review,

    --Delay features (match R)
    delivery_delay_days,
    LEAST(delivery_delay_days, 30):: int AS delay_cap,

    CASE
        WHEN LEAST(delivery_delay_days, 30) = 0 THEN '0'
        WHEN LEAST(delivery_delay_days, 30) BETWEEN 1 AND 3 THEN '1-3'
        WHEN LEAST(delivery_delay_days, 30) BETWEEN 4 AND 7 THEN '4-7'
        WHEN LEAST(delivery_delay_days, 30) BETWEEN 8 AND 14 THEN '8-14'
        ELSE '15-30'
    END AS delay_bucket,
    
    --Monetary + counts
    price,
    freight_value,
    items_count,

    --seasonality (R: factor, BI: categrorical)
    month,

    --log transforms (match R log1p)
    LN(1 + price) AS log_price,
    LN(1 + freight_value) AS log_freight_value

FROM mart.v_sla_order_enriched
WHERE is_delivered 
    AND is_low_review IS NOT NULL
    AND delivery_delay_days IS NOT NULL
    AND price IS NOT NULL
    AND freight_value IS NOT NULL
    AND items_count IS NOT NULL
    AND month IS NOT NULL;

