-- stg_members.sql
-- Objective: 1:1 cleanup of the raw members seed.

with source as (

    select * from {{ ref('members') }}

),

renamed as (

    select
        trim(member_id)                    as member_id,
        trim(client_id)                    as client_id,
        {{ title_case('trim(department)') }}   as department,
        cast(sessions_per_member_allowance as integer) as sessions_per_member_allowance,
        cast(enrollment_date as date)      as enrollment_date

    from source

)

select * from renamed
