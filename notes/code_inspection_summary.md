# Code Inspection Summary

Inspected source folder: `H:\My Drive\yolo-mpi-people-count`

## Main Executable

- Entry point: `src/yolo_mpi_cpp.cpp`
- Build script: `scripts/build.sh`
- The executable initializes MPI, parses configuration, creates offline tasks or runs live mode, selects a scheduler, and writes CSV outputs on rank 0.

## MPI Scheduling Modes Found

- Static scheduling:
  - File: `src/yolo_mpi/mpi/static_scheduler.hpp`
  - Mapping: block-cyclic over flattened task IDs.
  - Formula in code: `block_id = task.task_id / chunk_size`, then `block_id % world_size == rank`.
  - Communication: local processing followed by string gathering to rank 0.

- Dynamic scheduling:
  - File: `src/yolo_mpi/mpi/dynamic_scheduler.hpp`
  - Rank 0 owns the task queue.
  - Worker ranks receive one task, process YOLO inference, and return one payload.
  - Rank 0 can also process local tasks when `master_compute` is enabled.

## Communication Functions Found

- `send_task`: sends seven integers with `MPI_Send`.
- `recv_task`: receives seven integers with `MPI_Recv`.
- `send_string`: sends payload length and payload bytes with `MPI_Send`.
- `recv_string`: receives payload length and payload bytes with `MPI_Recv`.
- `gather_string`: uses `MPI_Gather` and `MPI_Gatherv`.
- Dynamic scheduler uses `MPI_Iprobe` only to poll whether a worker result is available. The actual receive remains blocking.

Conclusion: the implementation primarily uses blocking MPI communication, with non-blocking polling in the dynamic scheduler.

## Output CSV Schema

- `frame_counts.csv`
  - `frame_id,person_count`
- `bboxes.csv`
  - `frame_id,tile_id,rank,x1,y1,x2,y2,conf,cls`
- `rank_metrics.csv`
  - `rank,hostname,tasks_done,frames_done,compute_ms,io_ms,yolo_ms,comm_ms,idle_ms`
- `summary.csv`
  - `run_id,language,detector,model,device,imgsz,frames,tile_grid,num_tasks,overlap,tile_owner_filter,dedup_ios,dedup_center,dedup_axis_overlap,dedup_gap,dedup_near_camera,dedup_large_area_ratio,dedup_merge,schedule,chunk_size,master_compute,world_size,video_width,video_height,total_ms_with_comm,total_ms_without_comm,compute_ms_max,compute_ms_avg,comm_ms_total,io_ms_total,yolo_ms_total,idle_ms_total,load_imbalance,avg_count,correctness_pass`
- Live mode also writes `live_events.csv`.

## Benchmark Scripts Found

- `scripts/run/demo_correctness.sh`
- `scripts/run/demo_perf.sh`
- `scripts/run/find_N.sh`
- `scripts/run/speedup_sweep.sh`
- `scripts/run/scheduler_comparison.sh`
- `scripts/run/heterogeneous_balance.sh`
- `scripts/run/report_mot17_mini.sh`
- `scripts/run/report_mot17_fullseq.sh`
- `scripts/run/live_camera_demo.sh`

## Current Limitations

- No `results/` directory or completed CSV outputs were present in the inspected repository snapshot.
- Runtime assets such as model weights and videos are intentionally not tracked by GitHub.
- Hardware specifications were not found in the inspected snapshot and must be collected from the actual MacBooks.
- Apple MPS contention may affect scaling when multiple MPI ranks share one device.
- Live camera mode is implemented but is harder to reproduce than offline video mode.
