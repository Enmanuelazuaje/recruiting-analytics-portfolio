-- =====================================================================
-- 02 · BUSINESS KPIs WITH CTEs (Snowflake port)
-- Dialect changes vs BigQuery:
--   DATE_TRUNC(col, MONTH)      -> DATE_TRUNC('month', col)
--   DATE_DIFF(end, start, DAY)  -> DATEDIFF('day', start, end)  (arg order flips!)
--   SAFE_DIVIDE(a, b)           -> DIV0(a, b)
--   APPROX_QUANTILES(x,100)[90] -> APPROX_PERCENTILE(x, 0.9)
--   IF(cond, a, b)              -> IFF(cond, a, b)
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;

-- Monthly KPIs: openings, fills, fill rate, time-to-fill, new MRR
WITH monthly_openings AS (
  SELECT DATE_TRUNC('month', opened_date) AS month,
         COUNT(*)                         AS vacancies_opened
  FROM vacancies
  GROUP BY 1
),
monthly_fills AS (
  SELECT DATE_TRUNC('month', filled_date)                          AS month,
         COUNT(*)                                                  AS vacancies_filled,
         ROUND(AVG(DATEDIFF('day', opened_date, filled_date)), 1)  AS avg_time_to_fill_days,
         SUM(monthly_fee_usd)                                      AS new_mrr_usd
  FROM vacancies
  WHERE status = 'Filled'
  GROUP BY 1
)
SELECT
  o.month,
  o.vacancies_opened,
  COALESCE(f.vacancies_filled, 0)                          AS vacancies_filled,
  ROUND(DIV0(f.vacancies_filled, o.vacancies_opened) * 100, 1) AS fill_rate_pct,
  f.avg_time_to_fill_days,
  COALESCE(f.new_mrr_usd, 0)                               AS new_mrr_usd
FROM monthly_openings o
LEFT JOIN monthly_fills f USING (month)
ORDER BY o.month;

-- Time-to-fill by department and role
WITH filled AS (
  SELECT department, role_title,
         DATEDIFF('day', opened_date, filled_date) AS days_to_fill,
         monthly_fee_usd
  FROM vacancies
  WHERE status = 'Filled'
)
SELECT
  department,
  role_title,
  COUNT(*)                                AS placements,
  ROUND(AVG(days_to_fill), 1)             AS avg_days_to_fill,
  APPROX_PERCENTILE(days_to_fill, 0.9)    AS p90_days_to_fill,
  ROUND(AVG(monthly_fee_usd), 0)          AS avg_monthly_fee_usd
FROM filled
GROUP BY department, role_title
HAVING COUNT(*) >= 5
ORDER BY avg_days_to_fill DESC;

-- Sourcing channel effectiveness
SELECT
  source_channel,
  COUNT(*)                                            AS total_vacancies,
  COUNT_IF(status = 'Filled')                         AS filled,
  ROUND(COUNT_IF(status = 'Filled') / COUNT(*) * 100, 1) AS fill_rate_pct,
  ROUND(SUM(IFF(status = 'Filled', monthly_fee_usd, 0)), 0) AS revenue_usd
FROM vacancies
GROUP BY source_channel
ORDER BY revenue_usd DESC;
