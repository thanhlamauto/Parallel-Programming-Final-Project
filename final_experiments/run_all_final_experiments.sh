#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# User-configurable variables
# -----------------------------
REPO_DIR="${REPO_DIR:-/Users/Shared/yolo-mpi-people-count}"
RESULT_ROOT="${RESULT_ROOT:-results}"
HOSTFILE_GPU="${HOSTFILE_GPU:-configs/hosts_macos_gpu}"
HOSTFILE_CORE="${HOSTFILE_CORE:-configs/hosts_macos_core}"
HOSTFILE_24="${HOSTFILE_24:-configs/hosts_macos_cpu_weighted_24}"
HOSTFILE_UNIFORM_24="${HOSTFILE_UNIFORM_24:-configs/hosts_macos_cpu_uniform_24}"
MPI_LAN_CIDR="${MPI_LAN_CIDR:-192.168.31.0/24}"

# Leave SELECTED_N empty for the first pass. After final_find_N/raw/find_N.csv
# exists, choose the N whose total_ms_with_comm is about 120-180 seconds.
SELECTED_N="${SELECTED_N:-}"
SELECTED_2N="${SELECTED_2N:-}"

FIND_N_FRAME_LIST="${FIND_N_FRAME_LIST:-50 100 200 400 600 800}"
FINAL_TILE_GRID="${FINAL_TILE_GRID:-1x1}"
GRANULARITY_GRIDS="${GRANULARITY_GRIDS:-1x1 2x2}"
SCHED_TILE_GRID="${SCHED_TILE_GRID:-${FINAL_TILE_GRID}}"
SPEEDUP_P_LIST="${SPEEDUP_P_LIST:-1 2 4 8 12 24}"
RUN_HETEROGENEOUS_BALANCE="${RUN_HETEROGENEOUS_BALANCE:-0}"

# Final report measurements should use the real detector.
YOLO_DETECTOR="${YOLO_DETECTOR:-yolo}"
YOLO_DEVICE="${YOLO_DEVICE:-mps}"
YOLO_MODEL="${YOLO_MODEL:-models/yolo11n.pt}"
YOLO_SOURCE="${YOLO_SOURCE:-data/classroom.mp4}"
YOLO_IMGSZ="${YOLO_IMGSZ:-512}"

export MPI_LAN_CIDR YOLO_DETECTOR YOLO_DEVICE YOLO_MODEL YOLO_SOURCE YOLO_IMGSZ

cd "$REPO_DIR"

pass() { printf 'PASS    %s\n' "$1"; }
missing() { printf 'MISSING %s\n' "$1"; }
info() { printf '\n== %s ==\n' "$1"; }

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "$path"
  else
    missing "$path"
    return 1
  fi
}

require_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    pass "$path"
  else
    missing "$path"
    return 1
  fi
}

validate_run_dir() {
  local dir="$1"
  require_file "$dir/summary.csv"
  require_file "$dir/rank_metrics.csv"
  require_file "$dir/frame_counts.csv"
  require_file "$dir/bboxes.csv"
}

info "Build executable"
bash scripts/build.sh
require_file "build/yolo_mpi_cpp"

info "Collect hardware evidence"
mkdir -p "$RESULT_ROOT/final_evidence"
{
  echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repo_dir=$REPO_DIR"
  echo "hostname=$(hostname)"
  echo "mpi_lan_cidr=$MPI_LAN_CIDR"
  echo "yolo_source=$YOLO_SOURCE"
  echo "yolo_model=$YOLO_MODEL"
  echo "yolo_device=$YOLO_DEVICE"
  echo "yolo_imgsz=$YOLO_IMGSZ"
  echo
  echo "## OpenMPI"
  (mpirun --version || true) 2>&1
  echo
  echo "## Python"
  (.venv/bin/python --version || python3 --version || true) 2>&1
} > "$RESULT_ROOT/final_evidence/master_environment.txt"

if [[ -x scripts/cluster/collect_node_info.sh ]]; then
  (bash scripts/cluster/collect_node_info.sh > "$RESULT_ROOT/final_evidence/collect_node_info.log" 2>&1) || true
fi

