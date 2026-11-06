#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:-}"
CONFIRM="${2:-}"

[[ "$TEAM" =~ ^lab-team-[0-9]{2}$ ]] || {
  echo "ERROR: Invalid team name" >&2
  exit 1
}

[[ "$CONFIRM" == "--confirm" ]] || {
  echo "ERROR: --confirm required" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK="$ROOT/lab/images/${TEAM}.qcow2"

mapfile -t PIDS < <(
  ps -eo pid=,args= |
  awk -v disk="file=$DISK" '
    $2 ~ /(^|\/)qemu-system-x86_64$/ && index($0, disk) {print $1}
  '
)

if (( ${#PIDS[@]} > 1 )); then
  echo "ERROR: Multiple matching VM processes; refusing shutdown" >&2
  exit 1
fi

if (( ${#PIDS[@]} == 1 )); then
  PID="${PIDS[0]}"
  echo "REQUESTING: Graceful shutdown of $TEAM (PID $PID)"
  if ! command -v socat >/dev/null; then
    echo "ERROR: socat is required for graceful shutdown" >&2
    exit 1
  fi

  SOCKET="$ROOT/lab/qemu/${TEAM}.sock"

  [[ -S "$SOCKET" ]] || {
    echo "ERROR: QEMU monitor unavailable; refusing unsafe shutdown" >&2
    exit 1
  }

  printf 'system_powerdown\n' | socat - UNIX-CONNECT:"$SOCKET"

  STOPPED=false

  for ((i=0; i<60; i++)); do
    if ! kill -0 "$PID" 2>/dev/null; then
      STOPPED=true
      break
    fi
    sleep 2
  done

  if [[ "$STOPPED" != true ]]; then
    echo "ERROR: VM did not stop within 120 seconds; refusing further cleanup" >&2
    exit 1
  fi

  echo "PASS: VM stopped gracefully; disk preserved"
else
  echo "ABSENT: No running VM found for $TEAM"
fi

echo "PASS: VM shutdown request completed"
