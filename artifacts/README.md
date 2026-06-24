# Report Artifacts

This folder contains the small, Git-tracked subset of experiment outputs used by
the final report. Full raw runs stay under `results/`, which is intentionally
ignored because it can grow quickly.

## Method 1: YOLO11n Task Parallelism

`method1/` contains the selected MOT17-mini report outputs:

- serial-vs-MPI correctness tables
- YOLO-vs-ground-truth count accuracy
- input-size search for `N`
- tile granularity and load-balance plots
- speedup at `2N`
- heterogeneous host/rank allocation comparison

## Method 2: VGG11 Data Parallelism

`method2/` contains the selected VGG11 MPI outputs:

- input-size sweep
- speedup at `N = 224`
- with/without communication estimate
- rank-level compute/communication/idle plot
- classifier correctness metrics using pretrained VGG11 weights

Large model weights are not stored in Git. They are uploaded to Hugging Face and
can be restored with `scripts/assets/download_hf_assets.py`.
