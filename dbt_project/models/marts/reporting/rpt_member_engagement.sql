-- rpt_member_engagement.sql
-- Grain: 1 row per member. Segments members into engagement tiers for
-- "which members are highly engaged" reporting.
-- Demonstrates: CASE WHEN segmentation logic, window/ranking functions.

with fmj as (
    select * from {{ ref('fact_member_journey') }}
),

segmented as (

    select
        member_id,
        client_id,
        total_sessions,
        total_cost,
        utilization_rate,
        furthest_stage_reached,
        case
            when total_sessions = 0                    then 'Never Engaged'
            when total_sessions between 1 and 2         then 'Low Engagement'
            when total_sessions between 3 and 5         then 'Engaged'
            when total_sessions >= 6                    then 'Highly Engaged'
        end                                              as engagement_tier

    from fmj

),

ranked as (

    select
        *,
        rank() over (order by total_sessions desc) as session_count_rank

    from segmented

)

select * from ranked
