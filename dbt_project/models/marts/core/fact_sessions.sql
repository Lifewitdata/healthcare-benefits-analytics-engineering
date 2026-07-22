-- fact_sessions.sql
-- Grain: 1 row per session (matches source grain exactly -- a transaction
-- fact table, the most granular level available).

select
    seq.session_id,
    seq.member_id,
    mem.client_id,
    seq.session_date,
    seq.session_type,
    seq.cost_usd,
    seq.session_number,
    seq.previous_session_date,
    seq.days_since_previous_session

from {{ ref('int_session_sequence') }} as seq
left join {{ ref('stg_members') }} as mem
    on seq.member_id = mem.member_id
