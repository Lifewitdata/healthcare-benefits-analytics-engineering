# FHIR Bundle Demonstration Import

## Purpose

The repository includes a small demonstration importer for a FHIR JSON Bundle. It maps a limited subset of Patient, Encounter and Observation resources into flat CSV extracts for downstream analytics.

| FHIR resource | Output | Selected fields |
|---|---|---|
| Patient | patients.csv | id, gender, birth_date |
| Encounter | encounters.csv | id, patient_id, status, start, end |
| Observation | observations.csv | id, patient_id, status, code, display, date, value, unit |

## Run

```bash
python scripts/fhir_demo_import.py
```

Output is written to `build/fhir_normalized/`, including a reconciliation JSON file with record counts and patient-reference status. You can override input and output paths with `--input` and `--output-dir`.

## Validation performed

- Confirms the input is a Bundle with entries.
- Checks identifiers are present and unique within each supported resource type.
- Checks Encounter and Observation subject references point to a Patient included in the same Bundle.
- Produces normalized extracts and a simple count reconciliation report.

## Important limitations

This is an educational subset importer, not a complete FHIR R4 validator and not a claim of FHIR conformance. It does not validate profiles, terminology bindings, all cardinalities, extensions, security labels, Provenance, consent, transaction semantics or server interactions. It does not connect to an EHR, payer, claims system or FHIR endpoint. It does not implement HL7 v2.

All sample data is generated for demonstration. A production implementation needs approved source mappings, a full standards validator, terminology governance, secure access controls, audit trails, privacy review and PHI-safe observability.
