#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:?Usage: create-s3-bucket.sh lab-team-03}"

if [[ ! "$TEAM" =~ ^lab-team-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid team name: $TEAM" >&2
  exit 1
fi

CONTAINER="intern-sandbox-s3"

if ! docker inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -qx true; then
  echo "ERROR: LocalStack container is not running" >&2
  exit 1
fi

if docker exec "$CONTAINER" awslocal s3api head-bucket --bucket "$TEAM" >/dev/null 2>&1; then
  echo "EXISTS: S3 bucket $TEAM"
else
  docker exec "$CONTAINER" awslocal s3api create-bucket \
    --bucket "$TEAM" \
    --region us-east-1
  echo "CREATED: S3 bucket $TEAM"
fi
