#!/usr/bin/env bash
set -euo pipefail
umask 077

TEAM="${1:-}"

[[ "$TEAM" =~ ^lab-team-[0-9]{2}$ ]] || {
  echo "ERROR: Invalid team name" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="$ROOT/lab/images/ubuntu-22.04-base.img"
DISK="$ROOT/lab/images/${TEAM}.qcow2"
SEED="$ROOT/lab/cloud-init/${TEAM}-seed.img"
META="$ROOT/lab/cloud-init/${TEAM}-meta-data"
USER_DATA="$ROOT/lab/cloud-init/user-data"
SSH_PORT=$((2200 + 10#${TEAM##*-} - 1))

for cmd in qemu-img cloud-localds qemu-system-x86_64; do
  command -v "$cmd" >/dev/null || {
    echo "ERROR: Missing dependency: $cmd" >&2
    exit 1
  }
done

[[ -f "$BASE" && -f "$USER_DATA" ]] || {
  echo "ERROR: Missing base image or cloud-init user-data" >&2
  exit 1
}

if [[ ! -f "$DISK" ]]; then
  qemu-img create -f qcow2 -F qcow2 \
    -b "$BASE" "$DISK" 20G
  echo "CREATED: VM disk for $TEAM"
else
  echo "EXISTS: VM disk for $TEAM"
fi

if [[ ! -f "$SEED" ]]; then
  printf 'instance-id: %s-001\nlocal-hostname: %s\n' \
    "$TEAM" "$TEAM" > "$META"

  cloud-localds "$SEED" "$USER_DATA" "$META"
  echo "CREATED: Cloud-init seed for $TEAM"
fi

echo "PASS: VM storage prepared for $TEAM"
echo "SSH port: $SSH_PORT"
if ps -eo args= | grep '[q]emu-system-x86_64' | grep -F -- "file=$DISK," >/dev/null; then
  echo "EXISTS: VM already running for $TEAM"
else
  if ss -ltn | grep -qE "127\.0\.0\.1:$SSH_PORT[[:space:]]"; then
    echo "ERROR: SSH port $SSH_PORT is already in use" >&2
    exit 1
  fi

  mkdir -p "$ROOT/lab/qemu"
  SOCKET="$ROOT/lab/qemu/${TEAM}.sock"

  if [[ -e "$SOCKET" ]]; then
    if [[ -S "$SOCKET" ]] &&
       command -v socat >/dev/null 2>&1 &&
       printf 'info status\n' | timeout 3 socat - UNIX-CONNECT:"$SOCKET" >/dev/null 2>&1; then
      echo "ERROR: Active QEMU monitor detected; refusing duplicate startup" >&2
      exit 1
    fi

    if ps -eo args= | grep '[q]emu-system-x86_64' | grep -F -- "file=$DISK," >/dev/null; then
      echo "ERROR: VM process exists; refusing socket removal" >&2
      exit 1
    fi

    if command -v fuser >/dev/null 2>&1 && fuser "$SOCKET" >/dev/null 2>&1; then
      echo "ERROR: Socket is in use; refusing removal" >&2
      exit 1
    fi

    rm -- "$SOCKET"
    echo "RECOVERED: Removed stale monitor socket for $TEAM"
  fi

  qemu-system-x86_64 \
    -monitor "unix:$SOCKET,server=on,wait=off" \
    -enable-kvm \
    -cpu host \
    -machine q35 \
    -m 2048 \
    -smp 2 \
    -drive "file=$DISK,format=qcow2" \
    -drive "file=$SEED,format=raw,media=cdrom" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
    -device virtio-net-pci,netdev=net0 \
    -display none \
    -daemonize

  echo "STARTED: VM $TEAM on SSH port $SSH_PORT"
fi
