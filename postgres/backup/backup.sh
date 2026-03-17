#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
DUMP_FILE="/tmp/backups/pgdump_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting daily pg_dumpall..."

pg_dumpall -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" | gzip > "$DUMP_FILE"

echo "[$(date)] Dump complete: $(du -h "$DUMP_FILE" | cut -f1)"

export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

rclone copy "$DUMP_FILE" "r2:${R2_BUCKET}/daily/" --s3-no-check-bucket

echo "[$(date)] Uploaded to r2:${R2_BUCKET}/daily/pgdump_${TIMESTAMP}.sql.gz"

rm -f "$DUMP_FILE"

/scripts/prune.sh daily

echo "[$(date)] Daily backup complete."
