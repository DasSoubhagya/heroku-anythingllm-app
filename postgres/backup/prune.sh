#!/bin/bash
set -euo pipefail

SUBFOLDER="${1:-daily}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
CUTOFF_DATE=$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y-%m-%d)

echo "[$(date)] Pruning ${SUBFOLDER}/ backups older than ${RETENTION_DAYS} days (before ${CUTOFF_DATE})..."

export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

DELETED=0

rclone lsf "r2:${R2_BUCKET}/${SUBFOLDER}/" --files-only 2>/dev/null | while read -r file; do
  FILE_DATE=$(echo "$file" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)

  if [ -z "$FILE_DATE" ]; then
    continue
  fi

  if [[ "$FILE_DATE" < "$CUTOFF_DATE" ]]; then
    echo "  Deleting: ${file}"
    rclone deletefile "r2:${R2_BUCKET}/${SUBFOLDER}/${file}" --s3-no-check-bucket
    DELETED=$((DELETED + 1))
  fi
done

echo "[$(date)] Pruning complete. Removed ${DELETED} old backup(s)."
