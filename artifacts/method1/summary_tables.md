# Method 1 Artifact Summary: YOLO11n Task Parallelism

This folder keeps the compact report-ready outputs for Method 1.

## Correctness

Serial YOLO and MPI YOLO are compared frame by frame. The selected correctness
run reports zero count mismatch for the checked frames.

Main files:

- `correctness/correctness_compare.csv`
- `correctness/correctness_per_frame.csv`

## Detection Accuracy

YOLO predicted people counts are compared against MOT17-derived ground-truth
counts. This measures detector quality, not MPI correctness.

Main files:

- `accuracy/accuracy.csv`
- `accuracy/per_frame_accuracy.csv`
- `accuracy/count_error_plot.png`

## Static Granularity And Load Balance

The final Method 1 scope uses static block-cyclic mapping. The static rank
metrics are kept here for report discussion, together with tile-grid
granularity plots.

Main files:

- `granularity/granularity_overview.csv`
- `granularity/granularity_overview.png`
- `granularity/static_rank_summary.csv`
- `granularity/static_rank_metrics_stacked.png`

## Heterogeneous Static Mapping

The weighted-static experiment compares uniform rank allocation with manually
weighted allocation across the three MacBooks.

Main files:

- `heterogeneous/weighted_static_comparison.csv`
- `heterogeneous/weighted_static_comparison.png`
- `heterogeneous/heterogeneous_overview.csv`
- `heterogeneous/heterogeneous_balance.png`
