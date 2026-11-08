"""Demo-only FHIR Bundle importer for a small Patient/Encounter/Observation subset."""
import argparse
import csv
import json
from pathlib import Path

KINDS = {
    "Patient": ("patients.csv", ["id", "gender", "birth_date"]),
    "Encounter": ("encounters.csv", ["id", "patient_id", "status", "start", "end"]),
    "Observation": ("observations.csv", ["id", "patient_id", "status", "code", "display", "date", "value", "unit"]),
}


def normalize(bundle):
    if bundle.get("resourceType") != "Bundle" or not isinstance(bundle.get("entry"), list):
        raise ValueError("Expected a FHIR Bundle with an entry array")
    rows = {kind: [] for kind in KINDS}
    seen = {kind: set() for kind in KINDS}
    for entry in bundle["entry"]:
        resource = entry.get("resource", {})
        kind = resource.get("resourceType")
        if kind not in KINDS:
            continue
        rid = resource.get("id")
        if not isinstance(rid, str) or not rid:
            raise ValueError(f"{kind} is missing id")
        if rid in seen[kind]:
            raise ValueError(f"Duplicate {kind} id: {rid}")
        seen[kind].add(rid)
        if kind == "Patient":
            rows[kind].append({"id": rid, "gender": resource.get("gender", ""),
                               "birth_date": resource.get("birthDate", "")})
            continue
        subject = resource.get("subject", {}).get("reference", "")
        if not subject.startswith("Patient/"):
            raise ValueError(f"{kind}/{rid} has no Patient subject reference")
        patient_id = subject.split("/", 1)[1]
        if kind == "Encounter":
            period = resource.get("period", {})
            rows[kind].append({"id": rid, "patient_id": patient_id,
                               "status": resource.get("status", ""),
                               "start": period.get("start", ""), "end": period.get("end", "")})
        else:
            codings = resource.get("code", {}).get("coding", [])
            coding = codings[0] if codings else {}
            quantity = resource.get("valueQuantity", {})
            rows[kind].append({"id": rid, "patient_id": patient_id,
                               "status": resource.get("status", ""),
                               "code": coding.get("code", ""),
                               "display": coding.get("display", ""),
                               "date": resource.get("effectiveDateTime", ""),
                               "value": quantity.get("value", ""),
                               "unit": quantity.get("unit", "")})
    patient_ids = seen["Patient"]
    for kind in ("Encounter", "Observation"):
        for row in rows[kind]:
            if row["patient_id"] not in patient_ids:
                raise ValueError(f"{kind}/{row['id']} refers to a Patient absent from the Bundle")
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="data/fhir_demo/sample_bundle.json")
    parser.add_argument("--output-dir", default="build/fhir_normalized")
    args = parser.parse_args()
    bundle = json.loads(Path(args.input).read_text(encoding="utf-8"))
    rows = normalize(bundle)
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    for kind, (filename, columns) in KINDS.items():
        with (out / filename).open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=columns)
            writer.writeheader()
            writer.writerows(rows[kind])
    report = {"status": "passed", "counts": {k: len(v) for k, v in rows.items()},
              "patient_references_resolved": True,
              "note": "Subset demonstration only; not a complete FHIR conformance validator."}
    (out / "reconciliation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
