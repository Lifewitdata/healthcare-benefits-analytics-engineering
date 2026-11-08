"""Source-level healthcare benefits data contract checks.

Checks the committed demonstration CSVs before dbt loads them. This is a
reproducible portfolio example, not a substitute for production PHI controls.
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

CONTRACTS = {
    "clients.csv": {"required": {"client_id", "client_name", "industry", "plan_tier"}, "key": "client_id"},
    "members.csv": {"required": {"member_id", "client_id", "enrollment_date", "sessions_per_member_allowance"}, "key": "member_id"},
    "sessions.csv": {"required": {"session_id", "member_id", "session_date", "session_type", "cost_usd"}, "key": "session_id"},
    "assessments.csv": {"required": {"assessment_id", "member_id", "assessment_type", "timepoint", "assessment_date", "score"}, "key": "assessment_id"},
    "member_journey.csv": {"required": {"member_id", "client_id", "enrolled_date", "reached_scheduled", "reached_first_session", "reached_engaged", "reached_assessed"}, "key": "member_id"},
}


def load_csv(name: str) -> tuple[list[dict[str, str]], set[str]]:
    path = DATA / name
    if not path.exists():
        raise ValueError(f"Missing required source file: {path.relative_to(ROOT)}")
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError(f"{name}: missing header row")
        return list(reader), set(reader.fieldnames)


def run_checks() -> list[str]:
    errors: list[str] = []
    loaded: dict[str, list[dict[str, str]]] = {}
    for name, contract in CONTRACTS.items():
        try:
            rows, columns = load_csv(name)
            loaded[name] = rows
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
            continue
        missing = contract["required"] - columns
        if missing:
            errors.append(f"{name}: missing required columns: {sorted(missing)}")
            continue
        key = contract["key"]
        values = [row.get(key, "").strip() for row in rows]
        if any(not value for value in values):
            errors.append(f"{name}: {key} contains blank values")
        if len(values) != len(set(values)):
            errors.append(f"{name}: {key} contains duplicate values")
        if not rows:
            errors.append(f"{name}: source contains no records")

    if all(name in loaded for name in CONTRACTS):
        clients = {r["client_id"].strip() for r in loaded["clients.csv"]}
        members = {r["member_id"].strip() for r in loaded["members.csv"]}
        for name in ("members.csv", "member_journey.csv"):
            for row in loaded[name]:
                if row.get("client_id", "").strip() not in clients:
                    errors.append(f"{name}: orphan client_id found")
                    break
        for name in ("sessions.csv", "assessments.csv"):
            for row in loaded[name]:
                if row.get("member_id", "").strip() not in members:
                    errors.append(f"{name}: orphan member_id found")
                    break

        for row in loaded["sessions.csv"]:
            try:
                if float(row["cost_usd"]) < 0:
                    errors.append("sessions.csv: negative cost_usd found")
                    break
            except (KeyError, ValueError):
                errors.append("sessions.csv: cost_usd contains a non-numeric value")
                break

        for row in loaded["assessments.csv"]:
            try:
                score = int(row["score"])
                kind = row["assessment_type"].strip()
                maximum = {"PHQ-9": 27, "GAD-7": 21}.get(kind)
                if score < 0 or (maximum is not None and score > maximum):
                    errors.append(f"assessments.csv: score outside valid range for {kind}")
                    break
            except (KeyError, ValueError):
                errors.append("assessments.csv: score contains a non-integer value")
                break

    return errors


if __name__ == "__main__":
    problems = run_checks()
    if problems:
        print("SOURCE DATA CONTRACT: FAILED")
        for problem in problems:
            print(f"- {problem}")
        sys.exit(1)
    print("SOURCE DATA CONTRACT: PASSED")
    for filename in CONTRACTS:
        rows, _ = load_csv(filename)
        print(f"- {filename}: {len(rows):,} rows")
