# Pending Final Results

This report draft is method-complete but not measurement-complete. Fill the following items only after the macOS/OpenMPI cluster produces real CSV outputs.

## Required CSV Packages

- `results/final_correctness_static/summary.csv`
- `results/final_correctness_static/rank_metrics.csv`
- `results/final_correctness_static/frame_counts.csv`
- `results/final_correctness_static/bboxes.csv`
- `results/final_correctness_dynamic/summary.csv`
- `results/final_correctness_dynamic/rank_metrics.csv`
- `results/final_correctness_dynamic/frame_counts.csv`
- `results/final_correctness_dynamic/bboxes.csv`
- `results/final_find_N/raw/find_N.csv`
- `results/final_granularity/**/rank_metrics.csv`
- `results/final_scheduler_comparison/scheduler_comparison.csv`
- `results/final_speedup_2N/raw/speedup.csv`
- `results/final_communication/communication_summary.csv`
- `results/final_evidence/*`

## Report Tables Still Pending

- Table `tab:hardware`: host CPU/SoC, memory, and environment details.
- Table `tab:correctness`: frames, grid, processes, and pass/fail status.
- Table `tab:input-size`: candidate frame counts and selected `N`.
- Table `tab:granularity`: per-rank task and timing metrics.
- Table `tab:scheduler`: static versus dynamic measured comparison.
- Table `tab:speedup`: runtime, speedup, and efficiency.
- Table `tab:communication`: communication ratio.

## Figures Still Pending From Real CSV

- Per-rank stacked bar chart from `rank_metrics.csv`.
- Speedup chart from `speedup.csv`.
- Static versus dynamic comparison plot from `scheduler_comparison.csv`.

## Guardrails

- Do not add VGG16, convolution, or halo exchange as a method.
- Do not claim non-blocking payload transfer. Only `MPI_Iprobe` polling is implemented.
- Do not use mock-detector runs as final YOLO performance evidence.
- Do not report runtime, speedup, correctness, or hardware numbers unless they appear in real measured outputs.
