# Repository And Evidence Audit

Audit date: 2026-06-24  
Repository: `H:\My Drive\yolo-mpi-people-count`  
Report folder: `H:\My Drive\IT4130E_YOLO_MPI_Report`  
Current report PDF: `H:\My Drive\IT4130E_YOLO_MPI_Report\main.pdf`

This audit is factual and read-only. It does not modify the source repository, the LaTeX report, plots, or experiment data.

## 1. Repository Overview

### Main executable

- `src/yolo_mpi_cpp.cpp`
  - Initializes MPI.
  - Parses CLI options.
  - Builds offline frame/tile tasks.
  - Runs either static or dynamic MPI scheduling.
  - Runs live camera mode when `--live 1`.
  - Writes output CSV files from rank 0.

### Build scripts

- `scripts/build.sh`
  - Builds the C++17/OpenMPI executable.

### Run scripts

- `scripts/run/cluster_yolo_smoke.sh`
- `scripts/run/demo_correctness.sh`
- `scripts/run/demo_perf.sh`
- `scripts/run/find_N.sh`
- `scripts/run/speedup_sweep.sh`
- `scripts/run/scheduler_comparison.sh`
- `scripts/run/heterogeneous_balance.sh`
- `scripts/run/live_camera_demo.sh`
- `scripts/run/report_mot17_mini.sh`
- `scripts/run/report_mot17_fullseq.sh`
- `scripts/run/mot17_fullseq_accuracy_suite.sh`
- `scripts/run/extra_report_experiments.sh`

### Benchmark/report scripts

- `scripts/report/compare_frame_counts.py`
- `scripts/report/evaluate_count_accuracy.py`
- `scripts/report/check_report_readiness.py`
- `scripts/report/check_final_readiness.py`
- `scripts/report/summarize_report_dir.py`
- `scripts/report/summarize_host_metrics.py`
- `scripts/report/plots/plot_find_n.py`
- `scripts/report/plots/plot_rank_metrics.py`
- `scripts/report/plots/plot_scheduler_comparison.py`
- `scripts/report/plots/plot_speedup.py`
- `scripts/report/plots/plot_granularity_overview.py`
- `scripts/report/plots/plot_heterogeneous_balance.py`
- `scripts/report/plots/plot_count_error.py`

### Runtime/helper scripts

- `scripts/runtime/yolo_worker.py`
- `scripts/runtime/camera_tile_source.py`
- `scripts/runtime/live_viewer.py`
- `scripts/runtime/render_demo_video.py`

### Cluster/assets scripts

- `scripts/cluster/collect_node_info.sh`
- `scripts/cluster/check_macos.sh`
- `scripts/cluster/check_mps.py`
- `scripts/cluster/sync_to_nodes.sh`
- `scripts/cluster/setup_yolo_macos.sh`
- `scripts/cluster/write_ssh_config.sh`
- `scripts/cluster/import_reference.sh`
- `scripts/cluster/summarize_host_slots.py`
- `scripts/assets/download_model.py`
- `scripts/assets/download_hf_assets.py`
- `scripts/assets/upload_hf_assets.py`
- `scripts/assets/prepare_mot17_mini.py`
- `scripts/assets/probe_video.py`
- `scripts/assets/make_speedup_benchmark_video.py`

### Configs / hostfiles

- `configs/hosts_macos_gpu`
- `configs/hosts_macos_live`
- `configs/hosts_macos_core`
- `configs/hosts_macos_core_weighted_12`
- `configs/hosts_macos_core_weighted_12_4_6_2`
- `configs/hosts_macos_cpu_uniform_24`
- `configs/hosts_macos_cpu_weighted_24`
- `configs/hosts_macos_cpu_weighted_live`
- `configs/hosts_macos_cpu_max_live`
- `configs/cluster_macos.env.example`
- `configs/yolo_mps_experiment.env.example`

### Results folders

No actual `results/` directory was found in the repository snapshot.

Directories whose names look related to running/reporting exist only as source/script folders:

- `scripts/run`
- `scripts/runtime`
- `scripts/report/plots`

These are not experiment result folders.

