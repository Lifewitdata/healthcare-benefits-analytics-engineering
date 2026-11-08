"""Small, auditable FHIR R4 Bundle-to-analytics demonstration adapter.

Supports a deliberately narrow subset of Patient, Encounter and Observation.
It is not a complete FHIR validator and must not be described as FHIR
conformance certification. It accepts synthetic/demo JSON Bundles only.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SUPPORTED = {"Patient", "Encounter", "Observation"}
OUTPUTS = {
    "Patient": ("patients.csv", ["patient_id", "gender", "birth_date"]),
    "Encounter": ("encounters.csv", ["encounter_id", "patient_id", "status", "class_code", "period_start", "period_end"]),
    "Observation": ("observations.csv", ["observation_id", "patient_id", "status", "code", "display", "effective_date", "value", "unit"]),
}


class FHIRValidationError(ValueError):
    """Raised when the supported FHIR subset fails validation."""


def _required_text(obj: dict[str, Any], key: str, label: str) -> str:
    value = obj.get(key)
    if not isinstance(value, str) or not value.strip():
        raise FHIRValidationError(f"{label}: required non-empty '{key}'")
    return value.strip()


def _date(value: str, label: str) -> str:
    try:
        return date.fromisoformat(value[:10]).isoformat()
    except (TypeError, ValueError):
        raise FHIRValidationError(f"{label}: invalid date/dateTime '{value}'") from None


def _patient_reference(resource: dict[str, Any], label: str) -> str:
    subject = resource.get("subject")
    if not isinstance(subject, dict):
        raise FHIRValidationError(f"{label}: missing subject reference")
    reference = _required_text(subject, "reference", label)
    if not reference.startswith("Patient/"):
        raise FHIRValidationError(f"{label}: subject must reference Patient/<id>")
    return reference.split("/", 1)[1]


def validate_and_normalize(bundle: dict[str, Any]) -> dict[str, list[dict[str, str]]]:
    if bundle.get("resourceType") != "Bundle":
        raise FHIRValidationError("Input resourceType must be Bundle")
    entries = bundle.get("entry")
    if not isinstance(entries, list) or not entries:
        raise FHIRValidationError("Bundle.entry must be a non-empty array")

    normalized = {kind: [] for kind in SUPPORTED}
    seen: dict[str, set[str]] = {kind: set() for kind in SUPPORTED}
    ignored = Counter()

    for index, entry in enumerate(entries):
        resource = entry.get("resource") if isinstance(entry, dict) else None
        if not isinstance(resource, dict):
            raise FHIRValidationError(f"Bundle.entry[{index}] has no resource object")
        kind = resource.get("resourceType")
        if kind not in SUPPORTED:
            ignored[str(kind or "unknown")] += 1
            continue
        label = f"Bundle.entry[{index}] {kind}"
        identifier = _required_text(resource, "id", label)
        if identifier in seen[kind]:
            raise FHIRValidationError(f"{label}: duplicate {kind}.id '{identifier}'")
        seen[kind].add(identifier)

        if kind == "Patient":
            birth = resource.get("birthDate", "")
            if birth:
                birth = _date(birth, label)
            normalized[kind].append({
                "patient_id": identifier,
                "gender": str(resource.get("gender", "")),
                "birth_date": birth,
            })
        elif kind == "Encounter":
            period = resource.get("period") or {}
            class_obj = resource.get("class") or {}
            normalized[kind].append({
                "encounter_id": identifier,
                "patient_id": _patient_reference(resource, label),
                "status": _required_text(resource, "status", label),
                "class_code": str(class_obj.get("code", "")),
                "period_start": _date(period["start"], label) if period.get("start") else "",
                "period_end": _date(period["end"], label) if period.get("end") else "",
            })
        else:
            code_obj = resource.get("code") or {}
            coding = code_obj.get("coding") or []
            first_coding = coding[0] if coding else {}
            effective = resource.get("effectiveDateTime", "")
            value_quantity = resource.get("valueQuantity") or {}
            value = value_quantity.get("value", "")
            normalized[kind].append({
                "observation_id": identifier,
                "patient_id": _patient_reference(resource, label),
                "status": _required_text(resource, "status", label),
                "code": str(first_coding.get("code", "")),
                "display": str(first_coding.get("display", code_obj.get("text", ""))),
                "effective_date": _date(effective, label) if effective else "",
                "value": str(value),
                "unit": str(value_quantity.get("unit", "")),
            })

    patient_ids = {row["patient_id"] for row in normalized["Patient"]}
    for kind in ("Encounter", "Observation"):
        for row in normalized[kind]:
            if row["patient_id"] not in patient_ids:
                raise FHIRValidationError(
                    f"{kind}/{row[kind.lower() + '_id']} references missing Patient/{row['patient_id']}"
                )

    return normalized


def ingest(input_path: Path, output_dir: Path) -> dict[str, Any]:
    bundle = json.loads(input_path.read_text(encoding="utf-8"))
    normalized = validate_and_normalize(bundle)
    output_dir.mkdir(parents=True, exist_ok=True)

    for kind, (filename, columns) in OUTPUTS.items():
        with (output_dir / filename).open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=columns)
            writer.writeheader()
            writer.writerows(normalized[kind])

    report = {
        "input_file": input_path.name,
        "bundle_type": bundle.get("type", "unspecified"),
        "status": "passed",
        "resource_counts": {kind: len(rows) for kind, rows in normalized.items()},
        "total_supported_resources": sum(len(rows) for rows in normalized.values()),
        "reconciliation": {
            "patient_count": len(normalized["Patient"]),
            "encounter_count": len(normalized["Encounter"]),
            "observation_count": len(normalized["Observation"]),
            "referential_integrity": "passed",
            "duplicate_resource_ids": 0,
        },
        "scope_note": "Subset mapping only; not a complete FHIR R4 validator or conformance claim.",
    }
    (output_dir / "reconciliation_report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=ROOT / "data/fhir_demo/sample_bundle.json")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "build/fhir_normalized")
    args = parser.parse_args()
    try:
        report = ingest(args.input, args.output_dir)
    except (OSError, json.JSONDecodeError, FHIRValidationError) as exc:
        print(f"FHIR DEMO INGESTION: FAILED - {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
