-- rpt_industry_summary.sql
-- Grain: 1 row per industry. Rolls client-level data up one more level.
-- Demonstrates: aggregate functions, joins, subqueries in SELECT.

with fmj as (
    select * from {{ ref('fact_member_journey') }}
),

clients as (
    select * from {{ ref('dim_clients') }}
)

select
    c.industry,
    count(distinct c.client_id)                                        as n_clients,
    count(fmj.member_id)                                               as n_members,
    sum(fmj.total_cost)                                                as total_cost,
    round(sum(fmj.total_cost) / nullif(count(fmj.member_id), 0), 2)    as cost_per_member,
    round(avg(fmj.utilization_rate), 3)                                as avg_utilization_rate,
    round(
        sum(case when fmj.phq9_improved then 1 else 0 end)::decimal
        / nullif(sum(case when fmj.phq9_has_followup then 1 else 0 end), 0), 3
    )                                                                    as phq9_improvement_rate

from clients as c
left join fmj on c.client_id = fmj.client_id
group by c.industry
order by total_cost desc
