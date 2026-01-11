-- sql/12_build_sla_marts.sql
-- Purpose: SLA marts (order-level + purchase-date daily + delivered-date daily)

\set ON_ERROR_STOP on

BEGIN;

-- 1) Order-level SLA (1 row per order)
DROP TABLE IF EXISTS mart.sla_orders;

CREATE TABLE mart.sla_orders AS
SELECT
  of.order_id,
  of.customer_id,
  of.order_status,

  -- timestamps/dates
  of.purchase_ts,
  of.approved_ts,
  of.delivered_carrier_ts,
  of.delivered_customer_ts,
  of.estimated_delivery_date,

  -- convenience dates for grouping
  of.purchase_ts::date AS purchase_date,
  of.delivered_customer_ts::date AS delivered_date,

  -- flags
  (of.delivered_customer_ts IS NOT NULL) AS is_delivered,
  (
    of.delivered_customer_ts IS NOT NULL
    AND of.estimated_delivery_date IS NOT NULL
    AND of.delivered_customer_ts::date > of.estimated_delivery_date
  ) AS is_late,

  -- lead times (days)
  CASE
    WHEN of.delivered_customer_ts IS NULL OR of.purchase_ts IS NULL THEN NULL
    ELSE (of.delivered_customer_ts::date - of.purchase_ts::date)
  END AS delivery_days,

  CASE
    WHEN of.approved_ts IS NULL OR of.purchase_ts IS NULL THEN NULL
    ELSE (of.approved_ts::date - of.purchase_ts::date)
  END AS approval_days,

  CASE
    WHEN of.delivered_carrier_ts IS NULL OR of.approved_ts IS NULL THEN NULL
    ELSE (of.delivered_carrier_ts::date - of.approved_ts::date)
  END AS ship_days,

  CASE
    WHEN of.delivered_customer_ts IS NULL OR of.estimated_delivery_date IS NULL THEN NULL
    ELSE (of.delivered_customer_ts::date - of.estimated_delivery_date)
  END AS days_late

FROM mart.order_facts of;

-- indexes
CREATE INDEX IF NOT EXISTS ix_sla_orders_purchase_date ON mart.sla_orders (purchase_date);
CREATE INDEX IF NOT EXISTS ix_sla_orders_delivered_date ON mart.sla_orders (delivered_date);
CREATE INDEX IF NOT EXISTS ix_sla_orders_customer_id  ON mart.sla_orders (customer_id);
CREATE INDEX IF NOT EXISTS ix_sla_orders_is_late      ON mart.sla_orders (is_late);

-- 2) Purchase-date daily SLA aggregate (1 row per purchase day)
DROP TABLE IF EXISTS mart.sla_daily;

CREATE TABLE mart.sla_daily AS
SELECT
  purchase_date,
  COUNT(*) AS orders_cnt,
  SUM(is_delivered::int) AS delivered_cnt,
  SUM(is_late::int) AS late_cnt,

  -- backlog: purchased but not yet delivered (or never delivered)
  (COUNT(*) - SUM(is_delivered::int)) AS backlog_cnt,

  AVG(CASE WHEN is_delivered THEN delivery_days END) AS avg_delivery_days,
  AVG(CASE WHEN is_late THEN days_late END) AS avg_days_late,

  CASE
    WHEN SUM(is_delivered::int) = 0 THEN NULL
    ELSE SUM(is_late::int)::numeric / SUM(is_delivered::int)
  END AS late_rate
FROM mart.sla_orders
GROUP BY purchase_date;

CREATE INDEX IF NOT EXISTS ix_sla_daily_purchase_date ON mart.sla_daily (purchase_date);

-- 3) Delivered-date daily SLA aggregate (1 row per delivered day) + p90 metrics
DROP TABLE IF EXISTS mart.sla_delivered_daily;

CREATE TABLE mart.sla_delivered_daily AS
WITH base AS (
  SELECT *
  FROM mart.sla_orders
  WHERE is_delivered
),
agg AS (
  SELECT
    delivered_date,
    COUNT(*) AS delivered_cnt,
    SUM(is_late::int) AS late_cnt,
    AVG(delivery_days) AS avg_delivery_days,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY delivery_days) AS p90_delivery_days,
    AVG(CASE WHEN is_late THEN days_late END) AS avg_days_late
  FROM base
  GROUP BY delivered_date
),
p90_late AS (
  SELECT
    delivered_date,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY days_late) AS p90_days_late
  FROM base
  WHERE is_late AND days_late IS NOT NULL
  GROUP BY delivered_date
)
SELECT
  a.delivered_date,
  a.delivered_cnt,
  a.late_cnt,
  (a.late_cnt::numeric / NULLIF(a.delivered_cnt, 0)) AS late_rate,
  a.avg_delivery_days,
  a.p90_delivery_days,
  a.avg_days_late,
  p.p90_days_late
FROM agg a
LEFT JOIN p90_late p USING (delivered_date);

CREATE INDEX IF NOT EXISTS ix_sla_delivered_daily_delivered_date
  ON mart.sla_delivered_daily (delivered_date);

COMMIT;
