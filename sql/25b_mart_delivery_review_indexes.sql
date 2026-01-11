CREATE UNIQUE INDEX IF NOT EXISTS ux_delivery_review_order_id
    ON mart.delivery_review (order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_review_delay_days
    ON mart.delivery_review (delivery_delay_days);

ANALYZE mart.delivery_review;