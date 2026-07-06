# n8n ETL Pipeline — Data-Quality Gate

Scheduled **n8n** workflow that ingests a deliberately dirty vacancies CSV, cleans
and validates it against business rules, and publishes two artifacts on every run:
the clean dataset and a **data-quality report** with a row-count reconciliation.

## Pipeline

```
Schedule (daily 7 AM) ─┐
Manual trigger ────────┴─> Read CSV ─> Extract ─> Clean & validate ─┬─> Valid records ─> vacancies_clean.json
                                                                    └─> Quality report ─> data_quality_report.json
```

## What the transform handles

| Issue in raw data | Fix |
|-------------------|-----|
| Exact duplicates | Deduplicated by `vacancy_id` |
| `BRIGHTLINE HEALTH` / `brightline health` | Normalized to title case |
| `$1900 USD` in a numeric column | Parsed to `1900` |
| `03/15/2026` mixed with ISO dates | Normalized to `YYYY-MM-DD` |
| Missing `recruiter_id` | Flagged as invalid (referential integrity) |
| `Filled` rows without close date / fee | Flagged as business-rule violations |

Invalid rows are **never silently dropped** — they are counted and categorized in
the report, and the reconciliation check asserts
`rows_in = duplicates + valid + invalid` on every execution.

## Sample report output

See [`output/data_quality_report.json`](output/data_quality_report.json) — rows in,
duplicates removed, invalid rows by issue type, reconciliation status and total
monthly revenue of the clean records.

## Reproduce it

1. `npx n8n` (or Docker — see n8n docs), open http://localhost:5678
2. Workflows → Import from File → `workflow_etl_vacancies.json`
3. Adjust the three file paths (read + two writes) to your machine, then
   **Execute workflow**. Activate the schedule trigger to run it daily.
