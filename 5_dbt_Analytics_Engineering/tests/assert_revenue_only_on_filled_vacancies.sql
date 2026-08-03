-- Revenue recognition policy: an unfilled vacancy must never carry revenue.
-- This asserts the business rule itself, independently of the macro that
-- implements it — so a change to the macro cannot silently change the policy.

select
    vacancy_id,
    vacancy_status,
    is_filled,
    annual_contract_value_usd
from {{ ref('fct_vacancies') }}
where not is_filled
  and annual_contract_value_usd <> 0
