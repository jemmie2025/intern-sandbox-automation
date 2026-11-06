#!/usr/bin/env bash
set -euo pipefail
umask 077

TEAM="${1:?Usage: create-postgres-role.sh lab-team-04}"

if [[ ! "$TEAM" =~ ^lab-team-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid team name" >&2
  exit 1
fi

ROLE="${TEAM//-/_}"
CREDENTIAL_FILE="lab/postgres/${TEAM}.password"

if [[ -e "$CREDENTIAL_FILE" ]]; then
  [[ ! -L "$CREDENTIAL_FILE" && -f "$CREDENTIAL_FILE" && -s "$CREDENTIAL_FILE" ]] || {
    echo "ERROR: Existing credential file is invalid" >&2
    exit 1
  }

  EXISTS=$(sudo -u postgres psql -X -v ON_ERROR_STOP=1     -d postgres -Atc     "SELECT 1 FROM pg_roles WHERE rolname = '$ROLE'")

  if [[ "$EXISTS" == "1" ]]; then
    echo "EXISTS: PostgreSQL role and credentials preserved for $TEAM"
    exit 0
  fi

  echo "ERROR: Credentials exist but role is absent; manual recovery required" >&2
  exit 1
fi

if ! sudo -u postgres psql -d postgres \
  -v ON_ERROR_STOP=1 -Atc "SELECT 1" >/dev/null; then
  echo "ERROR: PostgreSQL administrator access unavailable" >&2
  exit 1
fi

EXISTS=$(sudo -u postgres psql -d postgres \
  -v ON_ERROR_STOP=1 -Atc \
  "SELECT 1 FROM pg_roles WHERE rolname = '$ROLE'")

if [[ "$EXISTS" == "1" ]]; then
  echo "EXISTS: PostgreSQL role $ROLE; no changes made"
  exit 0
fi

PASSWORD=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')

install -m 600 /dev/null "$CREDENTIAL_FILE"
printf '%s\n' "$PASSWORD" > "$CREDENTIAL_FILE"

if ! ROLE_NAME="$ROLE" ROLE_PASSWORD="$PASSWORD" python3 - <<'PYSQL' | sudo -u postgres psql -d postgres -v ON_ERROR_STOP=1 >/dev/null
import os
role = os.environ["ROLE_NAME"]
password = os.environ["ROLE_PASSWORD"]
def quote(value):
    return "'" + value.replace("'", "''") + "'"
print(
    "CREATE ROLE " + role +
    " LOGIN PASSWORD " + quote(password) +
    " NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;"
)
PYSQL
then
  echo "ERROR: Role creation failed; review credentials before retrying" >&2
  if sudo -u postgres psql -d postgres     -v ON_ERROR_STOP=1 -Atc     "SELECT 1 FROM pg_roles WHERE rolname = '$ROLE'" | grep -qx 1; then
    echo "ERROR: Role exists; credentials retained for recovery" >&2
  else
    echo "ERROR: Role absence not yet confirmed; credentials retained" >&2
  fi
  exit 1
fi

unset PASSWORD
echo "CREATED: Restricted PostgreSQL role $ROLE"
