#!/usr/bin/env bash
#
# bench_npu_model.sh — drive benchmark_model on the i.MX93 board over SSH,
# offloading inference to the Ethos-U65 NPU via libethosu_delegate.so.
#
# Usage: ./scripts/bench_npu_model.sh <model_basename>
#   e.g. ./scripts/bench_npu_model.sh mobilenetv2_w8a8
#
# Looks for /mnt/models/<basename>_vela.tflite on the board (NFS-mounted).
# Runs 3 reps of (5 warmup + 50 timed) with 2 threads + Ethos-U delegate.
# Reads thermals before/after each rep. Logs go to results/imx93/logs_npu/.
# Prints a summary block at the end suitable for pasting into RESULTS.md.

set -euo pipefail

# ---- Config ---------------------------------------------------------------
BOARD_HOST="${BOARD_HOST:-root@192.168.1.177}"
BOARD_BENCH="/usr/bin/tensorflow-lite-2.19.0/examples/benchmark_model"
BOARD_MODEL_DIR="/mnt/models"
BOARD_DELEGATE="/usr/lib/libethosu_delegate.so"
THERMAL_PATH="/sys/class/thermal/thermal_zone0/temp"
REMOTEPROC_STATE="/sys/class/remoteproc/remoteproc0/state"

NUM_THREADS=2
WARMUP_RUNS=5
NUM_RUNS=50
MAX_SECS=10000
MIN_SECS=1
NUM_REPS=3
COOLDOWN_SECS=30

# ---- Args -----------------------------------------------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <model_basename>" >&2
  echo "  e.g.: $0 mobilenetv2_w8a8" >&2
  echo "  (looks for ${BOARD_MODEL_DIR}/<basename>_vela.tflite on the board)" >&2
  exit 2
fi
MODEL="$1"
MODEL_FILE="${BOARD_MODEL_DIR}/${MODEL}_vela.tflite"

# ---- Paths (local, on Ubuntu) ---------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${REPO_ROOT}/results/imx93/logs_npu"
mkdir -p "${LOG_DIR}"

# ---- Helpers --------------------------------------------------------------
ssh_board() {
  ssh -o BatchMode=yes -o ConnectTimeout=10 "${BOARD_HOST}" "$@"
}

read_thermal_c() {
  local milli
  milli=$(ssh_board "cat ${THERMAL_PATH}" 2>/dev/null || echo "")
  if [[ -z "${milli}" ]]; then
    echo "n/a"
  else
    awk -v m="${milli}" 'BEGIN { printf "%.1f", m/1000.0 }'
  fi
}

# Same parser as bench_model.sh — second "count=" line is the timed block.
parse_median_us() {
  local logfile="$1"
  grep -E '^INFO: count=' "${logfile}" \
    | sed -n '2p' \
    | grep -oE 'median=[0-9]+' \
    | head -n1 \
    | cut -d= -f2
}

# Preflight: NPU device exists, delegate exists, model exists, M33 is offline.
preflight() {
  echo "[preflight] checking board state..."
  ssh_board "test -x ${BOARD_BENCH}" \
    || { echo "ERROR: benchmark_model not found at ${BOARD_BENCH}" >&2; exit 1; }
  ssh_board "test -e /dev/ethosu0" \
    || { echo "ERROR: /dev/ethosu0 missing — overlays not applied?" >&2; exit 1; }
  ssh_board "test -f ${BOARD_DELEGATE}" \
    || { echo "ERROR: delegate not found at ${BOARD_DELEGATE}" >&2; exit 1; }
  ssh_board "test -f ${MODEL_FILE}" \
    || { echo "ERROR: model not found at ${MODEL_FILE}" >&2; exit 1; }

  local rstate
  rstate=$(ssh_board "cat ${REMOTEPROC_STATE}" 2>/dev/null || echo "unknown")
  if [[ "${rstate}" != "offline" ]]; then
    echo "WARNING: remoteproc state is '${rstate}', expected 'offline'." >&2
    echo "  This means the M33 firmware is already loaded from a prior run." >&2
    echo "  The benchmark will reuse the running M33; first-inference init" >&2
    echo "  cost will be lower than from a cold start. Consider rebooting" >&2
    echo "  the board for clean methodology if this is your first measurement." >&2
  fi

  echo "[preflight] OK: ${MODEL_FILE}, /dev/ethosu0, delegate, remoteproc=${rstate}"
}

# ---- Main -----------------------------------------------------------------
preflight

declare -a MEDIANS_US=()
declare -a TEMP_PRE=()
declare -a TEMP_POST=()
declare -a LOG_FILES=()

echo
echo "======================================================================"
echo "Model:      ${MODEL} (NPU offload via Ethos-U65 delegate)"
echo "Board:      ${BOARD_HOST}"
echo "Config:     ${NUM_THREADS} threads (host), Ethos-U delegate"
echo "            ${WARMUP_RUNS} warmup + ${NUM_RUNS} timed iterations"
echo "Reps:       ${NUM_REPS} (cooldown ${COOLDOWN_SECS}s between)"
echo "Log dir:    ${LOG_DIR}"
echo "======================================================================"

