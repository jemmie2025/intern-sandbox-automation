#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:-}"
CONFIRM="${2:-}"

[[ "$TEAM" =~ ^lab-team-[0-9]{2}$ ]] || {
  echo "ERROR: Invalid team name" >&2
  exit 1
}

[[ "$CONFIRM" == "--confirm" ]] || {
  echo "ERROR: --confirm is required" >&2
  exit 1
}

DB_NAME="${TEAM//-/_}"
ROLE_NAME="$DB_NAME"

echo "Removing PostgreSQL resources for $TEAM"

cd /tmp

DB_OWNER=$(sudo -u postgres psql -d postgres -Atqc   "SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname='$DB_NAME'")

if [[ -n "$DB_OWNER" && "$DB_OWNER" != "$ROLE_NAME" ]]; then
  echo "ERROR: Database ownership mismatch. Refusing deletion." >&2
  exit 1
fi


cd /tmp

if [[ -n "$DB_OWNER" ]]; then
  ACTIVE_CONNECTIONS=$(sudo -u postgres psql -d postgres -Atqc \
    "SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME'")

  if (( ACTIVE_CONNECTIONS > 0 )); then
    echo "ERROR: $ACTIVE_CONNECTIONS active database connection(s). Refusing deletion." >&2
    exit 1
  fi
fi

if sudo -u postgres psql -d postgres -Atqc \
  "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -qx 1; then
  sudo -u postgres dropdb --if-exists -- "$DB_NAME"
  echo "REMOVED: Database $DB_NAME"
fi

if sudo -u postgres psql -d postgres -Atqc \
  "SELECT 1 FROM pg_roles WHERE rolname='$ROLE_NAME'" | grep -qx 1; then
  sudo -u postgres dropuser --if-exists -- "$ROLE_NAME"
  echo "REMOVED: Role $ROLE_NAME"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREDENTIAL_FILE="$ROOT/lab/postgres/${TEAM}.password"

REMAINING_ROLE=$(sudo -u postgres psql -X   -v ON_ERROR_STOP=1 -d postgres -Atc   "SELECT 1 FROM pg_roles WHERE rolname='$ROLE_NAME'")

if [[ "$REMAINING_ROLE" == "1" ]]; then
  echo "ERROR: PostgreSQL role still exists; credentials preserved" >&2
  exit 1
fi

if [[ -L "$CREDENTIAL_FILE" ]]; then
  echo "ERROR: Credential path is a symbolic link; refusing cleanup" >&2
  exit 1
fi

if [[ -f "$CREDENTIAL_FILE" ]]; then
  rm -- "$CREDENTIAL_FILE"
  echo "REMOVED: PostgreSQL credential file for $TEAM"
fi

echo "PASS: PostgreSQL teardown completed for $TEAM"
