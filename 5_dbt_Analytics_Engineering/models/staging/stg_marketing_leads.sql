with source as (

    select * from {{ ref('marketing_leads') }}

),

renamed as (

    select
        date          as spend_date,
        channel       as marketing_channel,
        ad_spend_usd,
        leads,
        qualified_leads,
        client_meetings,
        deals_closed

    from source

)

select * from renamed
