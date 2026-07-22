-- fact_member_journey.sql
-- Grain: 1 row per member. This is the primary business-ready fact table --
-- intentionally wide (a common, deliberate pattern for reporting-layer
-- facts) so that client-facing dashboards can query one table instead of
-- joining 4-5 tables for every report. Combines: funnel progression,
-- session/cost aggregates, and clinical outcome changes for both
-- instruments.

with journey as (

    select * from {{ ref('int_journey_enriched') }}

),

session_agg as (

    select * from {{ ref('int_member_session_agg') }}

),

-- Re-pivot assessment data from (member, instrument) grain to
-- (member) grain -- PHQ-9 and GAD-7 side by side as columns.
assessments_wide as (

    select
        member_id,
        max(case when assessment_type = 'PHQ-9' then baseline_score end)  as phq9_baseline,
        max(case when assessment_type = 'PHQ-9' then followup_score end)  as phq9_followup,
        max(case when assessment_type = 'PHQ-9' then score_change end)    as phq9_change,
        max(case when assessment_type = 'PHQ-9' then has_followup end)    as phq9_has_followup,
        max(case when assessment_type = 'PHQ-9' then improved end)        as phq9_improved,
        max(case when assessment_type = 'GAD-7' then baseline_score end)  as gad7_baseline,
        max(case when assessment_type = 'GAD-7' then followup_score end)  as gad7_followup,
        max(case when assessment_type = 'GAD-7' then score_change end)    as gad7_change,
        max(case when assessment_type = 'GAD-7' then has_followup end)    as gad7_has_followup,
        max(case when assessment_type = 'GAD-7' then improved end)        as gad7_improved

    from {{ ref('int_assessment_pivoted') }}
    group by member_id

),

members as (

    select member_id, client_id, sessions_per_member_allowance
    from {{ ref('stg_members') }}

),

joined as (

    select
        mem.member_id,
        mem.client_id,

        -- Journey / funnel
        j.enrolled_date,
        j.invited_date,
        j.scheduled_date,
        j.first_completed_date,
        j.engaged_date,
        j.assessed_date,
        j.reached_scheduled,
        j.reached_first_session,
        j.reached_engaged,
        j.reached_assessed,
        j.funnel_stage_number,
        j.furthest_stage_reached,
        j.days_invite_to_schedule,
        j.days_schedule_to_first_session,
        j.days_first_session_to_engaged,
        j.days_engaged_to_assessed,
        j.days_enrolled_to_assessed,

        -- Session / cost aggregates (0/NULL for members who never had a session)
        coalesce(sa.total_sessions, 0)              as total_sessions,
        coalesce(sa.total_cost, 0)                  as total_cost,
        sa.avg_cost_per_session,
        sa.dominant_modality,
        mem.sessions_per_member_allowance,
        round(
            coalesce(sa.total_sessions, 0)::decimal / nullif(mem.sessions_per_member_allowance, 0),
            3
        )                                             as utilization_rate,

        -- Clinical outcomes
        aw.phq9_baseline, aw.phq9_followup, aw.phq9_change, aw.phq9_has_followup, aw.phq9_improved,
        aw.gad7_baseline, aw.gad7_followup, aw.gad7_change, aw.gad7_has_followup, aw.gad7_improved

    from members as mem
    left join journey as j            on mem.member_id = j.member_id
    left join session_agg as sa       on mem.member_id = sa.member_id
    left join assessments_wide as aw  on mem.member_id = aw.member_id

)

select * from joined
