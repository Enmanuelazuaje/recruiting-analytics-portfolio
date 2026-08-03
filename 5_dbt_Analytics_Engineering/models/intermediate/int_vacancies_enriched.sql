-- Intermediate: the joins and the shared business logic that more than one
-- mart needs. Defining "annual contract value" once here is what keeps the
-- recruiter mart and the client mart from quietly disagreeing later.

with vacancies as (

    select * from {{ ref('stg_vacancies') }}

),

recruiters as (

    select * from {{ ref('stg_recruiters') }}

),

joined as (

    select
        v.vacancy_id,
        v.client_name,
        v.role_title,
        v.department,
        v.source_channel,
        v.candidate_country,
        v.vacancy_status,
        v.is_filled,
        v.opened_date,
        v.filled_date,
        v.days_to_fill,
        v.monthly_fee_usd,

        v.recruiter_id,
        r.recruiter_name,
        r.team                                  as recruiter_team,
        r.recruiter_country,

        -- revenue is only recognised on filled vacancies
        {{ annual_contract_value('v.monthly_fee_usd', 'v.is_filled') }} as annual_contract_value_usd,

        -- fill speed banding, defined once and reused everywhere
        case
            when v.days_to_fill is null then 'not filled'
            when v.days_to_fill <= 14   then 'fast (0-14d)'
            when v.days_to_fill <= 30   then 'standard (15-30d)'
            else 'slow (31d+)'
        end                                     as fill_speed_band,

        date_trunc('month', v.opened_date)      as opened_month

    from vacancies v
    left join recruiters r
        on v.recruiter_id = r.recruiter_id

)

select * from joined
