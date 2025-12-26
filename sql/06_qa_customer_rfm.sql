-- 06_qa_customer_rfm.sql

-- A. Rowcount
SELECT COUNT(*) AS n_rows FROM mart.customer_rfm;

-- B. Key integrity
SELECT COUNT(*) AS null_customer_id
FROM mart.customer_rfm
WHERE customer_id IS NULL;

-- C. Recency should be non-negative
SELECT COUNT(*) AS negative_recency
FROM mart.customer_rfm
WHERE recency_days < 0;

-- D. Frequency/Monetary sanity
SELECT
  MIN(frequency) AS min_freq,
  MAX(frequency) AS max_freq,
  MIN(monetary_value) AS min_m,
  MAX(monetary_value) AS max_m
FROM mart.customer_rfm;

-- E. Segment distribution
SELECT rfm_segment, COUNT(*) AS n
FROM mart.customer_rfm
GROUP BY 1
ORDER BY 2 DESC;

-- F. Spot checks
SELECT * FROM mart.customer_rfm ORDER BY monetary_value DESC LIMIT 10;
SELECT * FROM mart.customer_rfm ORDER BY frequency DESC LIMIT 10;
