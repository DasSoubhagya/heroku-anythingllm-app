#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="/tmp/backups/basebackup_${TIMESTAMP}"
ARCHIVE_FILE="/tmp/backups/basebackup_${TIMESTAMP}.tar.gz"

echo "[$(date)] Starting weekly pg_basebackup..."

mkdir -p "$BACKUP_DIR"

pg_basebackup -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -D "$BACKUP_DIR" -Ft -z -Xs

tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" .

echo "[$(date)] Base backup complete: $(du -h "$ARCHIVE_FILE" | cut -f1)"

export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

rclone copy "$ARCHIVE_FILE" "r2:${R2_BUCKET}/weekly/" --s3-no-check-bucket

echo "[$(date)] Uploaded to r2:${R2_BUCKET}/weekly/basebackup_${TIMESTAMP}.tar.gz"

rm -rf "$BACKUP_DIR" "$ARCHIVE_FILE"

/scripts/prune.sh weekly

echo "[$(date)] Weekly base backup complete."
