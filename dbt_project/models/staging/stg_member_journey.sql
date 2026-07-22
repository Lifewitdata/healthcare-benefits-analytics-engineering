-- stg_member_journey.sql
-- Objective: 1:1 cleanup of the raw member_journey seed.
-- Casts boolean flags explicitly (DuckDB infers these correctly from seed,
-- but explicit casting protects against future source changes e.g. if this
-- ever lands as 'TRUE'/'FALSE' strings from a different EL tool).

with source as (

    select * from {{ ref('member_journey') }}

),

renamed as (

    select
        trim(member_id)                         as member_id,
        trim(client_id)                         as client_id,
        cast(enrolled_date as date)             as enrolled_date,
        cast(invited_date as date)              as invited_date,
        cast(scheduled_date as date)            as scheduled_date,
        cast(first_completed_date as date)      as first_completed_date,
        cast(engaged_date as date)              as engaged_date,
        cast(assessed_date as date)             as assessed_date,
        cast(reached_scheduled as boolean)      as reached_scheduled,
        cast(reached_first_session as boolean)  as reached_first_session,
        cast(reached_engaged as boolean)        as reached_engaged,
        cast(reached_assessed as boolean)       as reached_assessed

    from source

)

select * from renamed
