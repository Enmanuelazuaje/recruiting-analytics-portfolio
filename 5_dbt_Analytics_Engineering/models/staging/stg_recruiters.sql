with source as (

    select * from {{ ref('recruiters') }}

),

renamed as (

    select
        recruiter_id,
        recruiter_name,
        team,
        country       as recruiter_country,
        hire_date     as recruiter_hire_date

    from source

)

select * from renamed
