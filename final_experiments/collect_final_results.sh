#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/Users/Shared/yolo-mpi-people-count}"
RESULT_ROOT="${RESULT_ROOT:-results}"
PACKAGE_DIR="${PACKAGE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DEST_DIR="${DEST_DIR:-$PACKAGE_DIR/collected_results}"

cd "$REPO_DIR"
mkdir -p "$DEST_DIR"

copy_if_exists() {
  local src="$1"
  local dst="$DEST_DIR/$(basename "$src")"
  if [[ -e "$src" ]]; then
    rm -rf "$dst"
    cp -R "$src" "$dst"
    printf 'COPIED  %s -> %s\n' "$src" "$dst"
  else
    printf 'MISSING %s\n' "$src"
  fi
}

copy_if_exists "$RESULT_ROOT/final_correctness_static"
copy_if_exists "$RESULT_ROOT/final_correctness_dynamic"
copy_if_exists "$RESULT_ROOT/final_find_N"
copy_if_exists "$RESULT_ROOT/final_granularity"
copy_if_exists "$RESULT_ROOT/final_scheduler_comparison"
copy_if_exists "$RESULT_ROOT/final_speedup_2N"
copy_if_exists "$RESULT_ROOT/final_communication"
copy_if_exists "$RESULT_ROOT/final_evidence"
copy_if_exists "$RESULT_ROOT/final_heterogeneous_balance"

cat > "$DEST_DIR/MANIFEST.txt" <<EOF
Collected at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Repository: $REPO_DIR
Result root: $RESULT_ROOT

Required report inputs:
- final_correctness_static/summary.csv
- final_correctness_static/rank_metrics.csv
- final_correctness_static/frame_counts.csv
- final_correctness_static/bboxes.csv
- final_correctness_dynamic/summary.csv
- final_correctness_dynamic/rank_metrics.csv
- final_correctness_dynamic/frame_counts.csv
- final_correctness_dynamic/bboxes.csv
- final_find_N/raw/find_N.csv
- final_granularity/**/rank_metrics.csv
- final_scheduler_comparison/scheduler_comparison.csv
- final_speedup_2N/raw/speedup.csv
- final_communication/communication_summary.csv
- final_evidence/*
- optional final_heterogeneous_balance/heterogeneous_overview.csv
EOF

echo "COLLECTED_RESULTS_DIR=$DEST_DIR"
