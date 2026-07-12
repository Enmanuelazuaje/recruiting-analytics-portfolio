-- =====================================================================
-- 05 · MARKETING PERFORMANCE (Snowflake port)
-- Migration gotcha: BigQuery DATE_TRUNC(date, WEEK(MONDAY)) needs
-- WEEK_START = 1 in Snowflake for identical weekly buckets.
-- =====================================================================
USE DATABASE recruiting_analytics; USE SCHEMA public;
ALTER SESSION SET WEEK_START = 1;  -- Monday weeks, matching BigQuery WEEK(MONDAY)

-- Full funnel by channel: spend -> leads -> qualified -> meetings -> deals
WITH channel_perf AS (
  SELECT
    channel,
    SUM(ad_spend_usd)    AS total_spend,
    SUM(leads)           AS leads,
    SUM(qualified_leads) AS qualified,
    SUM(client_meetings) AS meetings,
    SUM(deals_closed)    AS deals
  FROM marketing_leads
  GROUP BY channel
)
SELECT
  channel,
  ROUND(total_spend, 0)                            AS spend_usd,
  leads,
  qualified,
  meetings,
  deals,
  ROUND(DIV0(qualified, leads) * 100, 1)           AS lead_to_qualified_pct,
  ROUND(DIV0(deals, leads) * 100, 1)               AS lead_to_deal_pct,
  ROUND(DIV0(total_spend, leads), 2)               AS cost_per_lead_usd,
  ROUND(DIV0(total_spend, deals), 0)               AS cost_per_deal_usd
FROM channel_perf
ORDER BY deals DESC;

-- Weekly trend: is blended cost-per-lead improving?
SELECT
  DATE_TRUNC('week', date)                              AS week,
  ROUND(SUM(ad_spend_usd), 0)                           AS spend_usd,
  SUM(leads)                                            AS leads,
  ROUND(DIV0(SUM(ad_spend_usd), SUM(leads)), 2)         AS blended_cpl_usd,
  SUM(deals_closed)                                     AS deals
FROM marketing_leads
WHERE channel IN ('LinkedIn Ads', 'Google Ads', 'Meta Ads')
GROUP BY 1
ORDER BY week;

-- Executive view: does the marketing pipeline sustain the business?
WITH deals_monthly AS (
  SELECT DATE_TRUNC('month', date) AS month, SUM(deals_closed) AS new_clients
  FROM marketing_leads GROUP BY 1
),
vacancies_monthly AS (
  SELECT DATE_TRUNC('month', opened_date) AS month, COUNT(*) AS vacancies_opened
  FROM vacancies GROUP BY 1
)
SELECT
  d.month,
  d.new_clients,
  v.vacancies_opened,
  ROUND(DIV0(v.vacancies_opened, d.new_clients), 1) AS vacancies_per_new_client
FROM deals_monthly d
JOIN vacancies_monthly v USING (month)
ORDER BY d.month;
