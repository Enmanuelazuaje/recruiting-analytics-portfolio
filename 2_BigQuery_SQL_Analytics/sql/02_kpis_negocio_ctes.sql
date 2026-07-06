-- =====================================================================
-- 02 · KPIs DE NEGOCIO CON CTEs
-- Fill rate, time-to-fill y revenue mensual — el corazón del negocio
-- de una agencia de reclutamiento.
-- =====================================================================

-- KPIs mensuales: vacantes abiertas, cubiertas, fill rate, time-to-fill
-- promedio y revenue mensual recurrente generado.
WITH monthly_openings AS (
  SELECT
    DATE_TRUNC(opened_date, MONTH) AS month,
    COUNT(*)                       AS vacancies_opened
  FROM `recruiting_analytics.vacancies`
  GROUP BY month
),
monthly_fills AS (
  SELECT
    DATE_TRUNC(filled_date, MONTH)                    AS month,
    COUNT(*)                                          AS vacancies_filled,
    ROUND(AVG(DATE_DIFF(filled_date, opened_date, DAY)), 1) AS avg_time_to_fill_days,
    SUM(monthly_fee_usd)                              AS new_mrr_usd
  FROM `recruiting_analytics.vacancies`
  WHERE status = 'Filled'
  GROUP BY month
)
SELECT
  o.month,
  o.vacancies_opened,
  COALESCE(f.vacancies_filled, 0)                 AS vacancies_filled,
  ROUND(SAFE_DIVIDE(f.vacancies_filled, o.vacancies_opened) * 100, 1) AS fill_rate_pct,
  f.avg_time_to_fill_days,
  COALESCE(f.new_mrr_usd, 0)                      AS new_mrr_usd
FROM monthly_openings o
LEFT JOIN monthly_fills f USING (month)
ORDER BY o.month;

-- Time-to-fill por departamento y rol (¿dónde se atasca el negocio?)
WITH filled AS (
  SELECT
    department,
    role_title,
    DATE_DIFF(filled_date, opened_date, DAY) AS days_to_fill,
    monthly_fee_usd
  FROM `recruiting_analytics.vacancies`
  WHERE status = 'Filled'
)
SELECT
  department,
  role_title,
  COUNT(*)                              AS placements,
  ROUND(AVG(days_to_fill), 1)           AS avg_days_to_fill,
  APPROX_QUANTILES(days_to_fill, 100)[OFFSET(90)] AS p90_days_to_fill,
  ROUND(AVG(monthly_fee_usd), 0)        AS avg_monthly_fee_usd
FROM filled
GROUP BY department, role_title
HAVING COUNT(*) >= 5
ORDER BY avg_days_to_fill DESC;

-- Efectividad por canal de sourcing
SELECT
  source_channel,
  COUNT(*)                                          AS total_vacancies,
  COUNTIF(status = 'Filled')                        AS filled,
  ROUND(COUNTIF(status = 'Filled') / COUNT(*) * 100, 1) AS fill_rate_pct,
  ROUND(SUM(IF(status = 'Filled', monthly_fee_usd, 0)), 0) AS revenue_usd
FROM `recruiting_analytics.vacancies`
GROUP BY source_channel
ORDER BY revenue_usd DESC;