The repository has a `reports/` folder containing written report artifacts (`.md`, `.html`, `.pdf`), but no raw experiment CSV files were found in it.

## 2. Method 1 Audit: YOLO11n Video Inference

### Source files

YOLO MPI runtime:

- `src/yolo_mpi_cpp.cpp`
- `src/yolo_mpi/README.md`

Task generation:

- `src/yolo_mpi/core/tasks.hpp`
  - Parses tile grid such as `4x3`.
  - Builds `Task` objects for every selected frame and tile.
  - Expands tiles with overlap margins.

Configuration/types:

- `src/yolo_mpi/core/config.hpp`
- `src/yolo_mpi/core/types.hpp`
- `src/yolo_mpi/core/system.hpp`

Static scheduling:

- `src/yolo_mpi/mpi/static_scheduler.hpp`
  - Implements block-cyclic mapping.
  - Uses `block_id = task.task_id / chunk_size`.
  - A task belongs to a rank when `block_id % world_size == rank`.

Dynamic scheduling:

- `src/yolo_mpi/mpi/dynamic_scheduler.hpp`
  - Rank 0 owns a task queue.
  - Worker ranks receive one task at a time.
  - Rank 0 can also compute local tasks when `master_compute` is enabled.

Communication:

- `src/yolo_mpi/mpi/protocol.hpp`
  - `send_task`
  - `recv_task`
  - `send_string`
  - `recv_string`
- `src/yolo_mpi/mpi/communication.hpp`
  - `gather_string`

Detector/YOLO worker:

- `src/yolo_mpi/detector/runner.hpp`
- `src/yolo_mpi/detector/yolo_worker_process.hpp`
- `src/yolo_mpi/detector/mock_command.hpp`
- `src/yolo_mpi/detector/payload.hpp`
- `scripts/runtime/yolo_worker.py`

Post-processing / NMS / de-duplication:

- `src/yolo_mpi/postprocess/geometry.hpp`
- `src/yolo_mpi/postprocess/duplicate_rules.hpp`
- `src/yolo_mpi/postprocess/frame_merge.hpp`
- `src/yolo_mpi/postprocess/temporal.hpp`

CSV output:

- `src/yolo_mpi/output/csv.hpp`

Live camera mode:

- `src/yolo_mpi/live/io.hpp`
- `src/yolo_mpi/live/frame_processing.hpp`
- `src/yolo_mpi/live/runner.hpp`
- `scripts/runtime/camera_tile_source.py`
- `scripts/runtime/live_viewer.py`

### Scripts to run correctness / performance / demo

- `scripts/run/demo_correctness.sh`
  - Uses `--verify 1`.
  - Defaults to `YOLO_NP=3`, `configs/hosts_macos_gpu`, `YOLO_DEMO_FRAMES=20`, `YOLO_TILE_GRID=2x2`.
- `scripts/run/demo_perf.sh`
  - Uses `--verify 0`.
  - Defaults to dynamic scheduling through `YOLO_PERF_SCHEDULE=dynamic`.
- `scripts/run/cluster_yolo_smoke.sh`
  - Runs cluster smoke checks and demo correctness.
- `scripts/run/live_camera_demo.sh`
  - Runs live camera/video-source mode.
- `scripts/run/find_N.sh`
  - Runs multiple frame counts and writes `raw/find_N.csv`.
- `scripts/run/speedup_sweep.sh`
  - Runs process-count sweep and writes `raw/speedup.csv`.
- `scripts/run/scheduler_comparison.sh`
  - Runs static and dynamic cases and writes `scheduler_comparison.csv`.
- `scripts/run/heterogeneous_balance.sh`
  - Runs weighted/uniform host balance experiments.

### Command examples found in README

Demo workflow:

```bash
bash scripts/run/cluster_yolo_smoke.sh
bash scripts/cluster/sync_to_nodes.sh
bash scripts/run/demo_correctness.sh
bash scripts/run/demo_perf.sh
```

Main CLI example:

