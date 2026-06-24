#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-/Users/Shared/yolo-mpi-people-count}"
RESULT_ROOT="${RESULT_ROOT:-results}"

cd "$REPO_DIR"

failures=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    printf 'PASS    %s\n' "$path"
  else
    printf 'MISSING %s\n' "$path"
    failures=$((failures + 1))
  fi
}

check_any_named_file() {
  local root="$1"
  local name="$2"
  local label="$3"
  local first=""
  local count="0"
  if [[ -d "$root" ]]; then
    first="$(find "$root" -type f -name "$name" -print | head -n 1)"
    count="$(find "$root" -type f -name "$name" -print | wc -l | tr -d ' ')"
  fi
  if [[ -n "$first" ]]; then
    printf 'PASS    %s (%s found)\n' "$label" "$count"
    printf '        first: %s\n' "$first"
  else
    printf 'MISSING %s\n' "$label"
    failures=$((failures + 1))
  fi
}

check_any_file() {
  local root="$1"
  local label="$2"
  local first=""
  local count="0"
  if [[ -d "$root" ]]; then
    first="$(find "$root" -type f -print | head -n 1)"
    count="$(find "$root" -type f -print | wc -l | tr -d ' ')"
  fi
  if [[ -n "$first" ]]; then
    printf 'PASS    %s (%s found)\n' "$label" "$count"
    printf '        first: %s\n' "$first"
  else
    printf 'MISSING %s\n' "$label"
    failures=$((failures + 1))
  fi
}

echo "Validating final experiment outputs under: $REPO_DIR/$RESULT_ROOT"

check_file "$RESULT_ROOT/final_correctness_static/summary.csv"
check_file "$RESULT_ROOT/final_correctness_static/rank_metrics.csv"
check_file "$RESULT_ROOT/final_correctness_static/frame_counts.csv"
check_file "$RESULT_ROOT/final_correctness_static/bboxes.csv"

check_file "$RESULT_ROOT/final_correctness_dynamic/summary.csv"
check_file "$RESULT_ROOT/final_correctness_dynamic/rank_metrics.csv"
check_file "$RESULT_ROOT/final_correctness_dynamic/frame_counts.csv"
check_file "$RESULT_ROOT/final_correctness_dynamic/bboxes.csv"

check_file "$RESULT_ROOT/final_find_N/raw/find_N.csv"
check_file "$RESULT_ROOT/final_scheduler_comparison/scheduler_comparison.csv"
check_file "$RESULT_ROOT/final_speedup_2N/raw/speedup.csv"
check_file "$RESULT_ROOT/final_communication/communication_summary.csv"

check_any_named_file "$RESULT_ROOT/final_granularity" "rank_metrics.csv" "at least one final_granularity rank_metrics.csv"
check_any_file "$RESULT_ROOT/final_evidence" "hardware/environment evidence file"

if (( failures > 0 )); then
  echo "VALIDATION_STATUS=FAIL"
  echo "Missing outputs: $failures"
  exit 1
fi

echo "VALIDATION_STATUS=PASS"