for rep in $(seq 1 "${NUM_REPS}"); do
  ts=$(date +%Y%m%d_%H%M%S)
  log_file="${LOG_DIR}/${MODEL}_npu_rep${rep}_${ts}.log"
  LOG_FILES+=("${log_file}")

  echo
  echo "--- Rep ${rep}/${NUM_REPS} -----------------------------------------"

  pre=$(read_thermal_c)
  TEMP_PRE+=("${pre}")
  echo "[rep ${rep}] thermal pre:  ${pre} C"
  echo "[rep ${rep}] log:          ${log_file}"
  echo "[rep ${rep}] running benchmark..."

  ssh_board "${BOARD_BENCH} \
      --graph=${MODEL_FILE} \
      --external_delegate_path=${BOARD_DELEGATE} \
      --num_threads=${NUM_THREADS} \
      --warmup_runs=${WARMUP_RUNS} \
      --num_runs=${NUM_RUNS} \
      --min_secs=${MIN_SECS} \
      --max_secs=${MAX_SECS} 2>&1" \
    | tee "${log_file}"

  post=$(read_thermal_c)
  TEMP_POST+=("${post}")
  echo "[rep ${rep}] thermal post: ${post} C"

  med_us=$(parse_median_us "${log_file}")
  if [[ -z "${med_us}" ]]; then
    echo "WARNING: could not parse median from ${log_file}" >&2
    MEDIANS_US+=("")
  else
    med_ms=$(awk -v u="${med_us}" 'BEGIN { printf "%.2f", u/1000.0 }')
    echo "[rep ${rep}] median: ${med_ms} ms (${med_us} us)"
    MEDIANS_US+=("${med_us}")
  fi

  if [[ "${rep}" -lt "${NUM_REPS}" ]]; then
    echo "[rep ${rep}] cooldown ${COOLDOWN_SECS}s..."
    sleep "${COOLDOWN_SECS}"
  fi
done

# ---- Summary --------------------------------------------------------------
echo
echo "======================================================================"
echo "Summary: ${MODEL} (NPU)"
echo "======================================================================"

valid_us=()
for v in "${MEDIANS_US[@]}"; do
  [[ -n "$v" ]] && valid_us+=("$v")
done

if [[ "${#valid_us[@]}" -eq 0 ]]; then
  echo "ERROR: no valid medians parsed. Check logs in ${LOG_DIR}." >&2
  exit 1
fi

sorted=$(printf "%s\n" "${valid_us[@]}" | sort -n)
n=${#valid_us[@]}
mid=$(( n / 2 ))
mom_us=$(echo "${sorted}" | sed -n "$((mid+1))p")
mom_ms=$(awk -v u="${mom_us}" 'BEGIN { printf "%.2f", u/1000.0 }')
mom_fps=$(awk -v u="${mom_us}" 'BEGIN { printf "%.2f", 1000000.0/u }')

std_pct=$(printf "%s\n" "${valid_us[@]}" | awk '
  { s+=$1; a[NR]=$1; n++ }
  END {
    if (n<2) { print "n/a"; exit }
    m=s/n
    for (i=1;i<=n;i++) ss+=(a[i]-m)*(a[i]-m)
    sd=sqrt(ss/(n-1))
    printf "%.2f", 100.0*sd/m
  }')

echo
echo "Per-rep medians (ms):"
for i in "${!MEDIANS_US[@]}"; do
  rep_n=$((i+1))
  if [[ -n "${MEDIANS_US[$i]}" ]]; then
    rep_ms=$(awk -v u="${MEDIANS_US[$i]}" 'BEGIN { printf "%.2f", u/1000.0 }')
    echo "  rep ${rep_n}: ${rep_ms} ms   (thermal ${TEMP_PRE[$i]} -> ${TEMP_POST[$i]} C)"
  else
    echo "  rep ${rep_n}: PARSE FAILED  (thermal ${TEMP_PRE[$i]} -> ${TEMP_POST[$i]} C)"
  fi
done

echo
echo "Median-of-medians:  ${mom_ms} ms / ${mom_fps} fps"
echo "Std across reps:    ${std_pct} %"

if [[ "${std_pct}" != "n/a" ]]; then
  is_high=$(awk -v s="${std_pct}" 'BEGIN { print (s+0 > 1.0) ? "1" : "0" }')
  if [[ "${is_high}" == "1" ]]; then
    echo "WARNING: stddev > 1% — consider re-running."
  fi
fi

echo
echo "--- Paste into RESULTS.md --------------------------------------------"
echo "### ${MODEL} (NPU)"
echo ""
echo "| Rep | Median (ms) | Thermal pre/post (C) | Log |"
echo "|---|---|---|---|"
for i in "${!MEDIANS_US[@]}"; do
  rep_n=$((i+1))
  log_basename=$(basename "${LOG_FILES[$i]}")
  if [[ -n "${MEDIANS_US[$i]}" ]]; then
    rep_ms=$(awk -v u="${MEDIANS_US[$i]}" 'BEGIN { printf "%.2f", u/1000.0 }')
    echo "| ${rep_n} | ${rep_ms} | ${TEMP_PRE[$i]} / ${TEMP_POST[$i]} | \`${log_basename}\` |"
  else
    echo "| ${rep_n} | PARSE FAILED | ${TEMP_PRE[$i]} / ${TEMP_POST[$i]} | \`${log_basename}\` |"
  fi
done
echo ""
echo "**Median-of-medians: ${mom_ms} ms / ${mom_fps} fps** (std ${std_pct}% across reps)"
echo "----------------------------------------------------------------------"
