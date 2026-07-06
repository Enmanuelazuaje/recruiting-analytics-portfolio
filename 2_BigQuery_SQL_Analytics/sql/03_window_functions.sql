-- =====================================================================
-- 03 · WINDOW FUNCTIONS
-- Ranking de reclutadores, revenue acumulado y tendencias móviles.
-- Demuestra: RANK, ROW_NUMBER, LAG, SUM OVER, medias móviles, QUALIFY.
-- =====================================================================

-- Ranking de reclutadores por revenue, con posición dentro de su equipo
WITH recruiter_perf AS (
  SELECT
    r.recruiter_name,
    r.team,
    COUNT(*)                 AS placements,
    SUM(v.monthly_fee_usd)   AS revenue_usd,
    ROUND(AVG(DATE_DIFF(v.filled_date, v.opened_date, DAY)), 1) AS avg_ttf_days
  FROM `recruiting_analytics.vacancies` v
  JOIN `recruiting_analytics.recruiters` r USING (recruiter_id)
  WHERE v.status = 'Filled'
  GROUP BY r.recruiter_name, r.team
)
SELECT
  recruiter_name,
  team,
  placements,
  revenue_usd,
  avg_ttf_days,
  RANK() OVER (ORDER BY revenue_usd DESC)                    AS overall_rank,
  RANK() OVER (PARTITION BY team ORDER BY revenue_usd DESC)  AS rank_in_team,
  ROUND(revenue_usd - AVG(revenue_usd) OVER (PARTITION BY team), 0) AS vs_team_avg_usd
FROM recruiter_perf
ORDER BY overall_rank;

-- Revenue mensual: acumulado del año + variación mes contra mes (LAG)
WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC(filled_date, MONTH) AS month,
    SUM(monthly_fee_usd)           AS revenue_usd
  FROM `recruiting_analytics.vacancies`
  WHERE status = 'Filled'
  GROUP BY month
)
SELECT
  month,
  revenue_usd,
  SUM(revenue_usd) OVER (ORDER BY month)                       AS running_total_usd,
  LAG(revenue_usd) OVER (ORDER BY month)                       AS prev_month_usd,
  ROUND(SAFE_DIVIDE(revenue_usd - LAG(revenue_usd) OVER (ORDER BY month),
                    LAG(revenue_usd) OVER (ORDER BY month)) * 100, 1) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- Media móvil de 7 días de leads calificados por canal
SELECT
  date,
  channel,
  qualified_leads,
  ROUND(AVG(qualified_leads) OVER (
    PARTITION BY channel
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) AS qualified_leads_7d_avg
FROM `recruiting_analytics.marketing_leads`
ORDER BY channel, date;

-- La colocación más rápida de cada mes (QUALIFY + ROW_NUMBER)
SELECT
  DATE_TRUNC(filled_date, MONTH)            AS month,
  vacancy_id,
  role_title,
  client_name,
  DATE_DIFF(filled_date, opened_date, DAY)  AS days_to_fill
FROM `recruiting_analytics.vacancies`
WHERE status = 'Filled'
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY DATE_TRUNC(filled_date, MONTH)
  ORDER BY DATE_DIFF(filled_date, opened_date, DAY)
) = 1
ORDER BY month;
