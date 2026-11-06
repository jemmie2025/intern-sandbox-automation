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

PEER_DIR="lab/wireguard/peers/$TEAM"

if [[ ! -d "$PEER_DIR" ]]; then
  echo "ABSENT: WireGuard peer for $TEAM"
  exit 0
fi

[[ -s "$PEER_DIR/public.key" ]] || {
  echo "ERROR: Missing peer public key; refusing cleanup" >&2
  exit 1
}

PUBLIC_KEY=$(cat "$PEER_DIR/public.key")

if sudo wg show wg-lab >/dev/null 2>&1; then
  if sudo wg show wg-lab peers | grep -Fxq "$PUBLIC_KEY"; then
    sudo wg set wg-lab peer "$PUBLIC_KEY" remove
    echo "REMOVED: WireGuard peer from wg-lab"
  fi
else
  echo "ERROR: wg-lab unavailable; refusing credential deletion" >&2
  exit 1
fi

rm -f -- "$PEER_DIR/private.key" "$PEER_DIR/public.key" "$PEER_DIR/allowed-ips"
rmdir -- "$PEER_DIR"

echo "PASS: WireGuard teardown completed for $TEAM"