```bash
mpirun -np 3 --hostfile configs/hosts_macos_gpu \
  --mca btl tcp,self --mca btl_tcp_if_include 192.168.31.0/24 --mca btl_tcp_disable_family 6 \
  build/yolo_mpi_cpp \
  --source data/classroom.mp4 \
  --model models/yolo11n.pt \
  --device mps \
  --imgsz 512 \
  --tile-grid 2x2 \
  --overlap 64 \
  --conf 0.35 \
  --iou 0.50 \
  --schedule static \
  --master-compute 1 \
  --frames 20 \
  --detector yolo \
  --python .venv/bin/python \
  --worker-script scripts/runtime/yolo_worker.py \
  --verify 1 \
  --output results/demo_correctness
```

Fast scheduler-only smoke:

```bash
mpirun -np 2 --oversubscribe --mca btl self,sm,tcp \
  build/yolo_mpi_cpp --frames 4 --tile-grid 2x2 --detector mock --verify 1
```

Check a run directory:

```bash
.venv/bin/python scripts/report/check_final_readiness.py \
  --run-dir results/demo_correctness_YYYYMMDD-HHMMSS \
  --hostfile configs/hosts_macos_gpu \
  --require-host master --require-host node1 --require-host node2
```

### Method 1 verdict

| Question | Answer |
|---|---|
| Is Method 1 implemented? | YES |
| Is it runnable? | UNKNOWN in this Windows/Codex environment; likely runnable on the intended macOS/OpenMPI cluster after assets and Python dependencies are installed. |
| Parallel level | Task-level execution over frame-tile tasks; also data-level decomposition over frames and tiles. Best description: hybrid temporal-spatial data decomposition with task-level MPI execution. |
| Decomposition | Video frames; each frame split into `R x C` tiles; each frame-tile pair becomes one `Task`. |
| Mapping | Both static block-cyclic mapping and dynamic master-worker queue are implemented. |
| Communication topology | Master-worker/star topology in dynamic and live modes; static mode uses independent local processing followed by gather to rank 0. |
| MPI calls used | `MPI_Init`, `MPI_Comm_rank`, `MPI_Comm_size`, `MPI_Barrier`, `MPI_Finalize`, `MPI_Abort`, `MPI_Send`, `MPI_Recv`, `MPI_Gather`, `MPI_Gatherv`, `MPI_Iprobe`. |
| Blocking/non-blocking | Mixed only in the limited sense that `MPI_Iprobe` is used for non-blocking polling. Actual task/result payload transfer uses blocking `MPI_Send`/`MPI_Recv`; static gather uses blocking collectives. |
| `MPI_Iprobe` usage | `MPI_Iprobe` is only polling in `src/yolo_mpi/mpi/dynamic_scheduler.hpp`. No `MPI_Isend` or `MPI_Irecv` payload transfer was found in `src/`, `scripts/`, or `configs/`. |
| Output files | Offline: `frame_counts.csv`, `bboxes.csv`, `rank_metrics.csv`, `summary.csv`, optional rendered demo video. Live: additionally `live_events.csv` and optionally live frame images. |

## 3. Method 2 Audit: VGG16 / Convolution / Data-Parallel Method

### Search terms used

Searched the repository for:

- `VGG16`
- `vgg`
- `convolution`
- `conv`
- `CNN layer`
- `halo`
- `halo exchange`
- `stencil`
- `2D block`
- `block mapping`
- `non-blocking`
- `nonblocking`
- `MPI_Isend`
- `MPI_Irecv`
- `MPI_Wait`
- `MPI_Test`

### Findings

- No source file implementing VGG16 parallelization was found.
- No source file implementing a convolution-layer data-parallel method was found.
- No halo exchange implementation was found.
- No stencil or 2D block decomposition implementation was found.
- No blocking/non-blocking comparison implementation for convolution was found.
- No `MPI_Isend`, `MPI_Irecv`, `MPI_Wait`, or `MPI_Test` was found in `src/`, `scripts/`, or `configs/`.
- The only source-code "non-blocking" evidence is the dynamic scheduler comment around `MPI_Iprobe`, which is polling, not non-blocking payload transfer.
- Some report prose files mention possible future non-blocking communication, but that is not implementation evidence.

### Method 2 verdict

NOT IMPLEMENTED: do not include Method 2 as a main report method.

