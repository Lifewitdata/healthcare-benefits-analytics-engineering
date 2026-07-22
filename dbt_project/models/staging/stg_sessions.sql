-- stg_sessions.sql
-- Objective: 1:1 cleanup of the raw sessions seed.
-- Rounds cost to 2 decimal places (currency standardization) and
-- standardizes session_type casing to guard against upstream drift.

with source as (

    select * from {{ ref('sessions') }}

),

renamed as (

    select
        trim(session_id)                       as session_id,
        trim(member_id)                        as member_id,
        cast(session_date as date)             as session_date,
        {{ title_case('trim(session_type)') }} as session_type,
        cast(duration_min as integer)          as duration_min,
        round(cast(cost_usd as decimal(10,2)), 2) as cost_usd

    from source

)

select * from renamed
