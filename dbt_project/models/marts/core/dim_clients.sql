-- dim_clients.sql
-- Grain: 1 row per employer client. Natural key (client_id) used as PK --
-- no surrogate key needed since the source system's ID is already stable
-- and unique.

select
    client_id,
    client_name,
    industry,
    plan_tier,
    employee_count,
    contract_start_date,
    sessions_per_member_allowance

from {{ ref('stg_clients') }}
