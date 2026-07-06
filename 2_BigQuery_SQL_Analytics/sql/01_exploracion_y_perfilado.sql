-- =====================================================================
-- 01 · EXPLORACIÓN Y PERFILADO DE DATOS
-- Dataset: recruiting_analytics (BigQuery Sandbox - gratis, sin tarjeta)
-- Autor: Enmanuel Azuaje
-- =====================================================================

-- Vista general: volumen y rango de fechas por tabla
SELECT 'vacancies' AS table_name, COUNT(*) AS row_count,
       MIN(opened_date) AS min_date, MAX(opened_date) AS max_date
FROM `recruiting_analytics.vacancies`
UNION ALL
SELECT 'marketing_leads', COUNT(*), MIN(date), MAX(date)
FROM `recruiting_analytics.marketing_leads`;

-- Distribución de estados de vacantes
SELECT status,
       COUNT(*) AS vacancies,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM `recruiting_analytics.vacancies`
GROUP BY status
ORDER BY vacancies DESC;

-- Perfilado de nulos por columna clave (auditoría rápida de calidad)
SELECT
  COUNT(*)                                   AS total_rows,
  COUNTIF(vacancy_id IS NULL)                AS null_vacancy_id,
  COUNTIF(recruiter_id IS NULL)              AS null_recruiter_id,
  COUNTIF(status = 'Filled' AND filled_date IS NULL) AS filled_without_date,
  COUNTIF(status = 'Filled' AND monthly_fee_usd IS NULL) AS filled_without_fee
FROM `recruiting_analytics.vacancies`;
