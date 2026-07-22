-- stg_clients.sql
-- Objective: 1:1 cleanup of the raw clients seed. No joins, no aggregation.
-- Standardizes text casing, trims whitespace, casts types explicitly.

with source as (

    select * from {{ ref('clients') }}

),

renamed as (

    select
        trim(client_id)                        as client_id,
        trim(client_name)                       as client_name,
        {{ title_case('trim(industry)') }}      as industry,
        {{ title_case('trim(plan_tier)') }}     as plan_tier,
        cast(employee_count as integer)         as employee_count,
        cast(contract_start_date as date)       as contract_start_date,
        cast(sessions_per_member_allowance as integer) as sessions_per_member_allowance

    from source

)

select * from renamed
