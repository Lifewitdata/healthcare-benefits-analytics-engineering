"""Run the reproducible source-quality and dbt analytics pipeline."""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DBT_DIR = ROOT / "dbt_project"


def run(command: list[str], cwd: Path) -> None:
    print("\n$", " ".join(command), flush=True)
    subprocess.run(command, cwd=cwd, check=True, env=os.environ.copy())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-seed", action="store_true", help="Reuse the existing DuckDB seed tables")
    args = parser.parse_args()

    try:
        run([sys.executable, str(ROOT / "scripts" / "data_quality.py")], ROOT)
        if not args.skip_seed:
            run(["dbt", "seed", "--full-refresh"], DBT_DIR)
        run(["dbt", "run"], DBT_DIR)
        run(["dbt", "test"], DBT_DIR)
        print("\nPIPELINE STATUS: SUCCESS")
        return 0
    except subprocess.CalledProcessError as exc:
        print(f"\nPIPELINE STATUS: FAILED (exit code {exc.returncode})", file=sys.stderr)
        return exc.returncode or 1


if __name__ == "__main__":
    raise SystemExit(main())
