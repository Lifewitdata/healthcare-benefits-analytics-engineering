"""Lightweight dashboard over the dbt reporting marts.

Run from the repository root after building the warehouse:
    streamlit run dashboard/app.py
"""
from pathlib import Path
import os

import duckdb
import pandas as pd
import plotly.express as px
import streamlit as st

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = Path(os.getenv("DBT_DUCKDB_PATH", ROOT / "dbt_project" / "modern_health.duckdb"))
SCHEMA = os.getenv("DBT_REPORTING_SCHEMA", "main_reporting")

st.set_page_config(page_title="Population Health Analytics", page_icon="🏥", layout="wide")
st.title("Population Health & Healthcare Cost Analytics")
st.caption("Generated demonstration data only · Descriptive analytics, not clinical advice")

if not DB_PATH.exists():
    st.error(f"Warehouse not found: {DB_PATH}. Build it first with python scripts/run_pipeline.py")
    st.stop()

@st.cache_data(ttl=60)
def query(sql: str) -> pd.DataFrame:
    with duckdb.connect(str(DB_PATH), read_only=True) as con:
        return con.execute(sql).df()

def table_exists(name: str) -> bool:
    result = query(
        "SELECT COUNT(*) AS n FROM information_schema.tables WHERE table_schema = ? AND table_name = ?",
    ) if False else None
    with duckdb.connect(str(DB_PATH), read_only=True) as con:
        return con.execute(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_name = ?",
            [SCHEMA, name],
        ).fetchone()[0] > 0

try:
    if not table_exists("rpt_kpi_summary"):
        st.error(f"Reporting mart {SCHEMA}.rpt_kpi_summary not found. Check dbt target schema and run dbt build.")
        st.stop()
    kpi = query(f'SELECT * FROM "{SCHEMA}".rpt_kpi_summary')
    if kpi.empty:
        st.warning("The KPI mart is empty.")
        st.stop()
    row = kpi.iloc[0]
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Members", f"{int(row['total_members']):,}")
    c2.metric("Sessions", f"{int(row['total_sessions']):,}")
    c3.metric("Total cost", f"${row['total_healthcare_cost']:,.0f}")
    c4.metric("Cost / member", f"${row['avg_cost_per_member']:,.2f}")

    c5, c6, c7 = st.columns(3)
    c5.metric("Utilisation", f"{row['overall_utilization_rate']:.1%}")
    c6.metric("PHQ-9 improvement*", f"{row['phq9_improvement_rate']:.1%}")
    c7.metric("GAD-7 improvement*", f"{row['gad7_improvement_rate']:.1%}")

    st.subheader("Member journey funnel")
    funnel = query(f'SELECT * FROM "{SCHEMA}".rpt_funnel_summary')
    st.dataframe(funnel, use_container_width=True, hide_index=True)
    st.caption("*Improvement is lower follow-up score among members with a recorded follow-up. It is not causal evidence or a diagnosis.")

    st.subheader("Client performance")
    clients = query(f'SELECT * FROM "{SCHEMA}".rpt_client_scorecard')
    st.dataframe(clients, use_container_width=True, hide_index=True)

    if {"client_name", "total_cost"}.issubset(clients.columns):
        fig = px.bar(clients, x="client_name", y="total_cost", title="Healthcare programme cost by client")
        st.plotly_chart(fig, use_container_width=True)
except Exception as exc:
    st.exception(exc)
    st.info("Confirm that the dbt reporting schema and selected mart columns match your local build.")
