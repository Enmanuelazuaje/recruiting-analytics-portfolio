-- =====================================================================
-- 03 · WINDOW FUNCTIONS (Snowflake port)
-- RANK, LAG, running totals, moving averages and QUALIFY work the same
-- as BigQuery — only DATE_TRUNC / DATEDIFF / DIV0 syntax changes.
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;

-- Recruiter leaderboard with in-team ranking
WITH recruiter_perf AS (
  SELECT
    r.recruiter_name,
    r.team,
    COUNT(*)               AS placements,
    SUM(v.monthly_fee_usd) AS revenue_usd,
    ROUND(AVG(DATEDIFF('day', v.opened_date, v.filled_date)), 1) AS avg_ttf_days
  FROM vacancies v
  JOIN recruiters r USING (recruiter_id)
  WHERE v.status = 'Filled'
  GROUP BY r.recruiter_name, r.team
)
SELECT
  recruiter_name,
  team,
  placements,
  revenue_usd,
  avg_ttf_days,
  RANK() OVER (ORDER BY revenue_usd DESC)                   AS overall_rank,
  RANK() OVER (PARTITION BY team ORDER BY revenue_usd DESC) AS rank_in_team,
  ROUND(revenue_usd - AVG(revenue_usd) OVER (PARTITION BY team), 0) AS vs_team_avg_usd
FROM recruiter_perf
ORDER BY overall_rank;

-- Monthly revenue: running total + month-over-month growth (LAG)
WITH monthly_revenue AS (
  SELECT DATE_TRUNC('month', filled_date) AS month,
         SUM(monthly_fee_usd)             AS revenue_usd
  FROM vacancies
  WHERE status = 'Filled'
  GROUP BY 1
)
SELECT
  month,
  revenue_usd,
  SUM(revenue_usd) OVER (ORDER BY month)  AS running_total_usd,
  LAG(revenue_usd) OVER (ORDER BY month)  AS prev_month_usd,
  ROUND(DIV0(revenue_usd - LAG(revenue_usd) OVER (ORDER BY month),
             LAG(revenue_usd) OVER (ORDER BY month)) * 100, 1) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- 7-day moving average of qualified leads per channel
SELECT
  date,
  channel,
  qualified_leads,
  ROUND(AVG(qualified_leads) OVER (
    PARTITION BY channel
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) AS qualified_leads_7d_avg
FROM marketing_leads
ORDER BY channel, date;

-- Fastest placement of each month (QUALIFY + ROW_NUMBER)
SELECT
  DATE_TRUNC('month', filled_date)            AS month,
  vacancy_id,
  role_title,
  client_name,
  DATEDIFF('day', opened_date, filled_date)   AS days_to_fill
FROM vacancies
WHERE status = 'Filled'
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY DATE_TRUNC('month', filled_date)
  ORDER BY DATEDIFF('day', opened_date, filled_date)
) = 1
ORDER BY month;
