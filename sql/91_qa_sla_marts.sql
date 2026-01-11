select
  percentile_cont(0.50) within group (order by days_late) as p50,
  percentile_cont(0.90) within group (order by days_late) as p90,
  percentile_cont(0.99) within group (order by days_late) as p99,
  max(days_late) as max_days_late
from mart.sla_orders
where is_late and days_late is not null;

select
  count(*) filter (where days_late > 90) as late_gt_90,
  count(*) filter (where days_late > 120) as late_gt_120,
  count(*) as total_late
from mart.sla_orders
where is_late and days_late is not null;

select
  delivered_date,
  count(*) as delivered_cnt,
  sum(is_late::int) as late_cnt,
  sum(is_late::int)::numeric / nullif(count(*),0) as late_rate
from mart.sla_orders
where is_delivered
group by delivered_date
order by delivered_date desc
limit 10;

