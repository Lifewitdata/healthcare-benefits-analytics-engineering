# Source Data Contracts

The project uses five committed demonstration CSV inputs under `data/`.
The contracts are checked by `scripts/data_quality.py` before dbt runs.

| Source | Declared grain | Primary key | Important checks |
|---|---|---|---|
| clients.csv | One row per client | client_id | Required attributes, unique identifier |
| members.csv | One row per member | member_id | Client reference, enrollment date, allowance |
| sessions.csv | One row per service session | session_id | Member reference, date, non-negative cost |
| assessments.csv | One row per assessment event | assessment_id | Member reference, instrument-specific score range |
| member_journey.csv | One row per member journey | member_id | Client reference and funnel stage flags |

## Data quality dimensions

- **Completeness:** required columns and key values must be present.
- **Uniqueness:** declared primary keys must not repeat.
- **Referential integrity:** member and client references must resolve.
- **Validity:** session costs must be non-negative; PHQ-9 scores must be 0–27 and GAD-7 scores 0–21.
- **Reproducibility:** the same committed inputs and pinned dependencies should produce the same analytical outputs.

## Production extension

For a real multi-source healthcare environment, each source adapter should record source system, extract timestamp, source file or batch identifier, schema version, row count, rejected-row count and processing status. Add quarantine handling rather than silently dropping invalid records. Do not place PHI in logs or CI artifacts.

The included files are generated demonstration data. The project does not connect to an EHR, payer, claims clearinghouse or live FHIR endpoint.
