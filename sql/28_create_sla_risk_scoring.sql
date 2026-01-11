-- Purpose: store daily risk scores (one row per order_id per score_date)

CREATE TABLE IF NOT EXISTS mart.sla_risk_scoring (
    order_id text NOT NULL,
    score_date DATE NOT NULL,
    risk_score numeric(10, 6) NOT NULL, -- predicted probability
    risk_flag text NOT NULL, -- green/amber/red
    threshold_green numeric(10, 6) NOT NULL DEFAULT 0.20,
    threshold_red numeric(10, 6) NOT NULL DEFAULT 0.35,
    model_version text NOT NULL DEFAULT 'late_review_logit_v1',
    created_at timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (order_id, score_date)
);

CREATE INDEX IF NOT EXISTS ix_sla_risk_scoring_order_id ON mart.sla_risk_scoring (risk_flag);
CREATE INDEX IF NOT EXISTS ix_sla_risk_scoring_flag ON mart.sla_risk_scoring (risk_flag);
CREATE INDEX IF NOT EXISTS ix_sla_risk_scoring_score_date ON mart.sla_risk_scoring (score_date);
