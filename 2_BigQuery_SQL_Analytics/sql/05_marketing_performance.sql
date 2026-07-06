-- =====================================================================
-- 05 · MARKETING PERFORMANCE
-- Cost-per-lead, funnel de conversión y ROI por canal — el reporte
-- de "sales, vacancies and marketing performance" del anuncio.
-- =====================================================================

-- Funnel completo por canal: spend → leads → calificados → reuniones → deals
WITH channel_perf AS (
  SELECT
    channel,
    SUM(ad_spend_usd)     AS total_spend,
    SUM(leads)            AS leads,
    SUM(qualified_leads)  AS qualified,
    SUM(client_meetings)  AS meetings,
    SUM(deals_closed)     AS deals
  FROM `recruiting_analytics.marketing_leads`
  GROUP BY channel
)
SELECT
  channel,
  ROUND(total_spend, 0)                              AS spend_usd,
  leads,
  qualified,
  meetings,
  deals,
  ROUND(SAFE_DIVIDE(qualified, leads) * 100, 1)      AS lead_to_qualified_pct,
  ROUND(SAFE_DIVIDE(deals, leads) * 100, 1)          AS lead_to_deal_pct,
  ROUND(SAFE_DIVIDE(total_spend, NULLIF(leads, 0)), 2)  AS cost_per_lead_usd,
  ROUND(SAFE_DIVIDE(total_spend, NULLIF(deals, 0)), 0)  AS cost_per_deal_usd
FROM channel_perf
ORDER BY deals DESC;

-- Tendencia semanal: ¿el costo por lead mejora o empeora?
SELECT
  DATE_TRUNC(date, WEEK(MONDAY))                           AS week,
  ROUND(SUM(ad_spend_usd), 0)                              AS spend_usd,
  SUM(leads)                                               AS leads,
  ROUND(SAFE_DIVIDE(SUM(ad_spend_usd), NULLIF(SUM(leads), 0)), 2) AS blended_cpl_usd,
  SUM(deals_closed)                                        AS deals
FROM `recruiting_analytics.marketing_leads`
WHERE channel IN ('LinkedIn Ads', 'Google Ads', 'Meta Ads')  -- solo canales pagados
GROUP BY week
ORDER BY week;

-- Vista ejecutiva: ¿el pipeline de marketing sostiene el negocio?
-- Une marketing (deals nuevos) con operaciones (vacantes abiertas/mes)
WITH deals_monthly AS (
  SELECT DATE_TRUNC(date, MONTH) AS month, SUM(deals_closed) AS new_clients
  FROM `recruiting_analytics.marketing_leads`
  GROUP BY month
),
vacancies_monthly AS (
  SELECT DATE_TRUNC(opened_date, MONTH) AS month, COUNT(*) AS vacancies_opened
  FROM `recruiting_analytics.vacancies`
  GROUP BY month
)
SELECT
  d.month,
  d.new_clients,
  v.vacancies_opened,
  ROUND(SAFE_DIVIDE(v.vacancies_opened, d.new_clients), 1) AS vacancies_per_new_client
FROM deals_monthly d
JOIN vacancies_monthly v USING (month)
ORDER BY d.month;
