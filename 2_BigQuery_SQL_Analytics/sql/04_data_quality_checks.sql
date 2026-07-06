-- =====================================================================
-- 04 · VALIDACIÓN Y RECONCILIACIÓN DE DATOS
-- Los checks que corro antes de confiar en cualquier dashboard.
-- Demuestra: detección de duplicados, integridad referencial,
-- reglas de negocio y reconciliación entre tablas.
-- =====================================================================

-- CHECK 1 · Duplicados por clave primaria
SELECT vacancy_id, COUNT(*) AS occurrences
FROM `recruiting_analytics.vacancies`
GROUP BY vacancy_id
HAVING COUNT(*) > 1;

-- CHECK 2 · Integridad referencial: vacantes con recruiter_id inexistente
SELECT v.vacancy_id, v.recruiter_id
FROM `recruiting_analytics.vacancies` v
LEFT JOIN `recruiting_analytics.recruiters` r USING (recruiter_id)
WHERE r.recruiter_id IS NULL;

-- CHECK 3 · Reglas de negocio violadas
SELECT
  vacancy_id,
  CASE
    WHEN status = 'Filled' AND filled_date IS NULL       THEN 'Filled sin fecha de cierre'
    WHEN status = 'Filled' AND monthly_fee_usd IS NULL   THEN 'Filled sin fee'
    WHEN filled_date < opened_date                       THEN 'Cierre anterior a apertura'
    WHEN status != 'Filled' AND filled_date IS NOT NULL  THEN 'Fecha de cierre sin estado Filled'
    WHEN monthly_fee_usd < 0                             THEN 'Fee negativo'
  END AS violation
FROM `recruiting_analytics.vacancies`
WHERE (status = 'Filled' AND (filled_date IS NULL OR monthly_fee_usd IS NULL))
   OR filled_date < opened_date
   OR (status != 'Filled' AND filled_date IS NOT NULL)
   OR monthly_fee_usd < 0;

-- CHECK 4 · Reconciliación: revenue por agregación directa vs. por detalle
-- (dos caminos independientes deben dar el mismo total)
WITH by_month AS (
  SELECT DATE_TRUNC(filled_date, MONTH) AS month, SUM(monthly_fee_usd) AS revenue
  FROM `recruiting_analytics.vacancies`
  WHERE status = 'Filled'
  GROUP BY month
),
by_recruiter AS (
  SELECT recruiter_id, SUM(monthly_fee_usd) AS revenue
  FROM `recruiting_analytics.vacancies`
  WHERE status = 'Filled'
  GROUP BY recruiter_id
)
SELECT
  (SELECT ROUND(SUM(revenue), 2) FROM by_month)     AS total_by_month,
  (SELECT ROUND(SUM(revenue), 2) FROM by_recruiter) AS total_by_recruiter,
  (SELECT ROUND(SUM(revenue), 2) FROM by_month) =
  (SELECT ROUND(SUM(revenue), 2) FROM by_recruiter) AS reconciled;

-- CHECK 5 · Continuidad temporal: días sin datos de marketing
-- (huecos en un pipeline diario = señal de fallo de carga)
WITH expected AS (
  SELECT day
  FROM UNNEST(GENERATE_DATE_ARRAY('2026-01-01', '2026-06-30')) AS day
),
actual AS (
  SELECT DISTINCT date AS day FROM `recruiting_analytics.marketing_leads`
)
SELECT e.day AS missing_day
FROM expected e
LEFT JOIN actual a USING (day)
WHERE a.day IS NULL
ORDER BY e.day;
