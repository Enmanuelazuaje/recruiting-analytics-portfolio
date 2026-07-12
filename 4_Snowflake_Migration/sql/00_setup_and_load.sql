-- =====================================================================
-- 00 · SNOWFLAKE SETUP & DATA LOAD
-- Target: Snowflake (free 30-day trial). Source data: the same CSVs
-- used by the BigQuery project (../2_BigQuery_SQL_Analytics/data).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS recruiting_analytics;
USE DATABASE recruiting_analytics;
USE SCHEMA public;

-- File format matching the source CSVs (empty string = NULL)
CREATE OR REPLACE FILE FORMAT csv_std
  TYPE = 'CSV'
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('');

CREATE OR REPLACE STAGE raw_stage FILE_FORMAT = csv_std;

-- Target tables (same structure as the BigQuery dataset)
CREATE OR REPLACE TABLE vacancies (
  vacancy_id        STRING,
  client_name       STRING,
  role_title        STRING,
  department        STRING,
  recruiter_id      STRING,
  opened_date       DATE,
  filled_date       DATE,
  status            STRING,
  source_channel    STRING,
  monthly_fee_usd   NUMBER(10,2),
  candidate_country STRING
);

CREATE OR REPLACE TABLE marketing_leads (
  date             DATE,
  channel          STRING,
  ad_spend_usd     NUMBER(10,2),
  leads            INTEGER,
  qualified_leads  INTEGER,
  client_meetings  INTEGER,
  deals_closed     INTEGER
);

CREATE OR REPLACE TABLE recruiters (
  recruiter_id   STRING,
  recruiter_name STRING,
  team           STRING,
  country        STRING,
  hire_date      DATE
);

-- OPTION A · Web UI: Data > Add Data > Load into table (pick csv_std format)
-- OPTION B · SnowSQL CLI:
--   PUT file:///<path>/vacancies.csv       @raw_stage AUTO_COMPRESS=TRUE;
--   PUT file:///<path>/marketing_leads.csv @raw_stage AUTO_COMPRESS=TRUE;
--   PUT file:///<path>/recruiters.csv      @raw_stage AUTO_COMPRESS=TRUE;

COPY INTO vacancies       FROM @raw_stage/vacancies.csv.gz;
COPY INTO marketing_leads FROM @raw_stage/marketing_leads.csv.gz;
COPY INTO recruiters      FROM @raw_stage/recruiters.csv.gz;

-- Sanity check after load (expected: 900 / 905 / 12)
SELECT 'vacancies' AS t, COUNT(*) AS rows FROM vacancies
UNION ALL SELECT 'marketing_leads', COUNT(*) FROM marketing_leads
UNION ALL SELECT 'recruiters', COUNT(*) FROM recruiters;
