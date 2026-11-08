# Architecture and Analytics Design

## Pipeline layers

1. **Source layer:** version-controlled demonstration CSVs represent client, member, session, assessment and journey feeds.
2. **Source contract checks:** Python validates file presence, required fields, primary-key uniqueness, referential integrity and selected domain constraints.
3. **Raw layer:** dbt seeds load the source extracts into DuckDB.
4. **Staging:** one model per source performs naming, trimming, casting and defensive validation.
5. **Intermediate:** session aggregation, chronological session sequencing, assessment pivoting and journey enrichment.
6. **Core marts:** dimensions and facts establish reusable analytical grains.
7. **Reporting marts:** client scorecards, funnel summaries, engagement, utilisation, industry and headline KPI outputs.
8. **Consumption:** BI tools or the included Streamlit dashboard query the reporting marts.

## Warehouse design

The project uses a dimensional model with explicit grains. `fact_sessions` is session-grain; `fact_member_journey` is member-grain. Reporting tables are materialised separately to simplify downstream reporting.

## Interoperability roadmap

The canonical model is designed to make future healthcare source adapters explicit. A production implementation could map:
- Patient/member identity to FHIR R4 Patient.
- Service events to FHIR R4 Encounter.
- Clinical assessment observations to FHIR R4 Observation.
- Organisation/client metadata to FHIR R4 Organization.

These are mapping targets only. This repository currently ingests CSV files and does not claim FHIR conformance, HL7 messaging, terminology-service integration or live EHR connectivity.

## Operational controls

The pipeline fails fast on source contract violations, then runs dbt build and tests. GitHub Actions repeats the same checks on pushes and pull requests. Production extensions should add batch-level audit tables, source freshness SLAs, incremental loads, schema drift alerts, retry policies, role-based access and PHI-safe observability.
