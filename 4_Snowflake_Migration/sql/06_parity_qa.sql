-- =====================================================================
-- 06 · CROSS-PLATFORM PARITY QA: BigQuery -> Snowflake
-- The baseline values below were computed on the source (BigQuery-side)
-- dataset. After migrating, this script recomputes every metric in
-- Snowflake and reports PASS/FAIL per check. This is the same
-- methodology used to certify that migrated dashboards match legacy
-- ones: never eyeball it — assert it.
-- (Baseline generated automatically from the source data.)
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;

-- 1 · Load the expected values captured on the source platform
CREATE OR REPLACE TABLE parity_baseline (
  check_name   STRING,
  dim_value    STRING,
  metric_name  STRING,
  expected_value NUMBER(18,2)
);

INSERT INTO parity_baseline VALUES
  ('row_count', 'vacancies', 'rows', 900),
  ('row_count', 'marketing_leads', 'rows', 905),
  ('row_count', 'recruiters', 'rows', 12),
  ('monthly_mrr', '2025-10', 'new_mrr_usd', 9580.0),
  ('monthly_mrr', '2025-11', 'new_mrr_usd', 65850.0),
  ('monthly_mrr', '2025-12', 'new_mrr_usd', 106800.0),
  ('monthly_mrr', '2026-01', 'new_mrr_usd', 137290.0),
  ('monthly_mrr', '2026-02', 'new_mrr_usd', 99600.0),
  ('monthly_mrr', '2026-03', 'new_mrr_usd', 123850.0),
  ('monthly_mrr', '2026-04', 'new_mrr_usd', 107600.0),
  ('monthly_mrr', '2026-05', 'new_mrr_usd', 137420.0),
  ('monthly_mrr', '2026-06', 'new_mrr_usd', 123980.0),
  ('monthly_mrr', '2026-07', 'new_mrr_usd', 10600.0),
  ('channel', 'Internal Database', 'filled', 71),
  ('channel', 'Internal Database', 'revenue_usd', 139570.0),
  ('channel', 'Job Board', 'filled', 138),
  ('channel', 'Job Board', 'revenue_usd', 254140.0),
  ('channel', 'LinkedIn', 'filled', 184),
  ('channel', 'LinkedIn', 'revenue_usd', 347930.0),
  ('channel', 'Referral', 'filled', 100),
  ('channel', 'Referral', 'revenue_usd', 180930.0),
  ('totals', 'all', 'filled', 493),
  ('totals', 'all', 'total_mrr_usd', 922570.0),
  ('totals', 'all', 'avg_ttf_days', 42.3),
  ('marketing', 'all', 'leads', 6494),
  ('marketing', 'all', 'deals_closed', 308),
  ('marketing', 'all', 'ad_spend_usd', 98229.57);

-- 2 · Recompute the same metrics on Snowflake and compare
WITH actual AS (
  SELECT 'row_count' AS check_name, 'vacancies' AS dim_value, 'rows' AS metric_name,
         COUNT(*)::NUMBER(18,2) AS actual_value
  FROM vacancies
  UNION ALL
  SELECT 'row_count', 'marketing_leads', 'rows', COUNT(*) FROM marketing_leads
  UNION ALL
  SELECT 'row_count', 'recruiters', 'rows', COUNT(*) FROM recruiters
  UNION ALL
  SELECT 'monthly_mrr', TO_CHAR(DATE_TRUNC('month', filled_date), 'YYYY-MM'),
         'new_mrr_usd', SUM(monthly_fee_usd)
  FROM vacancies WHERE status = 'Filled'
  GROUP BY 2
  UNION ALL
  SELECT 'channel', source_channel, 'filled', COUNT(*)
  FROM vacancies WHERE status = 'Filled'
  GROUP BY 2
  UNION ALL
  SELECT 'channel', source_channel, 'revenue_usd', SUM(monthly_fee_usd)
  FROM vacancies WHERE status = 'Filled'
  GROUP BY 2
  UNION ALL
  SELECT 'totals', 'all', 'filled', COUNT(*) FROM vacancies WHERE status = 'Filled'
  UNION ALL
  SELECT 'totals', 'all', 'total_mrr_usd', SUM(monthly_fee_usd)
  FROM vacancies WHERE status = 'Filled'
  UNION ALL
  SELECT 'totals', 'all', 'avg_ttf_days',
         ROUND(AVG(DATEDIFF('day', opened_date, filled_date)), 1)
  FROM vacancies WHERE status = 'Filled'
  UNION ALL
  SELECT 'marketing', 'all', 'leads', SUM(leads) FROM marketing_leads
  UNION ALL
  SELECT 'marketing', 'all', 'deals_closed', SUM(deals_closed) FROM marketing_leads
  UNION ALL
  SELECT 'marketing', 'all', 'ad_spend_usd', SUM(ad_spend_usd) FROM marketing_leads
)
SELECT
  b.check_name,
  b.dim_value,
  b.metric_name,
  b.expected_value,
  a.actual_value,
  IFF(a.actual_value IS NOT NULL
      AND ABS(a.actual_value - b.expected_value) < 0.01, 'PASS', 'FAIL') AS status
FROM parity_baseline b
LEFT JOIN actual a USING (check_name, dim_value, metric_name)
ORDER BY status DESC, check_name, dim_value, metric_name;

-- 3 · Sign-off rule
-- The migration is approved only when section 2 returns ZERO rows with
-- status = 'FAIL'. To assert it programmatically, wrap section 2 as a CTE:
--   SELECT COUNT_IF(status = 'FAIL') AS failures FROM (<section 2 query>);
-- failures must equal 0 before switching any dashboard to Snowflake.
