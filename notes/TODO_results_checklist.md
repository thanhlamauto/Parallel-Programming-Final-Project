# TODO Results Checklist

This draft intentionally does not invent measurements. Fill the report only from real CSV files and logs.

## Correctness Run Checklist

- Build the C++ executable on the cluster with `bash scripts/build.sh`.
- Run a small correctness command with `--verify 1`, or use `bash scripts/run/demo_correctness.sh`.
- Save `frame_counts.csv`, `bboxes.csv`, `rank_metrics.csv`, `summary.csv`, and `correctness.txt`.
- Record `mismatched_frames`, `mean_count_error`, and `max_count_error`.
- Confirm that correctness is serial-vs-parallel, not human ground truth.

## Input Size Selection Checklist

- Run `bash scripts/run/find_N.sh`.
- Try several frame counts, for example `50 100 200 400 600 800`.
- Select the `N` whose wall-clock runtime is approximately 2-3 minutes.
- Save `raw/find_N.csv` and the per-run `summary.csv` files.
- Plot runtime with communication and compute-only estimate versus `N`.

## Granularity / Load Balance Checklist

- Run at least two tile grids, such as `1x1`, `2x2`, and `4x3`.
- Save each run's `rank_metrics.csv` and `summary.csv`.
- Plot stacked per-rank bars: compute time, communication time, idle/wait time.
- Compute `imbalance = (T_max - T_min) / T_max`.
- Mark load balance acceptable only if imbalance is at most 25%.

## Speedup Checklist

- Use input size `2N` after selecting `N`.
- Run `P = 1, 2, 4, 8, ..., X, 2X` as required by the course.
- Label `2X` clearly as oversubscription if it exceeds physical cores.
- Save `raw/speedup.csv`.
- Plot runtime and speedup with and without communication.
- Compute efficiency `E_p = S_p / p`.

## Communication Overhead Checklist

- Use `comm_ms_total` from `summary.csv`.
- Report `comm_ratio = comm_ms_total / total_ms_with_comm`.
- Compare static and dynamic scheduling under the same input size and process count.
- Discuss whether dynamic scheduling reduces idle time enough to offset extra communication.
