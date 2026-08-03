-- Staging: one model per source. Renaming, casting and light cleaning only.
-- No joins and no business logic live here, so a source change is fixed in
-- exactly one place instead of across every downstream query.

with source as (

    select * from {{ ref('vacancies') }}

),

renamed as (

    select
        vacancy_id,
        client_name,
        role_title,
        department,
        recruiter_id,
        source_channel,
        candidate_country,

        -- status is normalised so downstream models never depend on casing
        lower(trim(status))                          as vacancy_status,

        opened_date,
        filled_date,
        monthly_fee_usd,

        case when lower(trim(status)) = 'filled'
             then true else false end                as is_filled,

        -- null for vacancies that are still open: an unfilled role has no
        -- time-to-fill, and defaulting it to 0 would silently flatter the KPI
        case when filled_date is not null
             then date_diff('day', opened_date, filled_date)
        end                                          as days_to_fill

    from source

)

select * from renamed
