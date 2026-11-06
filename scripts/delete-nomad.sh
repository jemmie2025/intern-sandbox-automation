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

command -v nomad >/dev/null || {
  echo "ERROR: Nomad CLI unavailable" >&2
  exit 1
}

: "${NOMAD_ADDR:=http://127.0.0.1:4646}"
export NOMAD_ADDR

[[ "$NOMAD_ADDR" == "http://127.0.0.1:4646" ||
   "$NOMAD_ADDR" == "http://localhost:4646" ]] || {
  echo "ERROR: Only local Nomad lab permitted" >&2
  exit 1
}

if nomad namespace status "$TEAM" >/dev/null 2>&1; then
  JOBS=$(nomad job status -namespace="$TEAM" -json | python3 -c '
import json,sys
data=json.load(sys.stdin)
print(len(data) if isinstance(data,list) else 0)
')

  if (( JOBS > 0 )); then
    echo "ERROR: Namespace contains jobs. Refusing deletion." >&2
    exit 1
  fi

  nomad namespace delete "$TEAM"
  echo "REMOVED: Nomad namespace $TEAM"
else
  echo "ABSENT: Nomad namespace $TEAM"
fi

if nomad acl policy info "$TEAM" >/dev/null 2>&1; then
  nomad acl policy delete "$TEAM"
  echo "REMOVED: Nomad ACL policy $TEAM"
fi

echo "PASS: Nomad teardown completed for $TEAM"
