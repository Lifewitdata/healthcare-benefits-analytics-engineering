-- rpt_provider_utilization.sql
-- Grain: 1 row per session_type ("provider type" -- see project README for
-- the naming note: this dataset models provider type via session_type,
-- since no separate provider dimension exists in source data).
-- Demonstrates: aggregate functions, window functions for share-of-total.

with fs as (
    select * from {{ ref('fact_sessions') }}
),

by_type as (

    select
        session_type,
        count(*)              as n_sessions,
        sum(cost_usd)          as total_cost,
        round(avg(cost_usd), 2) as avg_cost_per_session,
        count(distinct member_id) as n_unique_members

    from fs
    group by session_type

),

with_share as (

    select
        *,
        round(100.0 * n_sessions / sum(n_sessions) over (), 1)   as pct_of_total_sessions,
        round(100.0 * total_cost / sum(total_cost) over (), 1)   as pct_of_total_cost

    from by_type

)

select * from with_share
order by n_sessions desc
