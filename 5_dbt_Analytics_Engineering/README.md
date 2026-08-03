# dbt Analytics Engineering — Recruiting Domain

A production-shaped dbt project over the recruiting dataset used across this
portfolio: layered models, a test suite that encodes business rules, a data
dictionary, and CI that blocks a merge when either breaks.

It runs locally on DuckDB — no cloud account, no credentials, no cost:

```bash
pip install dbt-duckdb
dbt build --profiles-dir .
```

Last run: **39/39 passed** — 3 seeds, 4 staging/intermediate views, 3 mart
tables, 29 tests.

---

## Layers

| Layer | Materialization | Responsibility |
|---|---|---|
| `staging` | view | One model per source. Renaming, casting, light cleaning. No joins, no business logic. |
| `intermediate` | view | Joins and the business rules shared by more than one mart. |
| `marts` | table | Business-facing tables, dimensional and named in business language. |

The reason for the split is maintenance, not aesthetics. When a source renames
a column, exactly one staging model changes. When the revenue recognition
policy changes, one macro changes. Business rules defined in three places is
how two dashboards end up disagreeing about the same number.

### Models

```
staging          stg_vacancies · stg_recruiters · stg_marketing_leads
intermediate     int_vacancies_enriched
marts            fct_vacancies · dim_recruiter_performance · fct_marketing_performance
```

---

## Testing

29 tests run on every build.

**Generic** — `unique` and `not_null` on primary keys, `relationships` for
referential integrity between vacancies and recruiters, `accepted_values` on
status and banding columns.

**Singular** — business rules that generic tests cannot express:

| Test | Rule it defends |
|---|---|
| `assert_revenue_reconciles_two_paths` | Total revenue from the fact table must equal total revenue from the recruiter scorecard. Catches aggregation and join bugs that every structural test passes. |
| `assert_revenue_only_on_filled_vacancies` | An unfilled vacancy must never carry revenue — asserted independently of the macro that implements it, so changing the macro cannot silently change the policy. |
| `assert_filled_vacancies_have_a_fee` | A filled vacancy must always carry a fee. |
| `assert_filled_date_after_opened_date` | A vacancy cannot be filled before it was opened. |
| `assert_qualified_leads_not_exceeding_leads` | Funnel integrity: a subset cannot exceed its superset. |

### A test that was wrong

The first build failed: `not_null` on `monthly_fee_usd` returned 407 rows.

The data was right and the test was wrong. A placement fee is agreed at
placement, so open and cancelled vacancies legitimately have none — all 493
filled vacancies had one. The blanket test was replaced with
`assert_filled_vacancies_have_a_fee`, which expresses the rule the business
actually holds.

Recorded here because the reflex to tighten a test until it goes green is how
real constraints get erased. The useful move was checking whether the
assumption or the data was at fault.

---

## Data dictionary

`models/schema.yml` carries a definition for every column in business
language, including edge cases — why `days_to_fill` is null rather than zero
for open vacancies, why the recruiter scorecard leads with median instead of
mean.

This is what makes the marts safe to expose to an AI or conversational
analytics layer. A human analyst who sees an ambiguous column asks someone; a
model guesses, and guesses confidently. Semantics have to live in the data
layer, not in the prompt.

```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .   # lineage graph + searchable dictionary
```

---

## CI

`.github/workflows/dbt_ci.yml` runs on every push and pull request: parse,
build, full test suite, docs generation, artifacts uploaded. A model that
violates a business rule fails the check before it can be merged — the same
discipline applied to application code, applied to data.

---

## Portability

DuckDB is the local target so the project is reproducible by anyone in one
command. The models are written against dbt's adapter layer, so pointing them
at BigQuery or Snowflake is a `profiles.yml` change rather than a rewrite —
the same portability validated in the
[Snowflake migration project](../4_Snowflake_Migration), where the parity QA
confirmed identical metrics across both warehouses.
