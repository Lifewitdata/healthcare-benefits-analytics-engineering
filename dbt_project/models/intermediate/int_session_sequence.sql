-- int_session_sequence.sql
-- Objective: Number each member's sessions in chronological order.
-- Demonstrates: window functions (ROW_NUMBER, LAG) for sequencing and
-- computing the gap between consecutive sessions -- useful downstream for
-- engagement-cadence analysis (e.g. "members with >21 day gaps churn more").

with sessions as (

    select * from {{ ref('stg_sessions') }}

),

sequenced as (

    select
        session_id,
        member_id,
        session_date,
        session_type,
        cost_usd,
        row_number() over (
            partition by member_id
            order by session_date, session_id
        )                                                          as session_number,
        lag(session_date) over (
            partition by member_id
            order by session_date, session_id
        )                                                          as previous_session_date

    from sessions

),

with_gap as (

    select
        *,
        date_diff('day', previous_session_date, session_date)      as days_since_previous_session

    from sequenced

)

select * from with_gap
