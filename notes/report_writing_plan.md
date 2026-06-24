# Report Writing Plan

## What Has Been Written

- Created a new isolated report folder: `H:\My Drive\IT4130E_YOLO_MPI_Report`.
- Reused the HUST/SOICT title-page style and logo from `H:\My Drive\Project 1`.
- Wrote a modular LaTeX draft with:
  - abstract;
  - introduction;
  - problem definition;
  - system overview;
  - parallelization strategy;
  - parallel algorithms and pseudocode;
  - experimental setup;
  - results/discussion placeholders;
  - conclusion;
  - member contribution table.
- Added `references.bib`.
- Added placeholder figure files and plotting/check scripts.

## What Still Needs Real Experimental Data

- Hardware specifications for `master`, `node1`, and `node2`.
- Dataset name, video resolution, FPS if needed, and selected frame ranges.
- Correctness metrics from serial-vs-parallel comparison.
- Input-size experiment for choosing `N`.
- Granularity/load-balance metrics from `rank_metrics.csv`.
- Speedup metrics for `P = 1, 2, 4, 8, ..., X, 2X`.
- Static-vs-dynamic scheduling comparison.
- Communication-overhead percentages.

## Exact Commands the Group Should Run Next

Run from the code repository on the macOS master node:

```bash
cd /Users/Shared/yolo-mpi-people-count
bash scripts/build.sh
bash scripts/cluster/check_macos.sh
mpirun -np 3 --hostfile configs/hosts_macos_gpu \
  --mca btl tcp,self --mca btl_tcp_disable_family 6 \
  .venv/bin/python scripts/cluster/check_mps.py
```

Download assets if needed:

```bash
.venv/bin/python -m pip install '.[assets,yolo]'
.venv/bin/python scripts/assets/download_hf_assets.py \
  --repo-id Bangchis/yolo-mpi-people-count-assets
```

Run correctness:

```bash
bash scripts/run/demo_correctness.sh
```

Run input-size selection:

```bash
YOLO_FIND_FRAME_LIST="50 100 200 400 600 800" \
bash scripts/run/find_N.sh
```

Run granularity/scheduler comparison:

```bash
bash scripts/run/scheduler_comparison.sh
bash scripts/run/heterogeneous_balance.sh
```

Run speedup after selecting `N`:

```bash
YOLO_SPEEDUP_FRAMES="<2N>" \
YOLO_P_LIST="1 2 4 8 12 24" \
bash scripts/run/speedup_sweep.sh
```

Generate report plots after copying results:

```bash
cd "H:\My Drive\IT4130E_YOLO_MPI_Report"
python scripts/generate_plots.py --results "H:\My Drive\yolo-mpi-people-count\results\<run_dir>"
```

## Plots That Remain TODO

- `plots/runtime_vs_input_size.png`
- `plots/rank_granularity_stacked_bar.png`
- `plots/runtime_vs_processes.png`
- `plots/speedup_vs_processes.png`
- `plots/communication_overhead.png`
