-- int_journey_enriched.sql
-- Objective: Enrich the raw journey funnel with stage-to-stage timing and a
-- single "furthest stage reached" classification per member.
-- Demonstrates: date functions, nested CASE WHEN, defensive NULL handling.

with journey as (

    select * from {{ ref('stg_member_journey') }}

),

with_timing as (

    select
        *,
        date_diff('day', invited_date, scheduled_date)        as days_invite_to_schedule,
        date_diff('day', scheduled_date, first_completed_date) as days_schedule_to_first_session,
        date_diff('day', first_completed_date, engaged_date)   as days_first_session_to_engaged,
        date_diff('day', engaged_date, assessed_date)          as days_engaged_to_assessed,
        date_diff('day', enrolled_date, assessed_date)         as days_enrolled_to_assessed

    from journey

),

with_furthest_stage as (

    select
        *,
        -- Ordinal funnel stage -- used for funnel drop-off charts and for
        -- ranking members by how far they progressed
        case
            when reached_assessed       then 5
            when reached_engaged        then 4
            when reached_first_session  then 3
            when reached_scheduled      then 2
            else 1
        end                                                    as funnel_stage_number,
        case
            when reached_assessed       then 'Assessed'
            when reached_engaged        then 'Engaged (3+ sessions)'
            when reached_first_session  then 'Completed First Session'
            when reached_scheduled      then 'Scheduled Only'
            else 'Enrolled Only'
        end                                                    as furthest_stage_reached

    from with_timing

)

select * from with_furthest_stage
