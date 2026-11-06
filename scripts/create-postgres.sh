#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:?Usage: create-postgres.sh lab-team-03}"

if [[ ! "$TEAM" =~ ^lab-team-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid team name: $TEAM" >&2
  exit 1
fi

DB_NAME="${TEAM//-/_}"

if ! sudo -n -u postgres psql -d postgres \
  -v ON_ERROR_STOP=1 -Atc "SELECT 1" >/dev/null 2>&1; then
  echo "ERROR: PostgreSQL administrator access unavailable" >&2
  exit 1
fi

ROLE_EXISTS=$(sudo -n -u postgres psql -d postgres \
  -v ON_ERROR_STOP=1 -Atc \
  "SELECT 1 FROM pg_roles WHERE rolname = '$DB_NAME'")

DB_EXISTS=$(sudo -n -u postgres psql -d postgres \
  -v ON_ERROR_STOP=1 -Atc \
  "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'")

if [[ "$ROLE_EXISTS" == "1" ]]; then
  echo "EXISTS: PostgreSQL role $DB_NAME"
else
  echo "MISSING: PostgreSQL role $DB_NAME"
fi

if [[ "$DB_EXISTS" == "1" ]]; then
  echo "EXISTS: PostgreSQL database $DB_NAME"
else
  if [[ "$ROLE_EXISTS" != "1" ]]; then
    echo "ERROR: PostgreSQL role $DB_NAME must exist before database creation" >&2
    exit 1
  fi

  sudo -u postgres createdb --owner="$DB_NAME" -- "$DB_NAME"
  echo "CREATED: PostgreSQL database $DB_NAME"
fi

sudo -u postgres psql -d postgres -v ON_ERROR_STOP=1 \
  -v db="$DB_NAME" <<'SQL'
SELECT format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC', :'db') \gexec
SQL

echo "PASS: PostgreSQL database provisioned with restricted public access"
