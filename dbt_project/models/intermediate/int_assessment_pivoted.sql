-- int_assessment_pivoted.sql
-- Objective: Pivot assessments from long format (1 row per timepoint) to
-- wide format (1 row per member per instrument, baseline + follow-up as
-- columns). Demonstrates: conditional aggregation pivot pattern, CASE WHEN,
-- date functions.

with assessments as (

    select * from {{ ref('stg_assessments') }}

),

pivoted as (

    select
        member_id,
        assessment_type,
        max(case when timepoint = 'baseline'  then score           end) as baseline_score,
        max(case when timepoint = 'follow_up' then score           end) as followup_score,
        max(case when timepoint = 'baseline'  then assessment_date end) as baseline_date,
        max(case when timepoint = 'follow_up' then assessment_date end) as followup_date

    from assessments
    group by member_id, assessment_type

),

enriched as (

    select
        *,
        followup_score is not null                                     as has_followup,
        followup_score - baseline_score                                 as score_change,
        case
            when followup_score is not null and followup_score < baseline_score
                then true
            when followup_score is not null
                then false
            else null  -- no follow-up completed -- unknown, not "did not improve"
        end                                                              as improved,
        date_diff('day', baseline_date, followup_date)                   as days_to_followup

    from pivoted

)

select * from enriched
