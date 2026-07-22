-- int_member_session_agg.sql
-- Objective: Aggregate session-grain data up to member grain.
-- Demonstrates: aggregate functions, CASE WHEN, date functions.

with sessions as (

    select * from {{ ref('stg_sessions') }}

),

member_agg as (

    select
        member_id,
        count(*)                                                       as total_sessions,
        sum(cost_usd)                                                  as total_cost,
        round(avg(cost_usd), 2)                                        as avg_cost_per_session,
        sum(case when session_type = 'Coaching'  then 1 else 0 end)    as n_coaching,
        sum(case when session_type = 'Therapy'   then 1 else 0 end)    as n_therapy,
        sum(case when session_type = 'Psychiatry' then 1 else 0 end)   as n_psychiatry,
        min(session_date)                                              as first_session_date,
        max(session_date)                                              as last_session_date,
        date_diff('day', min(session_date), max(session_date))         as active_span_days

    from sessions
    group by member_id

),

with_dominant_modality as (

    select
        *,
        -- Ties broken deterministically: Coaching > Therapy > Psychiatry
        -- (matches the natural care-pathway order: coaching is the typical
        -- entry point, so it's the reasonable default on a tie)
        case
            when n_coaching >= n_therapy and n_coaching >= n_psychiatry then 'Coaching'
            when n_therapy  >= n_coaching and n_therapy  >= n_psychiatry then 'Therapy'
            else 'Psychiatry'
        end as dominant_modality

    from member_agg

)

select * from with_dominant_modality
