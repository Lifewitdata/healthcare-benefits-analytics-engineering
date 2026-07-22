-- dim_assessments.sql
-- Grain: 1 row per clinical assessment instrument (PHQ-9, GAD-7).
-- This is a small static REFERENCE dimension describing the instruments
-- themselves (max score, clinical name, category) -- not per-event scores.
-- Per-member outcome data (baseline/follow-up/change) lives in
-- fact_member_journey, since that's member-grain, the natural fact grain
-- for "how did this member's clinical status change."
--
-- Built as hardcoded reference values rather than a seed, since this is
-- true static metadata about the instruments (would not change with new
-- data loads) rather than an extract from an operational system.

select * from (
    values
        ('PHQ-9', 'Patient Health Questionnaire-9', 'Depression', 0, 27,
         'Higher score = more severe depressive symptoms'),
        ('GAD-7', 'Generalized Anxiety Disorder-7', 'Anxiety', 0, 21,
         'Higher score = more severe anxiety symptoms')
) as t(assessment_type, full_name, clinical_category, min_score, max_score, scoring_notes)
