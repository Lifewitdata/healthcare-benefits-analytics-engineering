-- rpt_funnel_summary.sql
-- Grain: 1 row per client (plus an 'ALL' overall row via UNION ALL).
-- The core table for the member-journey dashboard's funnel chart --
-- shows count and conversion rate at each stage.
-- Demonstrates: CASE WHEN, aggregate functions, UNION ALL for grand total.

with fmj as (
    select * from {{ ref('fact_member_journey') }}
),

clients as (
    select client_id, client_name from {{ ref('dim_clients') }}
),

by_client as (

    select
        c.client_id,
        c.client_name,
        count(fmj.member_id)                                              as n_enrolled,
        sum(case when fmj.reached_scheduled then 1 else 0 end)            as n_scheduled,
        sum(case when fmj.reached_first_session then 1 else 0 end)        as n_completed_first_session,
        sum(case when fmj.reached_engaged then 1 else 0 end)              as n_engaged,
        sum(case when fmj.reached_assessed then 1 else 0 end)             as n_assessed

    from clients as c
    left join fmj on c.client_id = fmj.client_id
    group by c.client_id, c.client_name

),

overall as (

    select
        cast(null as varchar)   as client_id,
        'ALL CLIENTS'            as client_name,
        count(member_id)                                              as n_enrolled,
        sum(case when reached_scheduled then 1 else 0 end)            as n_scheduled,
        sum(case when reached_first_session then 1 else 0 end)        as n_completed_first_session,
        sum(case when reached_engaged then 1 else 0 end)              as n_engaged,
        sum(case when reached_assessed then 1 else 0 end)             as n_assessed

    from fmj

),

unioned as (

    select * from by_client
    union all
    select * from overall

),

with_rates as (

    select
        *,
        round(100.0 * n_scheduled / nullif(n_enrolled, 0), 1)                    as pct_scheduled,
        round(100.0 * n_completed_first_session / nullif(n_scheduled, 0), 1)     as pct_scheduled_to_completed,
        round(100.0 * n_engaged / nullif(n_completed_first_session, 0), 1)       as pct_completed_to_engaged,
        round(100.0 * n_assessed / nullif(n_engaged, 0), 1)                      as pct_engaged_to_assessed,
        round(100.0 * n_assessed / nullif(n_enrolled, 0), 1)                     as overall_completion_rate

    from unioned

)

select * from with_rates
