-- =====================================================================
-- 04 · DATA VALIDATION & RECONCILIATION (Snowflake port)
-- Dialect change vs BigQuery: GENERATE_DATE_ARRAY -> GENERATOR + DATEADD
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;

-- CHECK 1 · Primary-key duplicates
SELECT vacancy_id, COUNT(*) AS occurrences
FROM vacancies
GROUP BY vacancy_id
HAVING COUNT(*) > 1;

-- CHECK 2 · Referential integrity: vacancies pointing to unknown recruiters
SELECT v.vacancy_id, v.recruiter_id
FROM vacancies v
LEFT JOIN recruiters r USING (recruiter_id)
WHERE r.recruiter_id IS NULL;

-- CHECK 3 · Business-rule violations
SELECT
  vacancy_id,
  CASE
    WHEN status = 'Filled' AND filled_date IS NULL      THEN 'Filled without close date'
    WHEN status = 'Filled' AND monthly_fee_usd IS NULL  THEN 'Filled without fee'
    WHEN filled_date < opened_date                      THEN 'Closed before opened'
    WHEN status != 'Filled' AND filled_date IS NOT NULL THEN 'Close date without Filled status'
    WHEN monthly_fee_usd < 0                            THEN 'Negative fee'
  END AS violation
FROM vacancies
WHERE (status = 'Filled' AND (filled_date IS NULL OR monthly_fee_usd IS NULL))
   OR filled_date < opened_date
   OR (status != 'Filled' AND filled_date IS NOT NULL)
   OR monthly_fee_usd < 0;

-- CHECK 4 · Reconciliation: revenue via two independent aggregation paths
WITH by_month AS (
  SELECT DATE_TRUNC('month', filled_date) AS month, SUM(monthly_fee_usd) AS revenue
  FROM vacancies WHERE status = 'Filled' GROUP BY 1
),
by_recruiter AS (
  SELECT recruiter_id, SUM(monthly_fee_usd) AS revenue
  FROM vacancies WHERE status = 'Filled' GROUP BY 1
)
SELECT
  (SELECT ROUND(SUM(revenue), 2) FROM by_month)     AS total_by_month,
  (SELECT ROUND(SUM(revenue), 2) FROM by_recruiter) AS total_by_recruiter,
  (SELECT ROUND(SUM(revenue), 2) FROM by_month) =
  (SELECT ROUND(SUM(revenue), 2) FROM by_recruiter) AS reconciled;

-- CHECK 5 · Temporal continuity: missing days in the daily marketing feed
-- (Jan 1 - Jun 30 2026 = 181 days)
WITH expected AS (
  SELECT DATEADD('day', ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1,
                 '2026-01-01'::DATE) AS day
  FROM TABLE(GENERATOR(ROWCOUNT => 181))
),
actual AS (
  SELECT DISTINCT date AS day FROM marketing_leads
)
SELECT e.day AS missing_day
FROM expected e
LEFT JOIN actual a USING (day)
WHERE a.day IS NULL
ORDER BY e.day;
