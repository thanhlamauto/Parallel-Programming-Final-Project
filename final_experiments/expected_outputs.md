# Expected Final Experiment Outputs

All paths below are relative to the YOLO-MPI repository root unless otherwise noted.

## Correctness Verification

Static:

- `results/final_correctness_static/summary.csv`
- `results/final_correctness_static/rank_metrics.csv`
- `results/final_correctness_static/frame_counts.csv`
- `results/final_correctness_static/bboxes.csv`
- `results/final_correctness_static/correctness.txt`
- `results/final_correctness_static/demo_correctness.log`

Dynamic:

- `results/final_correctness_dynamic/summary.csv`
- `results/final_correctness_dynamic/rank_metrics.csv`
- `results/final_correctness_dynamic/frame_counts.csv`
- `results/final_correctness_dynamic/bboxes.csv`
- `results/final_correctness_dynamic/correctness.txt`
- `results/final_correctness_dynamic/demo_correctness.log`

Report use:

- correctness pass/fail;
- frames checked;
- max count error;
- mean count error;
- serial-vs-parallel output equality.

## Input Size Selection

- `results/final_find_N/raw/find_N.csv`

Required columns:

- `frames`
- `total_ms_with_comm`
- `total_ms_without_comm`
- `world_size`
- `tile_grid`
- `schedule`

Report use:

- runtime vs input size with communication;
- runtime vs input size without communication;
- selected `N` with target runtime about 120-180 seconds.

## Granularity And Load Balance

At least one of:

- `results/final_granularity/grid_1x1/rank_metrics.csv`
- `results/final_granularity/grid_2x2/rank_metrics.csv`

Also useful:

- `results/final_granularity/grid_1x1/summary.csv`
- `results/final_granularity/grid_2x2/summary.csv`
- `results/final_granularity/grid_1x1/frame_counts.csv`
- `results/final_granularity/grid_2x2/frame_counts.csv`

Required `rank_metrics.csv` columns:

- `rank`
- `hostname`
- `tasks_done`
- `frames_done`
- `compute_ms`
- `io_ms`
- `yolo_ms`
- `comm_ms`
- `idle_ms`

Report use:

- per-rank task count;
- stacked compute/YOLO, communication, and idle/wait chart;
- load-balance discussion with 25% threshold.

## Static vs Dynamic Scheduling

- `results/final_scheduler_comparison/scheduler_comparison.csv`
- `results/final_scheduler_comparison/static/summary.csv`
- `results/final_scheduler_comparison/dynamic/summary.csv`
- `results/final_scheduler_comparison/static/rank_metrics.csv`
- `results/final_scheduler_comparison/dynamic/rank_metrics.csv`

Expected `scheduler_comparison.csv` columns:

- `schedule`
- `world_size`
- `frames`
- `tile_grid`
- `num_tasks`
- `total_ms_with_comm`
- `total_ms_without_comm`
- `load_imbalance`
- `comm_s_total`
- `idle_s_total`
- `idle_gap_ratio`
- `load_balance_pass`

Report use:

- static vs dynamic wall time;
- load imbalance;
- communication and idle tradeoff.

## Speedup

- `results/final_speedup_2N/raw/speedup.csv`

Required columns:

- `world_size`
- `total_ms_with_comm`
- `total_ms_without_comm`
- `speedup_with_comm`
- `speedup_without_comm`
- `efficiency_with_comm`
- `efficiency_without_comm`
- `tile_grid`
- `schedule`

Report use:

- runtime vs P with communication;
- runtime vs P without communication;
- speedup vs P with ideal line;
- efficiency if space permits;
- oversubscription discussion for `P=24` if applicable.

## Communication Overhead

Derive from:

- any `summary.csv` with `comm_ms_total` and `total_ms_with_comm`;
- any `rank_metrics.csv` with `comm_ms`.

Generated summary:

- `results/final_communication/communication_summary.csv`

Expected columns:

- `run_dir`
- `run_id`
- `schedule`
- `world_size`
- `frames`
- `tile_grid`
- `total_ms_with_comm`
- `comm_ms_total`
- `communication_ratio`

Formula:

```text
communication_ratio = comm_ms_total / total_ms_with_comm
```

Report use:

- communication overhead by schedule or process count.

## Optional Heterogeneous Balance Evidence

Only required if the group enables `RUN_HETEROGENEOUS_BALANCE=1`.

Expected files:

- `results/final_heterogeneous_balance/heterogeneous_overview.csv`
- `results/final_heterogeneous_balance/uniform_24/rank_metrics.csv`
- `results/final_heterogeneous_balance/weighted_24/rank_metrics.csv`
- `results/final_heterogeneous_balance/uniform_24/host_metrics.csv`
- `results/final_heterogeneous_balance/weighted_24/host_metrics.csv`
- `results/final_heterogeneous_balance/figures/heterogeneous_balance.png`

Main columns in `heterogeneous_overview.csv`:

- `label`
- `world_size`
- `frames`
- `tile_grid`
- `total_ms_with_comm`
- `total_ms_without_comm`
- `load_imbalance`
- `host_task_distribution`

## Hardware Evidence

- `results/final_evidence/master_environment.txt`
- `results/final_evidence/collect_node_info.log` if `scripts/cluster/collect_node_info.sh` succeeds

Expected content:

- hostnames;
- CPU/SoC if script reports it;
- physical cores if script reports it;
- memory if script reports it;
- OpenMPI version;
- Python version;
- model path;
- device setting;
- source video path.

## Collected Result Package

After running:

```bash
bash final_experiments/collect_final_results.sh
```

Expected package path:

- `H:\My Drive\IT4130E_YOLO_MPI_Report\final_experiments\collected_results`

This folder should be sent back for report filling.
