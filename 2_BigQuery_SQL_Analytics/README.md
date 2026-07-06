# BigQuery SQL Analytics — Recruiting KPIs

Advanced Standard SQL on **Google BigQuery** answering the questions a staffing
agency actually asks: how fast do we fill roles, which channels make money, and
can we trust the numbers?

## Scripts (run in order)

| Script | Techniques | Business question |
|--------|-----------|-------------------|
| `sql/01_exploracion_y_perfilado.sql` | COUNTIF, window %, null audit | What does the data look like? Any gaps? |
| `sql/02_kpis_negocio_ctes.sql` | CTEs, DATE_DIFF, SAFE_DIVIDE, APPROX_QUANTILES | Fill rate, time-to-fill (avg & P90), monthly MRR |
| `sql/03_window_functions.sql` | RANK, LAG, running totals, 7-day moving avg, QUALIFY | Recruiter leaderboard, MoM growth, lead trends |
| `sql/04_data_quality_checks.sql` | dup detection, referential integrity, reconciliation | Can we trust this data before it hits a dashboard? |
| `sql/05_marketing_performance.sql` | funnel aggregation, cost-per-lead / cost-per-deal | Which channel pays for itself? |

## Reproduce it

1. Open [BigQuery Sandbox](https://console.cloud.google.com/bigquery) (free tier, no credit card).
2. Create a dataset named `recruiting_analytics` (location: US).
3. Upload the three CSVs from `data/` as tables `vacancies`, `marketing_leads`,
   `recruiters` (schema auto-detect).
4. Paste and run each script from `sql/`.

## Design notes

- Every revenue figure is cross-checked two independent ways (by month vs. by
  recruiter) before being reported — see check 4 in `04_data_quality_checks.sql`.
- `SAFE_DIVIDE` everywhere a denominator can be zero; `QUALIFY` keeps
  top-N-per-group queries readable.
- Check 5 detects missing days in the daily marketing feed — the first symptom
  of a broken ingestion pipeline.
