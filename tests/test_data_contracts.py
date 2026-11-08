from scripts.data_quality import CONTRACTS, load_csv, run_checks


def test_all_required_source_files_exist_and_have_rows():
    for filename in CONTRACTS:
        rows, columns = load_csv(filename)
        assert rows
        assert CONTRACTS[filename]["required"].issubset(columns)


def test_source_data_contracts_pass():
    assert run_checks() == []
