#!/usr/bin/env bash
set -euo pipefail

TEAM="${1:?Usage: delete-s3-bucket.sh TEAM --confirm}"
CONFIRM="${2:-}"

if [[ ! "$TEAM" =~ ^lab-team-[0-9]{2}$ ]]; then
  echo "ERROR: Invalid team name" >&2
  exit 1
fi

if [[ "$CONFIRM" != "--confirm" ]]; then
  echo "ERROR: Explicit --confirm required" >&2
  exit 1
fi

CONTAINER="intern-sandbox-s3"

if ! docker inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -qx true; then
  echo "ERROR: LocalStack is not running" >&2
  exit 1
fi

if ! docker exec "$CONTAINER" awslocal s3api head-bucket \
  --bucket "$TEAM" >/dev/null 2>&1; then
  echo "ABSENT: S3 bucket $TEAM"
  exit 0
fi

OBJECTS=$(docker exec "$CONTAINER" awslocal s3api \
  list-objects-v2 --bucket "$TEAM" --query 'KeyCount' --output text)

if [[ "$OBJECTS" != "0" && "$OBJECTS" != "None" && "$OBJECTS" != "null" ]]; then
  echo "ERROR: Bucket contains objects; refusing deletion" >&2
  exit 1
fi

docker exec "$CONTAINER" awslocal s3api delete-bucket \
  --bucket "$TEAM"

echo "DELETED: S3 bucket $TEAM"