| Question | Answer |
|---|---|
| Is VGG16 or convolution layer parallelization implemented? | NO |
| Source files | None found |
| Executable/script | None found |
| Command to run | None found |
| Decomposition | Not implemented |
| Mapping | Not implemented |
| Halo exchange | Not implemented |
| Blocking version | Not implemented |
| Non-blocking version | Not implemented |
| Correctness check | Not implemented |
| Result files | None found |

## 4. Existing Results Audit

### Result folders under repository

No real result folder was found under `H:\My Drive\yolo-mpi-people-count`.

The expected output location from README and scripts is `results/`, for example:

- `results/demo_correctness_YYYYMMDD-HHMMSS`
- `results/demo_perf_YYYYMMDD-HHMMSS`
- `results/find_N_YYYYMMDD-HHMMSS`
- `results/speedup_YYYYMMDD-HHMMSS`
- `results/scheduler_comparison_YYYYMMDD-HHMMSS`
- `results/live_camera_*`

However, these folders are not present in the current repository snapshot.

### CSV files found

No CSV files were found in the repository snapshot. Therefore:

- no `summary.csv` is available;
- no `rank_metrics.csv` is available;
- no `frame_counts.csv` is available;
- no `bboxes.csv` is available;
- no `find_N.csv` is available;
- no `speedup.csv` is available;
- no `scheduler_comparison.csv` is available.

### CSV schemas supported by code

Although no result CSV files exist, the code defines these schemas in `src/yolo_mpi/output/csv.hpp`.

`frame_counts.csv`:

```text
frame_id,person_count
```

`bboxes.csv`:

```text
frame_id,tile_id,rank,x1,y1,x2,y2,conf,cls
```

`rank_metrics.csv`:

```text
rank,hostname,tasks_done,frames_done,compute_ms,io_ms,yolo_ms,comm_ms,idle_ms
```

`summary.csv`:

```text
run_id,language,detector,model,device,imgsz,frames,tile_grid,num_tasks,overlap,tile_owner_filter,dedup_ios,dedup_center,dedup_axis_overlap,dedup_gap,dedup_near_camera,dedup_large_area_ratio,dedup_merge,schedule,chunk_size,master_compute,world_size,video_width,video_height,total_ms_with_comm,total_ms_without_comm,compute_ms_max,compute_ms_avg,comm_ms_total,io_ms_total,yolo_ms_total,idle_ms_total,load_imbalance,avg_count,correctness_pass
```

`live_events.csv` is written by live mode, but its exact header was not reprinted in this audit because no live result CSV is present.

### Metrics available if runs are executed

The implementation can provide:

- per-frame people counts;
- final postprocessed bounding boxes;
- per-rank task counts;
- per-rank compute time;
- per-rank YOLO time;
- per-rank communication time;
- estimated idle time;
- wall-clock runtime with communication;
- compute-only estimate without communication;
- total communication time;
- total YOLO time;
- total idle time;
- load-imbalance summary;
- serial-vs-parallel correctness pass/fail when `--verify 1`.

## 5. Required Experiment Coverage

