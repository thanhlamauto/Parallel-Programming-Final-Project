#!/usr/bin/env python3
"""Generate report plots from YOLO-MPI CSV outputs.

The script is intentionally tolerant of missing files so the report folder can
exist before experiments are completed.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def read_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        print(f"Missing CSV: {path}")
        return []
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def try_import_matplotlib():
    try:
        import matplotlib.pyplot as plt  # type: ignore
    except Exception as exc:  # pragma: no cover - environment dependent
        print(f"Matplotlib unavailable: {exc}")
        return None
    return plt


def as_float(row: dict[str, str], key: str, default: float = 0.0) -> float:
    try:
        return float(row.get(key, "") or default)
    except ValueError:
        return default


def find_csv(root: Path, name: str) -> Path | None:
    direct = root / name
    if direct.exists():
        return direct
    matches = sorted(root.rglob(name))
    return matches[0] if matches else None


def plot_runtime_vs_input_size(plt, results: Path, plots: Path) -> None:
    candidates = sorted(results.rglob("find_N.csv"))
    if not candidates:
        print("Skipping runtime_vs_input_size.png: find_N.csv not found.")
        return
    rows = read_rows(candidates[0])
    if not rows:
        return
    x = [as_float(r, "frames") for r in rows]
    y_with = [as_float(r, "total_ms_with_comm") / 1000.0 for r in rows]
    y_without = [as_float(r, "total_ms_without_comm") / 1000.0 for r in rows]
    plt.figure(figsize=(7, 4))
    plt.plot(x, y_with, marker="o", label="with communication")
    plt.plot(x, y_without, marker="s", label="compute-only estimate")
    plt.xlabel("Processed frames N")
    plt.ylabel("Runtime (s)")
    plt.title("Runtime vs input size")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(plots / "runtime_vs_input_size.png", dpi=180)
    plt.close()


def plot_rank_granularity(plt, results: Path, plots: Path) -> None:
    path = find_csv(results, "rank_metrics.csv")
    if path is None:
        print("Skipping rank_granularity_stacked_bar.png: rank_metrics.csv not found.")
        return
    rows = read_rows(path)
    if not rows:
        return
    ranks = [r.get("rank", "") for r in rows]
    compute = [as_float(r, "compute_ms") / 1000.0 for r in rows]
    comm = [as_float(r, "comm_ms") / 1000.0 for r in rows]
    idle = [as_float(r, "idle_ms") / 1000.0 for r in rows]
    plt.figure(figsize=(7, 4))
    plt.bar(ranks, compute, label="compute")
    plt.bar(ranks, comm, bottom=compute, label="communication")
    bottom = [a + b for a, b in zip(compute, comm)]
    plt.bar(ranks, idle, bottom=bottom, label="idle/wait")
    plt.xlabel("MPI rank")
    plt.ylabel("Time (s)")
    plt.title("Per-rank granularity and load balance")
    plt.grid(True, axis="y", alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(plots / "rank_granularity_stacked_bar.png", dpi=180)
    plt.close()


def plot_speedup_family(plt, results: Path, plots: Path) -> None:
    candidates = sorted(results.rglob("speedup.csv"))
    if not candidates:
        print("Skipping speedup/runtime process plots: speedup.csv not found.")
        return
    rows = read_rows(candidates[0])
    if not rows:
        return
    p = [as_float(r, "world_size") for r in rows]
    t_with = [as_float(r, "total_ms_with_comm") / 1000.0 for r in rows]
    t_without = [as_float(r, "total_ms_without_comm") / 1000.0 for r in rows]
    s_with = [as_float(r, "speedup_with_comm") for r in rows]
    s_without = [as_float(r, "speedup_without_comm") for r in rows]

    plt.figure(figsize=(7, 4))
    plt.plot(p, t_with, marker="o", label="with communication")
    plt.plot(p, t_without, marker="s", label="compute-only estimate")
    plt.xlabel("MPI processes")
    plt.ylabel("Runtime (s)")
    plt.title("Runtime vs process count")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(plots / "runtime_vs_processes.png", dpi=180)
    plt.close()

    plt.figure(figsize=(7, 4))
    plt.plot(p, s_with, marker="o", label="with communication")
    plt.plot(p, s_without, marker="s", label="compute-only estimate")
    plt.plot(p, p, linestyle="--", color="gray", label="ideal")
    plt.xlabel("MPI processes")
    plt.ylabel("Speedup")
    plt.title("Speedup vs process count")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(plots / "speedup_vs_processes.png", dpi=180)
    plt.close()


def plot_communication_overhead(plt, results: Path, plots: Path) -> None:
    summaries = sorted(results.rglob("summary.csv"))
    if not summaries:
        print("Skipping communication_overhead.png: summary.csv not found.")
        return
    labels: list[str] = []
    ratios: list[float] = []
    for path in summaries:
        rows = read_rows(path)
        if not rows:
            continue
        row = rows[0]
        wall = as_float(row, "total_ms_with_comm")
        comm = as_float(row, "comm_ms_total")
        if wall <= 0:
            continue
        labels.append(row.get("run_id") or path.parent.name)
        ratios.append(100.0 * comm / wall)
    if not labels:
        print("Skipping communication_overhead.png: no usable summary rows.")
        return
    plt.figure(figsize=(max(7, len(labels) * 0.55), 4))
    plt.bar(labels, ratios)
    plt.xticks(rotation=35, ha="right")
    plt.ylabel("Communication / wall time (%)")
    plt.title("Communication overhead")
    plt.grid(True, axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(plots / "communication_overhead.png", dpi=180)
    plt.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, required=True, help="Directory containing experiment CSV files.")
    parser.add_argument("--plots", type=Path, default=Path("plots"), help="Output plot directory.")
    args = parser.parse_args()

    plt = try_import_matplotlib()
    if plt is None:
        return 1

    args.plots.mkdir(parents=True, exist_ok=True)
    plot_runtime_vs_input_size(plt, args.results, args.plots)
    plot_rank_granularity(plt, args.results, args.plots)
    plot_speedup_family(plt, args.results, args.plots)
    plot_communication_overhead(plt, args.results, args.plots)
    print(f"Plots written to: {args.plots}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
