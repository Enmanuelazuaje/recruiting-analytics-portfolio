# Recruiting Analytics Portfolio

End-to-end analytics portfolio built around a realistic dataset from a remote staffing
agency: **900 vacancies**, daily **marketing performance** (spend, leads, deals) and a
recruiter dimension table. Five projects, one business question each.

**Author:** Enmanuel Azuaje — [enmanuelazuaje.github.io](https://enmanuelazuaje.github.io) · enmanuelacepeda@gmail.com

[![dbt CI](https://github.com/Enmanuelazuaje/recruiting-analytics-portfolio/actions/workflows/dbt_ci.yml/badge.svg)](https://github.com/Enmanuelazuaje/recruiting-analytics-portfolio/actions/workflows/dbt_ci.yml)

| Project | Stack | What it shows |
|---------|-------|---------------|
| [1. Tableau Dashboard](1_Tableau_Recruiting_Dashboard/) | Tableau Public | Sales, vacancies & marketing performance dashboard |
| [2. BigQuery SQL Analytics](2_BigQuery_SQL_Analytics/) | BigQuery (GCP), Standard SQL | Advanced SQL: CTEs, window functions, data-quality & reconciliation checks |
| [3. n8n ETL Pipeline](3_n8n_ETL_Pipeline/) | n8n, JavaScript | Scheduled ETL with cleaning, validation and a data-quality report |
| [4. Snowflake Migration](4_Snowflake_Migration/) | Snowflake, Standard SQL | BigQuery → Snowflake port with automated cross-platform parity QA (27 checks) |
| [5. dbt Analytics Engineering](5_dbt_Analytics_Engineering/) | dbt, DuckDB, GitHub Actions | Layered models, 29 tests encoding business rules, data dictionary, CI on every PR |

## Start here

If you only open one project, open **[5. dbt Analytics Engineering](5_dbt_Analytics_Engineering/)** —
it is the closest to how this work is done in production, and it runs on your
machine in two commands with no cloud account:

```bash
pip install dbt-duckdb
cd 5_dbt_Analytics_Engineering && dbt build --profiles-dir .
```

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

Fill rate · time-to-fill (avg / median / P90) · new MRR · recruiter leaderboard ·
sourcing-channel effectiveness · cost per lead · lead-to-deal conversion ·
pipeline reconciliation (rows in = duplicates + valid + invalid).

## Data quality as a first-class concern

Every project carries its own validation rather than treating quality as a
final audit: reconciliation checks in the BigQuery SQL, a data-quality gate in
the n8n pipeline, 27 parity checks across the Snowflake migration, and 29 dbt
tests that fail the build when a business rule is violated.

One of those dbt tests was wrong on the first run — a blanket `not_null` on
placement fee flagged 407 rows that were correct, because a fee is only agreed
at placement. It was replaced with a conditional test matching the rule the
business actually holds, and the episode is written up in the
[project README](5_dbt_Analytics_Engineering/#a-test-that-was-wrong). Checking
whether the assumption or the data is at fault is the habit these projects are
meant to demonstrate.