| Requirement | Evidence found? | Source file/result file | Status | Missing action |
|---|---:|---|---|---|
| Correctness verification | Partial implementation evidence only | `--verify` in `src/yolo_mpi/core/config.hpp`; `verify_counts` in `src/yolo_mpi/output/csv.hpp`; `scripts/run/demo_correctness.sh` | Not measured | Run correctness experiment and save `correctness.txt`, `summary.csv`, `frame_counts.csv`, `bboxes.csv`, `rank_metrics.csv`. |
| Input size selection for N around 2-3 minutes | Script only | `scripts/run/find_N.sh` | Not measured | Run `find_N.sh` on cluster and select N with 120-180s wall time. |
| Runtime vs input size with communication | Script only | `scripts/run/find_N.sh`, `raw/find_N.csv` schema | Not measured | Generate `find_N.csv`. |
| Runtime vs input size without communication | Script only | `scripts/run/find_N.sh`, `summary.csv.total_ms_without_comm` | Not measured | Generate `find_N.csv`. |
| Granularity/load balance per rank | Script/code only | `rank_metrics.csv` schema; `scripts/report/plots/plot_rank_metrics.py` | Not measured | Run granularity cases and save `rank_metrics.csv`. |
| Stacked compute/communication/idle chart | Plot script only | `scripts/report/plots/plot_rank_metrics.py` | Not generated | Generate from real `rank_metrics.csv`. |
| Speedup for P = 1, 2, 4, 8, ..., X, 2X | Script only | `scripts/run/speedup_sweep.sh` | Not measured | Run with required `YOLO_P_LIST`, including oversubscription if applicable. |
| Runtime vs P with communication | Script only | `scripts/run/speedup_sweep.sh`, `raw/speedup.csv` | Not measured | Generate `speedup.csv`. |
| Runtime vs P without communication | Script only | `scripts/run/speedup_sweep.sh`, `raw/speedup.csv` | Not measured | Generate `speedup.csv`. |
| Speedup chart with ideal line | Plot script only | `scripts/report/plots/plot_speedup.py` | Not generated | Generate from real `speedup.csv`. |
| Communication overhead | Code metrics only | `summary.csv.comm_ms_total`, `rank_metrics.csv.comm_ms` | Not measured | Derive from real `summary.csv` and `rank_metrics.csv`. |
| Static vs dynamic scheduling comparison | Script only | `scripts/run/scheduler_comparison.sh` | Not measured | Run scheduler comparison and save `scheduler_comparison.csv`. |
| Blocking vs non-blocking communication comparison, only if Method 2 exists | No | No Method 2 implementation found | Not applicable | Do not include this as a required result. |

## 6. Current Report Audit

### Current PDF

- File: `H:\My Drive\IT4130E_YOLO_MPI_Report\main.pdf`
- Page count: 30 pages.
- Status: exceeds the required maximum of 20 pages.
- Important timestamp issue: `main.pdf` was last modified at 2026-06-24 16:33:48, while `main.tex` and section files were modified later at approximately 16:41-16:43. Therefore the current PDF is stale relative to the current LaTeX source. This audit did not recompile because the task is read-only.

### Current LaTeX outline

Current source outline:

- Abstract
- Chapter 1: Introduction
  - Motivation
  - Project Objectives
  - Scope
  - Main Contributions
  - Report Organization
- Chapter 2: Problem Definition
  - Video People Counting Problem
  - YOLO11n Inference as the Target Workload
  - Frame and Tile Representation
  - Serial Baseline
  - Correctness Target
- Chapter 3: System Overview
  - Three-Machine MacBook Cluster
  - C++17/OpenMPI Runtime
  - Local YOLO Worker Process
  - Offline Video Processing Pipeline
  - Live Camera Pipeline
  - Output Artifacts and Metrics
- Chapter 4: Parallelization Strategy
  - Level of Parallelism
  - Decomposition Technique
  - Process Mapping and Processor Assignment
  - Static Scheduling
  - Dynamic Master-Worker Scheduling
  - Communication Strategy and Topology
  - Blocking vs Non-blocking Communication
  - Load Balancing Considerations
  - Post-processing, Tile Ownership, and NMS Deduplication
- Chapter 5: Parallel Algorithm
  - Serial Baseline Algorithm
  - Static MPI Algorithm
  - Dynamic Master-Worker MPI Algorithm
  - Complexity and Communication Cost
- Chapter 6: Experimental Setup
  - Hardware Environment
  - Software Environment
  - Dataset and Input Size Definition
  - Experimental Variables
  - Measured Metrics
  - Timing Methodology
- Chapter 7: Results and Discussion
  - Correctness Verification
  - Input Size Selection
  - Granularity and Load Balance
  - Speedup Evaluation
  - Communication Overhead
  - Static vs Dynamic Scheduling
  - Current Evidence Limitation
- Chapter 8: Conclusion
- Chapter 9: Member Contributions
- References

### TODO and pending status

Current LaTeX source has no literal `TODO` in `main.tex` or `sections/`, but it has many explicit pending placeholders:

