# Recruiting Analytics Portfolio

End-to-end analytics portfolio built around a realistic dataset from a remote staffing
agency: **900 vacancies**, daily **marketing performance** (spend, leads, deals) and a
recruiter dimension table. Four projects, one business question each.

**Author:** Enmanuel Azuaje — [enmanuelazuaje.github.io](https://enmanuelazuaje.github.io) · enmanuelacepeda@gmail.com

| Project | Stack | What it shows |
|---------|-------|---------------|
| [1. Tableau Dashboard](1_Tableau_Recruiting_Dashboard/) | Tableau Public | Sales, vacancies & marketing performance dashboard |
| [2. BigQuery SQL Analytics](2_BigQuery_SQL_Analytics/) | BigQuery (GCP), Standard SQL | Advanced SQL: CTEs, window functions, data-quality & reconciliation checks |
| [3. n8n ETL Pipeline](3_n8n_ETL_Pipeline/) | n8n, JavaScript | Scheduled ETL with cleaning, validation and a data-quality report |
| [4. Snowflake Migration](4_Snowflake_Migration/) | Snowflake, Standard SQL | BigQuery → Snowflake port with automated cross-platform parity QA (27 checks) |

## The dataset

Synthetic but business-realistic (generated with a seeded script, so results are reproducible):

- `vacancies.csv` — 900 job openings (Oct 2025 – Jun 2026): client, role, recruiter,
  status (Filled / Open / Cancelled), sourcing channel, monthly fee.
- `marketing_leads.csv` — daily funnel per channel (Jan – Jun 2026): ad spend, leads,
  qualified leads, client meetings, deals closed.
- `recruiters.csv` — recruiter dimension (team, country, hire date).

The n8n project uses a deliberately **dirty** variant (`vacancies_raw.csv`) with
duplicates, mixed date formats, currency text in numeric fields and missing foreign
keys — the raw material for the data-quality pipeline.

## Key metrics covered

Fill rate · time-to-fill (avg / P90) · new MRR · recruiter leaderboard ·
sourcing-channel effectiveness · cost per lead · lead-to-deal conversion ·
pipeline reconciliation (rows in = duplicates + valid + invalid).
