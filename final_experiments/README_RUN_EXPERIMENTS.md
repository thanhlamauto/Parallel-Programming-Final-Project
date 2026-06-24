# Final YOLO-MPI Experiment Workflow

This folder contains the reproducible experiment package for the IT4130E final report. The report direction is YOLO-only. Do not add a VGG16/convolution/halo-exchange Method 2 because it is not implemented in the repository.

Run these scripts on the macOS master node where OpenMPI, SSH aliases, the Python environment, model weights, and video assets are available.

## 1. Prepare Repository, Assets, And Model

Set the repository path if it differs from the default:

```bash
export REPO_DIR="/Users/Shared/yolo-mpi-people-count"
cd "$REPO_DIR"
```

Install Python helper dependencies and download shareable runtime assets:

```bash
.venv/bin/python -m pip install '.[assets,yolo]'
.venv/bin/python scripts/assets/download_hf_assets.py \
  --repo-id Bangchis/yolo-mpi-people-count-assets
```

Build the C++17/OpenMPI executable:

```bash
bash scripts/build.sh
```

## 2. Run Cluster Sanity Check

Check macOS/OpenMPI/SSH environment:

```bash
bash scripts/cluster/check_macos.sh
```

Check Apple MPS visibility through MPI:

```bash
mpirun -np 3 --hostfile configs/hosts_macos_gpu \
  --mca btl tcp,self --mca btl_tcp_if_include "${MPI_LAN_CIDR:-192.168.31.0/24}" \
  --mca btl_tcp_disable_family 6 \
  .venv/bin/python scripts/cluster/check_mps.py
```

## 3. One-Command Workflow

From this `final_experiments` folder:

```bash
bash run_all_final_experiments.sh
```

On the first pass, `SELECTED_N` is intentionally blank. The script runs correctness and `find_N`, then stops and asks you to choose `SELECTED_N` from:

```text
results/final_find_N/raw/find_N.csv
```

Choose the frame count whose `total_ms_with_comm` is closest to 120-180 seconds. Then rerun with:

```bash
SELECTED_N=<chosen_N> bash run_all_final_experiments.sh
```

The script sets `SELECTED_2N` automatically as `2 * SELECTED_N` unless you override it.

## 4. Run Correctness Only

The full script runs both:

- `results/final_correctness_static`
- `results/final_correctness_dynamic`

Both use real YOLO by default and `--verify 1` through `scripts/run/demo_correctness.sh`.

Useful override example:

```bash
YOLO_SOURCE=data/classroom.mp4 \
YOLO_MODEL=models/yolo11n.pt \
bash run_all_final_experiments.sh
```

Do not use `YOLO_DETECTOR=mock` for final report measurements unless you clearly label it as a smoke test and exclude it from performance conclusions.

## 5. Run Input Size Selection

The workflow uses:

- `P = 12`
- `configs/hosts_macos_core`
- dynamic scheduling
- tile grid `1x1`
- frame list `50 100 200 400 600 800`

Output:

```text
results/final_find_N/raw/find_N.csv
```

## 6. Run Granularity And Load Balance

After choosing `SELECTED_N`, the workflow runs at least:

- `results/final_granularity/grid_1x1`
- `results/final_granularity/grid_2x2`

Each run should produce:

- `rank_metrics.csv`
- `summary.csv`
- `frame_counts.csv`
- `bboxes.csv`

Use `rank_metrics.csv` for stacked bars: compute/YOLO time, communication time, idle/wait time, and `tasks_done`.

Optional heterogeneous host-mapping comparison:

```bash
RUN_HETEROGENEOUS_BALANCE=1 SELECTED_N=<chosen_N> bash run_all_final_experiments.sh
```

This calls `scripts/run/heterogeneous_balance.sh` and writes:

```text
results/final_heterogeneous_balance/heterogeneous_overview.csv
```

## 7. Run Static vs Dynamic Scheduling

After choosing `SELECTED_N`, the workflow runs:

```text
results/final_scheduler_comparison
```

It uses `scripts/run/scheduler_comparison.sh` with the same N, P, tile grid, detector settings, and hostfile for static and dynamic runs.

Required output:

```text
results/final_scheduler_comparison/scheduler_comparison.csv
```

## 8. Run Speedup

The workflow uses `2N` frames and:

```text
P = 1 2 4 8 12 24
```

Output:

```text
results/final_speedup_2N/raw/speedup.csv
```

If `P=24` exceeds physical cores or causes intentional oversubscription, label it as oversubscription in the report.

## 9. Validate Outputs

Run:

```bash
bash validate_final_results.sh
```

This checks for the required CSV files and at least one granularity `rank_metrics.csv`.

## 10. Collect Files To Send Back For Report Filling

After all runs pass validation:

```bash
bash collect_final_results.sh
```

This copies the final `results/final_*` directories into:

```text
final_experiments/collected_results
```

Send back:

- the whole `collected_results` folder;
- `results/final_find_N/raw/find_N.csv`;
- `results/final_scheduler_comparison/scheduler_comparison.csv`;
- `results/final_speedup_2N/raw/speedup.csv`;
- `results/final_communication/communication_summary.csv`;
- optional `results/final_heterogeneous_balance/heterogeneous_overview.csv`;
- all granularity `rank_metrics.csv` files;
- hardware evidence from `results/final_evidence`.