- hardware table contains `Pending log`;
- Chapter 7 contains `Pending CSV`, `Pending`, `Not yet measured`, and `Not yet selected`;
- Chapter 7 references `notes/final_missing_results.md`, but that file does not currently exist.

### Placeholder figures

The current source still references placeholder figures:

- `figures/placeholder_architecture.png`
- `figures/placeholder_task_decomposition.png`
- `figures/placeholder_communication_topology.png`

These should be replaced before final submission.

### Tables that need real numbers

- Hardware environment table in Chapter 6.
- Correctness verification table in Chapter 7.
- Input size selection table in Chapter 7.
- Granularity/load-balance table in Chapter 7.
- Speedup table in Chapter 7.

### Sections unsupported by current results

The implementation supports the structure of the report, but the numerical Results chapter is unsupported by current result files because no experiment CSV exists. The unsupported parts are:

- correctness numbers;
- chosen input size N;
- runtime vs input size;
- rank-level load balance;
- speedup and efficiency;
- communication overhead;
- static-vs-dynamic measured comparison.

### Length and cut/merge recommendation

- Current PDF: 30 pages, above the 20-page maximum.
- Since the PDF is stale, exact page count after current LaTeX source changes is unknown without recompilation.
- To fit <=20 pages:
  - remove appendix content from the compiled report;
  - keep cover and contents to one page each;
  - shorten Introduction and System Overview;
  - keep pseudocode concise;
  - keep only the required result tables/plots;
  - move command logs and long run instructions to notes, not main report;
  - do not include Method 2.

## 7. Decision Recommendation

Recommendation: Option A - YOLO-only report.

### Reason

Only the YOLO-MPI frame/tile people-counting method is implemented in the source repository. It has a real C++17/OpenMPI runtime, task generation, static scheduling, dynamic scheduling, MPI communication, post-processing, CSV output, and run scripts. No VGG16/convolution/halo-exchange/data-parallel method exists in the implementation.

### Evidence

- Main executable: `src/yolo_mpi_cpp.cpp`
- Task generation: `src/yolo_mpi/core/tasks.hpp`
- Static scheduling: `src/yolo_mpi/mpi/static_scheduler.hpp`
- Dynamic scheduling: `src/yolo_mpi/mpi/dynamic_scheduler.hpp`
- Communication protocol: `src/yolo_mpi/mpi/protocol.hpp`
- Gather helper: `src/yolo_mpi/mpi/communication.hpp`
- CSV output: `src/yolo_mpi/output/csv.hpp`
- Run scripts: `demo_correctness.sh`, `demo_perf.sh`, `find_N.sh`, `speedup_sweep.sh`, `scheduler_comparison.sh`
- No `MPI_Isend`, `MPI_Irecv`, `MPI_Wait`, `MPI_Test`, VGG16, halo exchange, stencil, or convolution parallel method was found in source code.

### Risks

- No real CSV result files are present, so the final report currently lacks measurable evidence.
- Current PDF is over 20 pages.
- Current source still uses placeholder figures.
- Current Chapter 7 is pending, not a final results chapter.
- Running multiple MPI ranks on Apple MPS may produce contention; this should be discussed only if observed in CSV results.

### Exact next step

Run the YOLO-only evidence pipeline on the intended macOS/OpenMPI cluster and collect CSV outputs. Then fill the report strictly from those CSVs.

## 8. Next Commands To Collect Missing Evidence

Run from the code repository on the macOS master node:

```bash
cd /Users/Shared/yolo-mpi-people-count
```

If the repository path differs, use the actual synchronized path on all nodes.

### 8.1 Build and cluster sanity checks

```bash
bash scripts/build.sh
bash scripts/cluster/check_macos.sh
mpirun -np 3 --hostfile configs/hosts_macos_gpu \
  --mca btl tcp,self --mca btl_tcp_if_include 192.168.31.0/24 --mca btl_tcp_disable_family 6 \
  .venv/bin/python scripts/cluster/check_mps.py
```

### 8.2 Download required runtime assets

```bash
.venv/bin/python -m pip install '.[assets,yolo]'
.venv/bin/python scripts/assets/download_hf_assets.py \
  --repo-id Bangchis/yolo-mpi-people-count-assets
```

