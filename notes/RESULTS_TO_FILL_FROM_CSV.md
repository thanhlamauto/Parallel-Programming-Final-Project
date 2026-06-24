# Results To Fill From CSV

This note maps measured output files to the LaTeX report tables. Do not fill any report value unless the corresponding CSV exists.

## summary.csv

Used in:

- Table `tab:correctness`
- Table `tab:scheduler`
- Table `tab:communication`
- Chapter 5 narrative

Column mapping:

| CSV column | Report field |
|---|---|
| `run_id` | Run label or evidence note |
| `detector` | Confirm final run uses real `yolo`, not `mock` |
| `model` | Software/model description |
| `device` | Software/device description |
| `imgsz` | Software setup |
| `frames` | Frames / `N` |
| `tile_grid` | Grid |
| `num_tasks` | Task count, granularity discussion |
| `schedule` | Static/dynamic label |
| `world_size` | Processes / `P` |
| `total_ms_with_comm` | Runtime with communication |
| `total_ms_without_comm` | Runtime without communication |
| `comm_ms_total` | Communication overhead numerator |
| `idle_ms_total` | Bottleneck analysis |
| `load_imbalance` | Scheduling and load-balance discussion |
| `avg_count` | Optional people-count summary |
| `correctness_pass` | Correctness pass/fail |

## rank_metrics.csv

Used in:

- Table `tab:granularity`
- Per-rank stacked-bar plot
- Bottleneck analysis

Column mapping:

| CSV column | Report field |
|---|---|
| `rank` | Rank |
| `hostname` | Host |
| `tasks_done` | Tasks |
| `frames_done` | Optional per-rank frame coverage |
| `compute_ms` | Compute ms |
| `io_ms` | Optional I/O discussion |
| `yolo_ms` | YOLO ms |
| `comm_ms` | Communication ms |
| `idle_ms` | Idle ms |

## frame_counts.csv

Used in:

- Correctness verification support
- Optional qualitative discussion of per-frame count stability

Column mapping:

| CSV column | Report field |
|---|---|
| `frame_id` | Frame identifier |
| `person_count` | Final people count for the frame |

## bboxes.csv

Used in:

- Correctness verification support
- Optional rendered demo validation
- Post-processing sanity checks

Column mapping:

| CSV column | Report field |
|---|---|
| `frame_id` | Frame identifier |
| `tile_id` | Source tile |
| `rank` | Producing MPI rank |
| `x1,y1,x2,y2` | Final bounding box coordinates |
| `conf` | Detection confidence |
| `cls` | Detection class |

## find_N.csv

Used in:

- Table `tab:input-size`
- Selection of final `N`

Required mapping:

| CSV concept | Report field |
|---|---|
| frame count column | `N` |
| process count column | `P` |
| tile grid column | Grid |
| `total_ms_with_comm` | Runtime with communication |
| `total_ms_without_comm` | Runtime without communication |

Choose the row whose `total_ms_with_comm` is closest to 120000-180000 ms.

## speedup.csv

Used in:

- Table `tab:speedup`
- Speedup plot
- Efficiency discussion

Column mapping:

| CSV column | Report field |
|---|---|
| `world_size` | `P` |
| `total_ms_with_comm` | Runtime with communication |
| `total_ms_without_comm` | Runtime without communication |
| `speedup_with_comm` | `S_p` if present |
| `speedup_without_comm` | Optional compute-only speedup |
| `efficiency_with_comm` | `E_p` if present |
| `efficiency_without_comm` | Optional compute-only efficiency |
| `tile_grid` | Grid |
| `schedule` | Scheduling label |

If speedup columns are absent, compute `S_p = T_1 / T_p` and `E_p = S_p / p` from measured runtimes.

## scheduler_comparison.csv

Used in:

- Table `tab:scheduler`
- Static vs dynamic discussion

Column mapping:

| CSV column | Report field |
|---|---|
| `schedule` | Schedule |
| `world_size` | `P` |
| `frames` | `N` |
| `tile_grid` | Grid |
| `num_tasks` | Task count |
| `total_ms_with_comm` | Runtime with communication |
| `total_ms_without_comm` | Runtime without communication |
| `load_imbalance` | Imbalance |
| `comm_s_total` | Communication discussion |
| `idle_s_total` | Idle discussion |
| `idle_gap_ratio` | Bottleneck discussion |
| `load_balance_pass` | Load-balance status |

## communication_summary.csv

Used in:

- Table `tab:communication`
- Communication overhead discussion

Column mapping:

| CSV column | Report field |
|---|---|
| `run_dir` | Run |
| `world_size` | `P` |
| `total_ms_with_comm` | `T_wall` |
| `comm_ms_total` | `T_comm` |
| `communication_ratio` | `T_comm / T_wall` |
