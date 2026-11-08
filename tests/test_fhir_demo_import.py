import json

import pytest

from scripts.fhir_demo_import import normalize


def bundle():
    return {"resourceType": "Bundle", "entry": [
        {"resource": {"resourceType": "Patient", "id": "p-1"}},
        {"resource": {"resourceType": "Encounter", "id": "e-1", "status": "finished",
                      "subject": {"reference": "Patient/p-1"}}},
        {"resource": {"resourceType": "Observation", "id": "o-1", "status": "final",
                      "subject": {"reference": "Patient/p-1"},
                      "code": {"coding": [{"code": "44249-1"}]},
                      "valueQuantity": {"value": 5, "unit": "score"}}}
    ]}


def test_supported_resources_are_normalized():
    result = normalize(bundle())
    assert len(result["Patient"]) == 1
    assert result["Encounter"][0]["patient_id"] == "p-1"
    assert result["Observation"][0]["value"] == 5


def test_missing_patient_reference_is_rejected():
    data = bundle()
    data["entry"][1]["resource"]["subject"]["reference"] = "Patient/missing"
    with pytest.raises(ValueError, match="absent"):
        normalize(data)


def test_duplicate_identifiers_are_rejected():
    data = bundle()
    data["entry"].append({"resource": {"resourceType": "Patient", "id": "p-1"}})
    with pytest.raises(ValueError, match="Duplicate"):
        normalize(data)


def test_non_bundle_input_is_rejected():
    with pytest.raises(ValueError, match="FHIR Bundle"):
        normalize({"resourceType": "Patient", "id": "p-1"})
