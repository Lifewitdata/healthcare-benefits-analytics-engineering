-- rpt_client_scorecard.sql
-- Grain: 1 row per client. The core client-facing report -- cost,
-- utilization, and clinical improvement, ranked for easy "top N" queries.
-- Demonstrates: window/ranking functions (RANK), joins, CASE WHEN.

with fmj as (
    select * from {{ ref('fact_member_journey') }}
),

clients as (
    select * from {{ ref('dim_clients') }}
),

client_agg as (

    select
        c.client_id,
        c.client_name,
        c.industry,
        c.plan_tier,
        count(fmj.member_id)                                             as n_members,
        sum(fmj.total_sessions)                                          as total_sessions,
        sum(fmj.total_cost)                                              as total_cost,
        round(sum(fmj.total_cost) / nullif(count(fmj.member_id), 0), 2)  as avg_cost_per_member,
        round(avg(fmj.utilization_rate), 3)                              as avg_utilization_rate,
        sum(case when fmj.reached_assessed then 1 else 0 end)            as n_assessed,
        round(
            sum(case when fmj.phq9_improved then 1 else 0 end)::decimal
            / nullif(sum(case when fmj.phq9_has_followup then 1 else 0 end), 0), 3
        )                                                                  as phq9_improvement_rate,
        round(
            sum(case when fmj.gad7_improved then 1 else 0 end)::decimal
            / nullif(sum(case when fmj.gad7_has_followup then 1 else 0 end), 0), 3
        )                                                                  as gad7_improvement_rate

    from clients as c
    left join fmj on c.client_id = fmj.client_id
    group by c.client_id, c.client_name, c.industry, c.plan_tier

),

ranked as (

    select
        *,
        rank() over (order by avg_utilization_rate desc) as utilization_rank,
        rank() over (order by avg_cost_per_member desc)   as cost_per_member_rank

    from client_agg

)

select * from ranked
