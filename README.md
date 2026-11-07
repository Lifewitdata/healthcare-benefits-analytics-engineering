# Healthcare Data Integration & Population Health Analytics

[![Analytics Engineering CI](https://github.com/Lifewitdata/healthcare-benefits-analytics-engineering/actions/workflows/ci.yml/badge.svg?branch=innovaccer-data-analyst-build)](https://github.com/Lifewitdata/healthcare-benefits-analytics-engineering/actions)

A reproducible healthcare analytics engineering portfolio project aligned with a Data Analyst role focused on healthcare data integration, data quality, warehouse modelling, population health insights and cost/utilisation reporting.

> **Data and privacy notice:** All included records are generated demonstration data. No real patient, member or clinical records are used. This is not a production clinical system and does not claim HIPAA certification, FHIR conformance or live EHR connectivity.

## Business problem

Healthcare customers need to combine information from different operational systems, trust the quality of the resulting data, and use clear reporting to understand population health, service utilisation, member engagement and programme costs.

This project demonstrates a small but end-to-end version of that workflow: validate incoming source extracts, load them into a warehouse, transform them into reusable dimensional models, test the results and publish reporting-ready datasets.

## What the solution delivers

- **Multi-source data preparation:** five structured source feeds representing clients, members, service sessions, assessments and member journeys.
- **Data quality controls:** source contracts for required columns, unique keys, referential integrity, non-negative costs and valid PHQ-9/GAD-7 score ranges.
- **Healthcare analytics warehouse:** DuckDB with dbt seed, staging, intermediate, core and reporting layers.
- **Dimensional modelling:** member- and session-grain facts plus reusable dimensions and reporting marts.
- **Population health reporting:** engagement funnel, follow-up completion, PHQ-9/GAD-7 score movement, utilisation, service mix and cost per member.
- **Automated validation:** Python tests, dbt tests and GitHub Actions CI.
- **Reproducible execution:** pinned Python dependencies, Makefile commands and a local warehouse; no cloud credentials required.

## Architecture

```text
Healthcare source extracts (CSV demonstration feeds)
        |
        v
Python source data contracts
  - schema / required fields
  - primary-key uniqueness
  - referential integrity
  - selected domain constraints
        |
        v
dbt seeds -> DuckDB raw layer
        |
        v
Staging models (standardise and type source fields)
        |
        v
Intermediate models
  - member session aggregation
  - chronological session sequencing
  - assessment pivot and score movement
  - member journey enrichment
        |
        v
Core dimensional marts
  - dim_clients / dim_members / dim_assessments / dim_dates
  - fact_sessions / fact_member_journey
        |
        v
Reporting marts
  - rpt_kpi_summary
  - rpt_client_scorecard
  - rpt_industry_summary
  - rpt_provider_utilization
  - rpt_member_engagement
  - rpt_funnel_summary
        |
        v
BI-ready reporting / customer-facing analytical outputs
```

## Data sources and grain

| Source | Grain | Primary key | Purpose |
|---|---|---|---|
| clients.csv | One row per client | client_id | Customer/plan context |
| members.csv | One row per member | member_id | Enrolment and allowance context |
| sessions.csv | One row per service session | session_id | Service utilisation and cost |
| assessments.csv | One row per assessment event | assessment_id | PHQ-9/GAD-7 outcome observations |
| member_journey.csv | One row per member journey | member_id | Funnel milestones and engagement |

The files are generated for this portfolio project. They are not sourced from Innovaccer, a provider, payer or real healthcare customer.

## Data quality approach

The pipeline checks data before warehouse transformation. See [Data Contracts](docs/data_contracts.md).

| Dimension | Example control |
|---|---|
| Completeness | Required source columns and non-empty primary keys |
| Uniqueness | No duplicate declared primary keys |
| Referential integrity | Member and client foreign keys resolve |
| Validity | Session costs are non-negative; PHQ-9 range 0–27; GAD-7 range 0–21 |
| Transformation quality | dbt schema and relationship tests |
| Reproducibility | Pinned dependencies and CI pipeline |

Invalid source data causes the quality step to fail instead of silently proceeding. A production-grade implementation should additionally persist rejected records to a quarantine table with batch metadata and PHI-safe error details.

## Analytics questions answered

The reporting marts support questions such as:

1. How many members are enrolled, and how does engagement change through the journey?
2. At which journey stage is the largest member drop-off observed?
3. How many sessions are delivered by service type and client?
4. What is the average programme cost per member and the utilisation rate?
5. What proportion of members with a completed follow-up show a lower PHQ-9 or GAD-7 score than baseline?
6. How do client scorecards and industry-level measures compare?

**Interpretation guardrails:** a lower follow-up score is a descriptive change, not proof that a programme caused the change. Missing follow-up assessments must remain unknown, not be treated as non-improvement. Cost and utilisation metrics are descriptive and do not establish savings or return on investment without a defensible comparison design.

## Technology

- **SQL and dbt:** modular transformations, tests, macros, dimensional modelling and reporting marts.
- **DuckDB:** local analytical warehouse.
- **Python:** source contracts and pipeline execution.
- **pytest:** automated source-contract tests.
- **GitHub Actions:** continuous integration.
- **Tableau / other BI tools:** reporting marts can be consumed by a connected BI tool.

## Quick start

Requires Python 3.10 or newer.

```bash
# 1. Clone the repository
git clone https://github.com/Lifewitdata/healthcare-benefits-analytics-engineering.git
cd healthcare-benefits-analytics-engineering

# 2. Create and activate a virtual environment
python -m venv .venv
# Windows PowerShell:
.venv\Scripts\Activate.ps1
# macOS / Linux:
source .venv/bin/activate

# 3. Install pinned dependencies
python -m pip install -r requirements.txt

# 4. Validate source files
python scripts/data_quality.py

# 5. Build the complete warehouse and run tests
python scripts/run_pipeline.py
```

Equivalent Make commands are available:

```bash
make install
make quality
make build
make docs
```

Run dbt commands directly from the project directory:

```bash
cd dbt_project
dbt seed --full-refresh
dbt run
dbt test
dbt docs generate
dbt docs serve
```

The DuckDB file is created locally and is ignored by Git. The dbt profile reads `DBT_DUCKDB_PATH`; the default file is `modern_health.duckdb`.

## Repository guide

```text
.
├── data/                         # Source demonstration CSV files
├── dbt_project/
│   ├── seeds/                    # dbt seed inputs and seed tests/docs
│   ├── models/
│   │   ├── staging/              # Source standardisation
│   │   ├── intermediate/         # Reusable business transformations
│   │   └── marts/
│   │       ├── core/             # Dimensions and facts
│   │       └── reporting/        # BI-ready reporting models
│   ├── macros/                   # Reusable SQL macros
│   ├── dbt_project.yml
│   └── profiles.yml
├── docs/
│   ├── architecture.md           # Pipeline and warehouse design
│   └── data_contracts.md         # Source-level quality rules
├── scripts/
│   ├── data_quality.py           # Source data contract validation
│   └── run_pipeline.py           # Reproducible pipeline runner
├── tests/                        # Python tests
├── .github/workflows/ci.yml      # Automated validation
├── Makefile
├── requirements.txt
└── README.md
```

## How this maps to the Data Analyst role

| Role responsibility | Evidence in this project |
|---|---|
| Build pipelines from multiple healthcare systems | Five source feeds, Python validation and dbt transformation layers |
| Follow data quality best practices | Source contracts, dbt tests, relationship checks and CI |
| Build digestible healthcare analytics | KPI, client, industry, provider utilisation, engagement and funnel marts |
| Understand data warehousing | DuckDB warehouse, dimensional model, facts, dimensions and documented grains |

## Standards and production-readiness boundaries

The project uses a canonical analytical model that could be extended with adapters for healthcare interoperability formats such as HL7 FHIR. These are future integration targets only: the current repository does **not** parse FHIR resources, process HL7 messages, connect to EHR/claims APIs, or provide a terminology service.

A production deployment would require, at minimum:

- Approved source-system interfaces and documented mapping specifications.
- FHIR/HL7 validation where applicable, code-set governance and identity resolution.
- Secure secrets management, encryption, access controls and audit logging.
- PHI minimisation, retention controls, privacy review and HIPAA compliance assessment.
- Incremental ingestion, schema-drift handling, retry/recovery and batch-level reconciliation.
- Monitoring for freshness, completeness, duplication, latency and failed records.
- Formal metric definitions and customer-specific validation.

See [Architecture](docs/architecture.md) for the detailed design and extension path.

## Current limitations

- Demonstration data only; no real EHR, payer or claims feeds.
- DuckDB is a local warehouse for reproducibility, not a multi-user production platform.
- The project does not implement FHIR/HL7 ingestion or claim regulatory compliance.
- No causal inference: descriptive outcome movement must not be represented as programme impact.
- A production-grade quarantine, orchestration service, dashboard deployment and role-based security layer remain future work.

## Portfolio positioning

**Healthcare Data Integration & Population Health Analytics | Python, SQL, dbt, DuckDB, Data Quality, Dimensional Modelling**

This project is designed to demonstrate the core workflow behind healthcare analytics: preparing data from multiple sources, enforcing quality controls, modelling trusted warehouse datasets and translating them into customer-facing population health and cost insights.
