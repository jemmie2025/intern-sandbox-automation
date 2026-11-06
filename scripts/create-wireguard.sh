#!/usr/bin/env bash
set -euo pipefail
umask 077

TEAM="${1:-}"

[[ "$TEAM" =~ ^lab-team-[0-9]{2}$ ]] || {
  echo "ERROR: Invalid team name" >&2
  exit 1
}

command -v wg >/dev/null || {
  echo "ERROR: WireGuard CLI unavailable" >&2
  exit 1
}

TEAM_NUMBER="${TEAM##*-}"
PEER_IP="10.77.3.$((10#$TEAM_NUMBER + 10))"
PEER_DIR="lab/wireguard/peers/$TEAM"

if [[ -d "$PEER_DIR" ]]; then
  [[ -s "$PEER_DIR/private.key" &&
     -s "$PEER_DIR/public.key" &&
     -s "$PEER_DIR/allowed-ips" ]] || {
    echo "ERROR: Incomplete existing peer credentials" >&2
    exit 1
  }

  [[ "$(cat "$PEER_DIR/allowed-ips")" == "$PEER_IP/32" ]] || {
    echo "ERROR: Existing peer IP does not match expected allocation" >&2
    exit 1
  }

  echo "EXISTS: Reusing WireGuard credentials for $TEAM"
else
  mkdir -p "$PEER_DIR"
  wg genkey > "$PEER_DIR/private.key"
  wg pubkey < "$PEER_DIR/private.key" > "$PEER_DIR/public.key"
  printf '%s\n' "$PEER_IP/32" > "$PEER_DIR/allowed-ips"
fi

echo "CREATED: WireGuard peer credentials for $TEAM"
echo "Assigned IP: $PEER_IP/32"
if sudo wg show wg-lab >/dev/null 2>&1; then
  sudo wg set wg-lab \
    peer "$(cat "$PEER_DIR/public.key")" \
    allowed-ips "$(cat "$PEER_DIR/allowed-ips")"

  echo "PASS: WireGuard peer registered on wg-lab"
else
  echo "WARNING: wg-lab is unavailable; peer registration pending"
fi
