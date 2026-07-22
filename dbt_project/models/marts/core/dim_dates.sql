-- dim_dates.sql
-- Grain: 1 row per calendar day, spanning the full range of dates present
-- across sessions, journey events, and assessments (with a small buffer).
-- Built dynamically off the data itself rather than hardcoded bounds, so
-- it stays correct as new data is loaded.

with date_bounds as (

    select
        min(d) as min_date,
        max(d) as max_date
    from (
        select session_date       as d from {{ ref('stg_sessions') }}
        union all
        select enrolled_date      as d from {{ ref('stg_member_journey') }}
        union all
        select assessed_date      as d from {{ ref('stg_member_journey') }} where assessed_date is not null
        union all
        select assessment_date    as d from {{ ref('stg_assessments') }}
    )

),

date_spine as (

    select unnest(
        generate_series(
            (select min_date from date_bounds),
            (select max_date from date_bounds),
            interval 1 day
        )
    )::date as date_day

),

enriched as (

    select
        date_day,
        extract(year from date_day)                    as year,
        extract(month from date_day)                    as month,
        extract(day from date_day)                       as day_of_month,
        extract(dow from date_day)                        as day_of_week,
        strftime(date_day, '%A')                           as day_name,
        strftime(date_day, '%B')                            as month_name,
        date_trunc('month', date_day)::date                  as month_start_date,
        date_trunc('week', date_day)::date                    as week_start_date,
        case when extract(dow from date_day) in (0, 6)
             then true else false end                          as is_weekend

    from date_spine

)

select * from enriched