### 8.3 Correctness verification

```bash
YOLO_RUN_DIR=results/final_correctness_static \
YOLO_SCHEDULE=static \
YOLO_NP=3 \
YOLO_HOSTFILE=configs/hosts_macos_gpu \
bash scripts/run/demo_correctness.sh
```

```bash
YOLO_RUN_DIR=results/final_correctness_dynamic \
YOLO_SCHEDULE=dynamic \
YOLO_NP=3 \
YOLO_HOSTFILE=configs/hosts_macos_gpu \
bash scripts/run/demo_correctness.sh
```

Check each run:

```bash
.venv/bin/python scripts/report/check_final_readiness.py \
  --run-dir results/final_correctness_static \
  --hostfile configs/hosts_macos_gpu \
  --require-host master --require-host node1 --require-host node2
```

### 8.4 Input size selection

```bash
YOLO_RUN_DIR=results/final_find_N \
YOLO_FIND_FRAME_LIST="50 100 200 400 600 800" \
YOLO_NP=12 \
YOLO_HOSTFILE=configs/hosts_macos_core \
YOLO_TILE_GRID=1x1 \
YOLO_SCHEDULE=dynamic \
bash scripts/run/find_N.sh
```

Select N whose `total_ms_with_comm` is approximately 120000-180000 ms.

### 8.5 Granularity and load balance

```bash
YOLO_RUN_DIR=results/final_granularity \
YOLO_NP=12 \
YOLO_HOSTFILE=configs/hosts_macos_core \
YOLO_PERF_FRAMES=<SELECTED_N> \
bash scripts/run/heterogeneous_balance.sh
```

If comparing tile grids manually:

```bash
for grid in 1x1 2x2 4x3; do
  YOLO_RUN_DIR="results/final_granularity/grid_${grid}" \
  YOLO_TILE_GRID="$grid" \
  YOLO_NP=12 \
  YOLO_HOSTFILE=configs/hosts_macos_core \
  YOLO_PERF_FRAMES=<SELECTED_N> \
  YOLO_RENDER_VIDEO=0 \
  bash scripts/run/demo_perf.sh
done
```

### 8.6 Static vs dynamic scheduling

```bash
YOLO_RUN_DIR=results/final_scheduler_comparison \
YOLO_SCHED_COMPARE_FRAMES=<SELECTED_N> \
YOLO_SCHED_COMPARE_NP=12 \
YOLO_SCHED_COMPARE_TILE_GRID=4x3 \
YOLO_SCHED_COMPARE_HOSTFILE=configs/hosts_macos_core \
bash scripts/run/scheduler_comparison.sh
```

### 8.7 Speedup

Use input size `2N`:

```bash
YOLO_RUN_DIR=results/final_speedup_2N \
YOLO_SPEEDUP_FRAMES=<2_TIMES_SELECTED_N> \
YOLO_P_LIST="1 2 4 8 12 24" \
YOLO_SWEEP_HOSTFILE=configs/hosts_macos_cpu_weighted_24 \
YOLO_TILE_GRID=1x1 \
YOLO_SCHEDULE=dynamic \
bash scripts/run/speedup_sweep.sh
```

If 24 exceeds physical cores or intended slots, label it as oversubscription in the report.

### 8.8 Communication overhead

After the above runs, derive communication ratios from:

- `summary.csv.total_ms_with_comm`
- `summary.csv.comm_ms_total`
- `rank_metrics.csv.comm_ms`

Formula:

```text
communication_ratio = comm_ms_total / total_ms_with_comm
```

### 8.9 Final report evidence package

At minimum, copy or reference these generated files:

- `results/final_correctness_static/summary.csv`
- `results/final_correctness_static/rank_metrics.csv`
- `results/final_correctness_static/frame_counts.csv`
- `results/final_correctness_static/bboxes.csv`
- `results/final_correctness_static/correctness.txt`
- `results/final_find_N/raw/find_N.csv`
- `results/final_scheduler_comparison/scheduler_comparison.csv`
- `results/final_speedup_2N/raw/speedup.csv`
- all relevant `rank_metrics.csv` files from granularity runs
- generated figures from real CSV files

