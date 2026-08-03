-- Recruiter performance, pre-aggregated so the dashboard does presentation
-- and not computation.
--
-- Median is used instead of average deliberately: a handful of hard-to-fill
-- roles drags the mean upward and makes strong recruiters look slow. Average
-- is kept alongside it so the two can be compared rather than argued about.

with vacancies as (

    select * from {{ ref('int_vacancies_enriched') }}

),

aggregated as (

    select
        recruiter_id,
        recruiter_name,
        recruiter_team,
        recruiter_country,

        count(*)                                        as vacancies_assigned,
        count(*) filter (where is_filled)               as vacancies_filled,

        round(
            100.0 * count(*) filter (where is_filled)
            / nullif(count(*), 0)
        , 1)                                            as fill_rate_pct,

        median(days_to_fill) filter (where is_filled)   as median_days_to_fill,
        round(avg(days_to_fill) filter (where is_filled), 1) as avg_days_to_fill,

        sum(annual_contract_value_usd)                  as revenue_generated_usd

    from vacancies
    where recruiter_id is not null
    group by 1, 2, 3, 4

)

select * from aggregated
