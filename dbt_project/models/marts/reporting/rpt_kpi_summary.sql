-- rpt_kpi_summary.sql
-- Grain: 1 row. Org-wide headline KPIs for a top-level dashboard tile row.
-- Demonstrates: aggregate functions across multiple source facts, CASE WHEN
-- for conditional rates, subqueries for cross-fact counts.

with fmj as (
    select * from {{ ref('fact_member_journey') }}
),

fs as (
    select * from {{ ref('fact_sessions') }}
),

clients as (
    select * from {{ ref('dim_clients') }}
)

select
    (select count(*) from clients)                                          as total_clients,
    count(*)                                                                as total_members,
    (select count(*) from fs)                                               as total_sessions,
    sum(fmj.total_cost)                                                     as total_healthcare_cost,
    round(sum(fmj.total_cost) / nullif(count(*), 0), 2)                     as avg_cost_per_member,
    round(sum(fmj.total_sessions)::decimal / nullif(count(*), 0), 2)        as avg_sessions_per_member,
    round(avg(fmj.utilization_rate), 3)                                     as overall_utilization_rate,

    -- PHQ-9 / GAD-7 improvement rates: of members WITH a completed follow-up
    round(
        sum(case when fmj.phq9_improved then 1 else 0 end)::decimal
        / nullif(sum(case when fmj.phq9_has_followup then 1 else 0 end), 0), 3
    )                                                                        as phq9_improvement_rate,
    round(
        sum(case when fmj.gad7_improved then 1 else 0 end)::decimal
        / nullif(sum(case when fmj.gad7_has_followup then 1 else 0 end), 0), 3
    )                                                                        as gad7_improvement_rate,

    round(
        sum(case when fmj.phq9_has_followup then 1 else 0 end)::decimal
        / nullif(sum(case when fmj.reached_engaged then 1 else 0 end), 0), 3
    )                                                                        as followup_completion_rate,

    -- Journey completion rate: reached "Assessed" as a share of all enrolled
    round(
        sum(case when fmj.reached_assessed then 1 else 0 end)::decimal
        / nullif(count(*), 0), 3
    )                                                                        as journey_completion_rate

from fmj
