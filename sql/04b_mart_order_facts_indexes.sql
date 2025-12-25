-- Indexes for mart.order_facts
-- Purpose: speed up joins, filters, and time-series queries in BI dashboards

CREATE UNIQUE INDEX IF NOT EXISTS ix_order_facts_order_id
  ON mart.order_facts(order_id);

CREATE INDEX IF NOT EXISTS ix_order_facts_customer_id
  ON mart.order_facts(customer_id);

CREATE INDEX IF NOT EXISTS ix_order_facts_purchase_ts
  ON mart.order_facts(purchase_ts);

CREATE INDEX IF NOT EXISTS ix_order_facts_status
  ON mart.order_facts(order_status);

CREATE INDEX IF NOT EXISTS ix_order_facts_payment_type
  ON mart.order_facts(primary_payment_type);

-- Optional: if you often filter late deliveries
-- CREATE INDEX IF NOT EXISTS ix_order_facts_is_late
--   ON mart.order_facts(is_late);

ANALYZE mart.order_facts;
