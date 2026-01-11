-- Purpose: latest score joined back to enriched orer view for BI

CREATE OR REPLACE VIEW mart.v_sla_order_scored AS
WITH latest AS (
    SELECT DISTINCT ON (order_id)
        order_id,
        score_date,
        risk_score,
        risk_flag,
        model_version
    FROM mart.sla_risk_scoring
    ORDER BY order_id, score_date DESC
)
SELECT
    e.*,
    l.score_date,
    l.risk_score,
    l.risk_flag,
    l.model_version
FROM mart.v_sla_order_enriched e
LEFT JOIN latest l ON e.order_id=l.order_id;