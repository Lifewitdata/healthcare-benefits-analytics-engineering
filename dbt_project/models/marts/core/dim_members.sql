-- dim_members.sql
-- Grain: 1 row per member. Contains member attributes only -- client
-- attributes (industry, plan_tier) are NOT denormalized here; BI tools
-- join to dim_clients via client_id, keeping the star schema properly
-- normalized at the dimension level.

select
    member_id,
    client_id,
    department,
    enrollment_date,
    sessions_per_member_allowance

from {{ ref('stg_members') }}