info "Correctness: static schedule"
YOLO_RUN_DIR="$RESULT_ROOT/final_correctness_static" \
YOLO_SCHEDULE=static \
YOLO_NP=3 \
YOLO_HOSTFILE="$HOSTFILE_GPU" \
YOLO_DETECTOR="$YOLO_DETECTOR" \
YOLO_DEVICE="$YOLO_DEVICE" \
YOLO_MODEL="$YOLO_MODEL" \
YOLO_SOURCE="$YOLO_SOURCE" \
YOLO_RENDER_VIDEO=0 \
bash scripts/run/demo_correctness.sh
validate_run_dir "$RESULT_ROOT/final_correctness_static"

info "Correctness: dynamic schedule"
YOLO_RUN_DIR="$RESULT_ROOT/final_correctness_dynamic" \
YOLO_SCHEDULE=dynamic \
YOLO_NP=3 \
YOLO_HOSTFILE="$HOSTFILE_GPU" \
YOLO_DETECTOR="$YOLO_DETECTOR" \
YOLO_DEVICE="$YOLO_DEVICE" \
YOLO_MODEL="$YOLO_MODEL" \
YOLO_SOURCE="$YOLO_SOURCE" \
YOLO_RENDER_VIDEO=0 \
bash scripts/run/demo_correctness.sh
validate_run_dir "$RESULT_ROOT/final_correctness_dynamic"

info "Input-size selection: find N"
YOLO_RUN_DIR="$RESULT_ROOT/final_find_N" \
YOLO_FIND_FRAME_LIST="$FIND_N_FRAME_LIST" \
YOLO_NP=12 \
YOLO_HOSTFILE="$HOSTFILE_CORE" \
YOLO_TILE_GRID=1x1 \
YOLO_SCHEDULE=dynamic \
YOLO_DETECTOR="$YOLO_DETECTOR" \
YOLO_DEVICE="$YOLO_DEVICE" \
YOLO_MODEL="$YOLO_MODEL" \
YOLO_SOURCE="$YOLO_SOURCE" \
YOLO_RENDER_VIDEO=0 \
bash scripts/run/find_N.sh
require_file "$RESULT_ROOT/final_find_N/raw/find_N.csv"

if [[ -z "$SELECTED_N" ]]; then
  cat <<EOF

STOP AFTER find_N:
  SELECTED_N is not set.
  Open $RESULT_ROOT/final_find_N/raw/find_N.csv and choose the frame count whose
  total_ms_with_comm is about 120000-180000 ms.

Then rerun:
  SELECTED_N=<chosen_N> bash run_all_final_experiments.sh

EOF
  exit 0
fi

if [[ -z "$SELECTED_2N" ]]; then
  SELECTED_2N=$((SELECTED_N * 2))
fi

info "Granularity and load balance"
mkdir -p "$RESULT_ROOT/final_granularity"
for grid in $GRANULARITY_GRIDS; do
  out="$RESULT_ROOT/final_granularity/grid_${grid}"
  YOLO_RUN_DIR="$out" \
  YOLO_NP=12 \
  YOLO_HOSTFILE="$HOSTFILE_CORE" \
  YOLO_PERF_FRAMES="$SELECTED_N" \
  YOLO_TILE_GRID="$grid" \
  YOLO_PERF_SCHEDULE=dynamic \
  YOLO_DETECTOR="$YOLO_DETECTOR" \
  YOLO_DEVICE="$YOLO_DEVICE" \
  YOLO_MODEL="$YOLO_MODEL" \
  YOLO_SOURCE="$YOLO_SOURCE" \
  YOLO_RENDER_VIDEO=0 \
  bash scripts/run/demo_perf.sh
  validate_run_dir "$out"
done

if [[ "$RUN_HETEROGENEOUS_BALANCE" == "1" ]]; then
  info "Optional heterogeneous balance comparison"
  YOLO_RUN_DIR="$RESULT_ROOT/final_heterogeneous_balance" \
  YOLO_HET_FRAMES="$SELECTED_N" \
  YOLO_HET_NP=24 \
  YOLO_HET_TILE_GRID="$FINAL_TILE_GRID" \
  YOLO_HET_UNIFORM_HOSTFILE="$HOSTFILE_UNIFORM_24" \
  YOLO_HET_WEIGHTED_HOSTFILE="$HOSTFILE_24" \
  YOLO_SCHEDULE=dynamic \
  YOLO_DETECTOR="$YOLO_DETECTOR" \
  YOLO_DEVICE="$YOLO_DEVICE" \
  YOLO_MODEL="$YOLO_MODEL" \
  YOLO_SOURCE="$YOLO_SOURCE" \
  YOLO_RENDER_VIDEO=0 \
  bash scripts/run/heterogeneous_balance.sh
  require_file "$RESULT_ROOT/final_heterogeneous_balance/heterogeneous_overview.csv"
