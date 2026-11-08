PYTHON ?= python
DBT_DIR := dbt_project

.PHONY: install quality seed run test build docs dashboard clean

install:
	$(PYTHON) -m pip install -r requirements.txt

quality:
	$(PYTHON) scripts/data_quality.py

seed:
	cd $(DBT_DIR) && dbt seed --full-refresh

run:
	cd $(DBT_DIR) && dbt run

test:
	cd $(DBT_DIR) && dbt test
	$(PYTHON) -m pytest -q

build: quality seed run test

docs:
	cd $(DBT_DIR) && dbt docs generate

dashboard:
	streamlit run dashboard/app.py

clean:
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/logs .pytest_cache
