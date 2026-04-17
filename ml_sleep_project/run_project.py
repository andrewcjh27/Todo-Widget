from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "src"))

from sleep_ml_project import pretty_report, run_all_experiments
from sleep_ml_project.data import SyntheticSleepConfig


def main() -> None:
    parser = argparse.ArgumentParser(description="Run sleep ML study-inspired experiments.")
    parser.add_argument(
        "--epochs-per-hemisphere",
        type=int,
        default=450,
        help="Synthetic epochs generated per participant hemisphere.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Also print raw JSON results.",
    )
    args = parser.parse_args()

    config = SyntheticSleepConfig(epochs_per_hemisphere=args.epochs_per_hemisphere)
    report = run_all_experiments(config)

    print(pretty_report(report))
    if args.json:
        print("\nRaw JSON summary:\n")
        print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
