-- Purpose: WBR weekly metrics based on delivered week

DROP TABLE IF EXISTS mart.sla_wbr_weekly;

CREATE TABLE mart.sla_wbr_weekly AS
SELECT
  delivered_week_start AS week_start,
  COUNT(*) FILTER (WHERE is_delivered) AS delivered_cnt,
  COUNT(*) FILTER (WHERE is_delivered AND is_late) AS late_cnt,
  ROUND(
    COUNT(*) FILTER (WHERE is_delivered AND is_late)::numeric
    / NULLIF(COUNT(*) FILTER (WHERE is_delivered), 0)
  , 6) AS late_rate,

  -- on-time rate among delivered
  ROUND(
    COUNT(*) FILTER (WHERE is_delivered AND NOT is_late)::numeric
    / NULLIF(COUNT(*) FILTER (WHERE is_delivered), 0)
  , 6) AS ontime_rate,

  -- risk shares among scored orders (delivered or all? we keep all scored)
  COUNT(*) FILTER (WHERE risk_flag IS NOT NULL) AS scored_cnt,
  COUNT(*) FILTER (WHERE risk_flag = 'amber') AS amber_cnt,
  COUNT(*) FILTER (WHERE risk_flag = 'red') AS red_cnt,
  ROUND(
    COUNT(*) FILTER (WHERE risk_flag IN ('amber','red'))::numeric
    / NULLIF(COUNT(*) FILTER (WHERE risk_flag IS NOT NULL), 0)
  , 6) AS high_risk_share
FROM mart.v_sla_order_scored
WHERE delivered_week_start IS NOT NULL
GROUP BY delivered_week_start
ORDER BY delivered_week_start;

CREATE INDEX IF NOT EXISTS ix_sla_wbr_weekly_week_start
  ON mart.sla_wbr_weekly (week_start);
