# BigQuery → Snowflake Migration with Parity QA

Full port of the [BigQuery analytics layer](../2_BigQuery_SQL_Analytics/) to
**Snowflake**, including the piece most migrations skip: an automated
**cross-platform parity QA** that certifies every migrated metric matches the
source platform before any dashboard is switched over.

## Why this project

Rewriting SQL for a new warehouse is the easy half of a migration. The hard
half is proving the numbers still match. This project treats parity as a
first-class deliverable: a baseline of **27 expected values** captured on the
source platform (row counts, monthly MRR, per-channel revenue, global KPIs,
marketing totals) is loaded into Snowflake and asserted with a PASS/FAIL
report — zero failures required for sign-off.

## Scripts

| Script | Purpose |
|--------|---------|
| `sql/00_setup_and_load.sql` | Database, file format, stage, DDL and COPY INTO |
| `sql/01`–`05` | The five analytics scripts, ported to Snowflake dialect |
| `sql/06_parity_qa.sql` | Baseline load + PASS/FAIL comparison of all 27 checks |

Source data: the same three CSVs as the BigQuery project
([`../2_BigQuery_SQL_Analytics/data/`](../2_BigQuery_SQL_Analytics/data/)).

## Dialect migration notes (BigQuery → Snowflake)

| BigQuery | Snowflake | Gotcha |
|----------|-----------|--------|
| `DATE_TRUNC(col, MONTH)` | `DATE_TRUNC('month', col)` | Unit becomes a string, moves first |
| `DATE_DIFF(end, start, DAY)` | `DATEDIFF('day', start, end)` | **Argument order flips** — silent off-by-sign bug if missed |
| `SAFE_DIVIDE(a, b)` | `DIV0(a, b)` | `DIV0NULL` if divisor can be NULL |
| `COUNTIF(cond)` | `COUNT_IF(cond)` | Underscore |
| `IF(c, a, b)` | `IFF(c, a, b)` | Extra F |
| `APPROX_QUANTILES(x, 100)[OFFSET(90)]` | `APPROX_PERCENTILE(x, 0.9)` | Different function family |
| `GENERATE_DATE_ARRAY(...)` + `UNNEST` | `GENERATOR(ROWCOUNT => n)` + `DATEADD` | Use `ROW_NUMBER()`, not raw `SEQ4()` (can have gaps) |
| `DATE_TRUNC(col, WEEK(MONDAY))` | `ALTER SESSION SET WEEK_START = 1` + `DATE_TRUNC('week', col)` | Week-start mismatch shifts weekly buckets |
| `QUALIFY` | `QUALIFY` | Identical — pleasant surprise |

## Reproduce it

1. Start a [Snowflake 30-day free trial](https://signup.snowflake.com/) (no card).
2. Run `00_setup_and_load.sql`, loading the three CSVs via the web UI or SnowSQL.
3. Run scripts `01`–`05` and compare with their BigQuery counterparts.
4. Run `06_parity_qa.sql` — all 27 checks must return `PASS`.
