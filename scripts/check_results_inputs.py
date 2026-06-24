#!/usr/bin/env python3
"""Check whether required YOLO-MPI result CSV files exist."""

from __future__ import annotations

import argparse
from pathlib import Path


REQUIRED_FILENAMES = {
    "summary.csv",
    "rank_metrics.csv",
    "frame_counts.csv",
    "bboxes.csv",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, required=True, help="Result directory to inspect.")
    args = parser.parse_args()

    root = args.results
    if not root.exists():
        print(f"Missing results directory: {root}")
        return 1

    found = {p.name: p for p in root.rglob("*.csv")}
    missing = sorted(REQUIRED_FILENAMES - set(found))

    print(f"Results directory: {root}")
    for name in sorted(REQUIRED_FILENAMES):
        if name in found:
            print(f"OK      {name}: {found[name]}")
        else:
            print(f"MISSING {name}")

    if missing:
        print("Not ready for final report tables.")
        return 1

    print("All basic CSV inputs are present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
