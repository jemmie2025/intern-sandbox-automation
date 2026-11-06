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
echo "STATUS: VM launch integration pending"
