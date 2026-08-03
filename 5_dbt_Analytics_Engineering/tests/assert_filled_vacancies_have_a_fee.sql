-- A filled vacancy must always carry a monthly fee — that is the placement
-- being paid for. Open and cancelled vacancies legitimately have none.
--
-- This test replaced a blanket not_null on monthly_fee_usd. That version
-- failed on 407 rows, and the rows were correct: the assumption was wrong,
-- not the data. The rule the business actually holds is conditional, so the
-- test is conditional too. Tightening a test until it passes teaches you
-- nothing; correcting it to match reality is the point.

select
    vacancy_id,
    vacancy_status,
    monthly_fee_usd
from {{ ref('stg_vacancies') }}
where is_filled
  and monthly_fee_usd is null
