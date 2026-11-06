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
  JOBS=$(TEAM="$TEAM" python3 - <<'PYCODE'
import json
import os
import urllib.parse
import urllib.request

team = os.environ["TEAM"]
url = os.environ["NOMAD_ADDR"].rstrip("/") + "/v1/jobs?" + urllib.parse.urlencode({"namespace": team})

headers = {}
if os.environ.get("NOMAD_TOKEN"):
    headers["X-Nomad-Token"] = os.environ["NOMAD_TOKEN"]

try:
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=10) as response:
        jobs = json.load(response)
    if not isinstance(jobs, list):
        raise ValueError("Unexpected jobs response")
    print(len(jobs))
except Exception:
    raise SystemExit("ERROR: Cannot verify Nomad jobs; refusing deletion")
PYCODE
)

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
