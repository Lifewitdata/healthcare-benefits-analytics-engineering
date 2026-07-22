-- stg_assessments.sql
-- Objective: 1:1 cleanup of the raw assessments seed.
-- Enforces valid clinical score ranges as a defensive cast-time guard
-- (the actual capping/correction already happened upstream in Section 2's
-- data generation; this CASE is a safety net if raw data ever changes).

with source as (

    select * from {{ ref('assessments') }}

),

renamed as (

    select
        trim(assessment_id)                as assessment_id,
        trim(member_id)                    as member_id,
        trim(assessment_type)              as assessment_type,
        trim(timepoint)                    as timepoint,
        cast(assessment_date as date)      as assessment_date,
        case
            when assessment_type = 'PHQ-9' then least(greatest(cast(score as integer), 0), 27)
            when assessment_type = 'GAD-7' then least(greatest(cast(score as integer), 0), 21)
            else cast(score as integer)
        end                                 as score

    from source

)

select * from renamed
