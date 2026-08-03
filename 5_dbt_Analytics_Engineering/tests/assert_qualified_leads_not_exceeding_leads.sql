-- Funnel integrity: qualified leads are a subset of leads, so they can never
-- exceed them. A violation means the source feed is misaligned, and every
-- conversion rate built on top of it is wrong.

select
    spend_date,
    marketing_channel,
    leads,
    qualified_leads
from {{ ref('stg_marketing_leads') }}
where qualified_leads > leads
