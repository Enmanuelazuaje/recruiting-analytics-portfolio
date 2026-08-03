-- Two-path reconciliation: total recognised revenue computed from the fact
-- table must equal the same figure computed from the recruiter scorecard.
--
-- This is the check that catches an aggregation or join bug that every
-- structural test would happily pass. If the two paths ever disagree, the
-- build fails before a number reaches a dashboard.

with from_fact as (

    select round(sum(annual_contract_value_usd), 2) as revenue
    from {{ ref('fct_vacancies') }}

),

from_scorecard as (

    select round(sum(revenue_generated_usd), 2) as revenue
    from {{ ref('dim_recruiter_performance') }}

)

select
    f.revenue as revenue_from_fact,
    s.revenue as revenue_from_scorecard,
    abs(f.revenue - s.revenue) as difference
from from_fact f
cross join from_scorecard s
where abs(f.revenue - s.revenue) > 0.01
