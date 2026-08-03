-- A vacancy cannot be filled before it was opened. Catches source data
-- corruption and timezone/parsing bugs that produce negative days_to_fill.

select
    vacancy_id,
    opened_date,
    filled_date
from {{ ref('stg_vacancies') }}
where filled_date is not null
  and filled_date < opened_date
