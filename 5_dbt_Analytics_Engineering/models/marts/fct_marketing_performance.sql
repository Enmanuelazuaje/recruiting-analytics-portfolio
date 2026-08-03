-- Marketing efficiency by channel and month. Every ratio is guarded with
-- nullif so a channel with zero spend or zero leads returns null rather than
-- failing the run or reporting a misleading zero.

with leads as (

    select * from {{ ref('stg_marketing_leads') }}

),

by_channel_month as (

    select
        marketing_channel,
        date_trunc('month', spend_date)     as spend_month,

        sum(ad_spend_usd)                   as ad_spend_usd,
        sum(leads)                          as leads,
        sum(qualified_leads)                as qualified_leads,
        sum(client_meetings)                as client_meetings,
        sum(deals_closed)                   as deals_closed

    from leads
    group by 1, 2

)

select
    marketing_channel,
    spend_month,
    ad_spend_usd,
    leads,
    qualified_leads,
    client_meetings,
    deals_closed,

    round(ad_spend_usd / nullif(leads, 0), 2)           as cost_per_lead_usd,
    round(ad_spend_usd / nullif(deals_closed, 0), 2)    as cost_per_deal_usd,

    round(100.0 * qualified_leads / nullif(leads, 0), 1) as lead_qualification_rate_pct,
    round(100.0 * deals_closed / nullif(qualified_leads, 0), 1) as qualified_to_deal_rate_pct

from by_channel_month
