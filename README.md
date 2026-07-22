# Modern Health: Client-Facing ROI & Member Journey Dashboard

A SQL + dbt analytics engineering project — built on **DuckDB** (a local,
embedded SQL warehouse) so anyone can clone this repo and run the full
pipeline with zero cloud credentials.

> **Synthetic data notice:** All data is generated to mirror the structure of
> a real B2B mental-health-benefits program. No real member or clinical data
> is used.

---

## What This Project Demonstrates

- A complete dbt project: **seeds → staging → intermediate → marts (core +
  reporting)**
- A proper **star schema** (`dim_clients`, `dim_members`, `dim_assessments`,
  `dim_dates`, `fact_sessions`, `fact_member_journey`)
- **129 dbt tests** across every layer (`unique`, `not_null`,
  `accepted_values`, `relationships`)
- A custom **macro** (`title_case`), written to solve a real problem (DuckDB
  has no `initcap`), not added for show
- **Window functions** (`ROW_NUMBER`, `LAG`, `RANK`), **CTEs**, conditional
  aggregation **pivots**, and `UNION ALL` grand-total patterns
- Six **business-ready reporting marts** answering the exact KPIs and
  business questions a Modern Health Analytics team would be asked for

---

## Architecture

```
Raw CSVs (data/)
      │
      ▼
  dbt SEED   →  raw schema (5 tables, DuckDB)
      │
      ▼
  STAGING    →  stg_clients, stg_members, stg_sessions,
                stg_assessments, stg_member_journey
      │
      ▼
  INTERMEDIATE → int_member_session_agg, int_session_sequence,
                 int_assessment_pivoted, int_journey_enriched
      │
      ▼
  MARTS / CORE     → dim_clients, dim_members, dim_assessments,
                      dim_dates, fact_sessions, fact_member_journey
      │
      ▼
  MARTS / REPORTING → rpt_kpi_summary, rpt_client_scorecard,
                       rpt_industry_summary, rpt_provider_utilization,
                       rpt_member_engagement, rpt_funnel_summary
```

## Key Finding: The Member Journey Funnel

```
Enrolled (2,500) → Scheduled (73.3%) → Completed 1st Session (92.0%)
→ Engaged/3+ sessions (54.1%) → Assessed (80.4%)

Overall journey completion rate: 29.3%
```

**The biggest drop-off is post-first-session** (Completed → Engaged, 54.1%
conversion) — not enrollment or scheduling. This points to first-session
experience quality as the highest-leverage intervention point, not top-of-
funnel awareness.

## Headline KPIs (`rpt_kpi_summary`)

| KPI | Value |
|---|---|
| Total Clients | 12 |
| Total Members | 2,500 |
| Total Sessions | 7,239 |
| Total Healthcare Cost | $689,736 |
| Avg Cost per Member | $275.89 |
| Overall Utilization Rate | 37.9% |
| PHQ-9 Improvement Rate | 74.5% |
| GAD-7 Improvement Rate | 75.8% |
| Journey Completion Rate | 29.3% |

---

## How to Run

```bash
# Install dependencies
pip install dbt-core dbt-duckdb

# From the dbt_project/ directory
export DBT_PROFILES_DIR=$(pwd)

dbt seed          # load raw CSVs into DuckDB
dbt run           # build staging -> intermediate -> marts
dbt test          # run all 129 data quality tests
dbt docs generate # build the lineage graph + model catalog
dbt docs serve    # view it in your browser
```

This creates a local `modern_health.duckdb` file — the entire warehouse in
one portable file. Query it directly with any DuckDB client, or point a BI
tool (Metabase, Evidence, even Tableau via ODBC) at the `main_reporting`
schema.

---

## Repository Structure

```
dbt_project/
├── seeds/                          # raw CSVs + seed_properties.yml (docs+tests)
├── models/
│   ├── staging/                    # stg_* -- 1:1 cleanup, no business logic
│   ├── intermediate/               # int_* -- aggregation, pivots, enrichment
│   └── marts/
│       ├── core/                   # dim_*, fact_* -- the star schema
│       └── reporting/              # rpt_* -- BI-tool-ready business marts
├── macros/                         # title_case.sql
├── dbt_project.yml
└── profiles.yml                    # local DuckDB connection

data/                                # source CSVs (also copied into seeds/)
scripts/
└── 01_generate_data.R               # regenerates the synthetic dataset
```

---

## Design Decisions Worth Knowing

- **DuckDB, not a cloud warehouse** — makes this runnable by anyone who
  clones the repo, no Snowflake/BigQuery account needed. Same SQL/dbt
  skillset transfers directly to a cloud warehouse.
- **`dim_assessments` is a reference dimension**, not a per-event log —
  actual member outcome scores live in `fact_member_journey` (member grain),
  since that's the natural home for outcome data.
- **`fact_member_journey` is intentionally wide** — a deliberate "one big
  table" tradeoff so client dashboards query one table instead of joining
  four.
- **"Provider type" is modeled via `session_type`** (Coaching/Therapy/
  Psychiatry), since no separate provider dimension exists in source data.

## Limitations

- Synthetic data — illustrates the analytics engineering method, not real
  program performance.
- Small client count (n=12) — client- and industry-level findings are
  directional, not statistically robust.
- No incremental models — with this data volume, full-refresh tables are
  appropriate; a real production version with growing session data would
  make `fact_sessions` incremental.

---

*Built as a portfolio project demonstrating SQL + dbt analytics engineering
best practices, relevant to a Data Analyst role on a healthcare benefits
Analytics team.*