fi

info "Static vs dynamic scheduling"
YOLO_RUN_DIR="$RESULT_ROOT/final_scheduler_comparison" \
YOLO_SCHED_COMPARE_FRAMES="$SELECTED_N" \
YOLO_SCHED_COMPARE_NP=12 \
YOLO_SCHED_COMPARE_TILE_GRID="$SCHED_TILE_GRID" \
YOLO_SCHED_COMPARE_HOSTFILE="$HOSTFILE_CORE" \
YOLO_DETECTOR="$YOLO_DETECTOR" \
YOLO_DEVICE="$YOLO_DEVICE" \
YOLO_MODEL="$YOLO_MODEL" \
YOLO_SOURCE="$YOLO_SOURCE" \
bash scripts/run/scheduler_comparison.sh
require_file "$RESULT_ROOT/final_scheduler_comparison/scheduler_comparison.csv"

info "Speedup with input size 2N"
YOLO_RUN_DIR="$RESULT_ROOT/final_speedup_2N" \
YOLO_SPEEDUP_FRAMES="$SELECTED_2N" \
YOLO_P_LIST="$SPEEDUP_P_LIST" \
YOLO_SWEEP_HOSTFILE="$HOSTFILE_24" \
YOLO_TILE_GRID="$FINAL_TILE_GRID" \
YOLO_SCHEDULE=dynamic \
YOLO_DETECTOR="$YOLO_DETECTOR" \
YOLO_DEVICE="$YOLO_DEVICE" \
YOLO_MODEL="$YOLO_MODEL" \
YOLO_SOURCE="$YOLO_SOURCE" \
YOLO_RENDER_VIDEO=0 \
bash scripts/run/speedup_sweep.sh
require_file "$RESULT_ROOT/final_speedup_2N/raw/speedup.csv"

info "Derive communication overhead summary"
mkdir -p "$RESULT_ROOT/final_communication"
python_cmd=".venv/bin/python"
if [[ ! -x "$python_cmd" ]]; then
  python_cmd="python3"
fi
"$python_cmd" - "$RESULT_ROOT" "$RESULT_ROOT/final_communication/communication_summary.csv" <<'PY'
import csv
import sys
from pathlib import Path

root = Path(sys.argv[1])
out = Path(sys.argv[2])
summary_paths = sorted(root.glob("final_*/**/summary.csv"))
rows = []
for path in summary_paths:
    try:
        with path.open(newline="", encoding="utf-8") as f:
            row = next(csv.DictReader(f))
    except Exception:
        continue
    wall = float(row.get("total_ms_with_comm") or 0.0)
    comm = float(row.get("comm_ms_total") or 0.0)
    ratio = comm / wall if wall > 0 else 0.0
    rows.append({
        "run_dir": str(path.parent),
        "run_id": row.get("run_id", ""),
        "schedule": row.get("schedule", ""),
        "world_size": row.get("world_size", ""),
        "frames": row.get("frames", ""),
        "tile_grid": row.get("tile_grid", ""),
        "total_ms_with_comm": row.get("total_ms_with_comm", ""),
        "comm_ms_total": row.get("comm_ms_total", ""),
        "communication_ratio": f"{ratio:.8f}",
    })

out.parent.mkdir(parents=True, exist_ok=True)
with out.open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=[
        "run_dir",
        "run_id",
        "schedule",
        "world_size",
        "frames",
        "tile_grid",
        "total_ms_with_comm",
        "comm_ms_total",
        "communication_ratio",
    ])
    writer.writeheader()
    writer.writerows(rows)
PY
require_file "$RESULT_ROOT/final_communication/communication_summary.csv"

info "Final validation"
REPO_DIR="$REPO_DIR" RESULT_ROOT="$RESULT_ROOT" bash "$SCRIPT_DIR/validate_final_results.sh"

cat <<EOF

FINAL_EXPERIMENTS_DONE=YES
RESULT_ROOT=$REPO_DIR/$RESULT_ROOT
SELECTED_N=$SELECTED_N
SELECTED_2N=$SELECTED_2N

If P=24 exceeds the physical-core/process target, label it as oversubscription
in the report.

EOF
