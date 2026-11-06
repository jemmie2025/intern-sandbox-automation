#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:-}"

[[ "$TEAM" =~ ^lab-team-[0-9]{2}$ ]] || {
  echo "ERROR: Invalid team name" >&2
  exit 1
}

command -v nomad >/dev/null || {
  echo "ERROR: Nomad CLI not installed" >&2
  exit 1
}

: "${NOMAD_ADDR:=http://127.0.0.1:4646}"
export NOMAD_ADDR

[[ "$NOMAD_ADDR" == "http://127.0.0.1:4646" ||
   "$NOMAD_ADDR" == "http://localhost:4646" ]] || {
  echo "ERROR: Only local Nomad lab access is permitted" >&2
  exit 1
}

nomad status >/dev/null || {
  echo "ERROR: Local Nomad agent unavailable or access denied" >&2
  exit 1
}

if ! nomad namespace status "$TEAM" >/dev/null 2>&1; then
  nomad namespace apply -description "Isolated intern sandbox $TEAM" "$TEAM"
  echo "CREATED: Nomad namespace $TEAM"
else
  echo "EXISTS: Nomad namespace $TEAM"
fi

mkdir -p lab/nomad

POLICY_FILE="lab/nomad/${TEAM}.hcl"

cat > "$POLICY_FILE" <<POLICY
namespace "$TEAM" {
  policy = "read"
  capabilities = [
    "submit-job",
    "dispatch-job",
    "read-job"
  ]
}
POLICY

nomad acl policy apply "$TEAM" "$POLICY_FILE"

echo "PASS: Nomad namespace and ACL policy provisioned for $TEAM"
