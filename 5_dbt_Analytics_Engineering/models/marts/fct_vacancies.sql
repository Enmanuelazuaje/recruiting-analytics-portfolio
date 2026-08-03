-- Fact table at vacancy grain: one row per vacancy, already joined to its
-- recruiter and carrying the shared business rules. This is the table a
-- dashboard or an AI agent should query — flat, named in business language,
-- and documented in schema.yml.

select
    vacancy_id,
    client_name,
    role_title,
    department,
    recruiter_id,
    recruiter_name,
    recruiter_team,
    recruiter_country,
    candidate_country,
    source_channel,
    vacancy_status,
    is_filled,
    opened_date,
    opened_month,
    filled_date,
    days_to_fill,
    fill_speed_band,
    monthly_fee_usd,
    annual_contract_value_usd

from {{ ref('int_vacancies_enriched') }}
