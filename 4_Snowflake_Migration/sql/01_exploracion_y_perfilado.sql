-- =====================================================================
-- 01 · EXPLORATION & PROFILING (Snowflake port of the BigQuery script)
-- Dialect changes vs BigQuery: COUNTIF -> COUNT_IF
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;

-- Volume and date range per table
SELECT 'vacancies' AS table_name, COUNT(*) AS row_count,
       MIN(opened_date) AS min_date, MAX(opened_date) AS max_date
FROM vacancies
UNION ALL
SELECT 'marketing_leads', COUNT(*), MIN(date), MAX(date)
FROM marketing_leads;

-- Vacancy status distribution
SELECT status,
       COUNT(*) AS vacancies,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM vacancies
GROUP BY status
ORDER BY vacancies DESC;

-- Null profiling on key columns
SELECT
  COUNT(*)                                                   AS total_rows,
  COUNT_IF(vacancy_id IS NULL)                               AS null_vacancy_id,
  COUNT_IF(recruiter_id IS NULL)                             AS null_recruiter_id,
  COUNT_IF(status = 'Filled' AND filled_date IS NULL)        AS filled_without_date,
  COUNT_IF(status = 'Filled' AND monthly_fee_usd IS NULL)    AS filled_without_fee
FROM vacancies;
