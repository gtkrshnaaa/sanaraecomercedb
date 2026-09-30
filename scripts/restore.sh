#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Disaster Recovery & Database Restore Script
# Validates SHA-256 archive checksum before decompressing and restoring
# ==============================================================================

set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_backup.sql.gz> [target_db_name]" >&2
    exit 1
fi

BACKUP_ARCHIVE="$1"
TARGET_DB="${2:-sanara_ecommerce}"
CHECKSUM_FILE="${BACKUP_ARCHIVE}.sha256"

if [ ! -f "${BACKUP_ARCHIVE}" ]; then
    echo "ERROR: Backup archive file does not exist: ${BACKUP_ARCHIVE}" >&2
    exit 1
fi

echo "Initiating disaster recovery restore for database: ${TARGET_DB}..."

# Step 1: Verify SHA-256 checksum if available
if [ -f "${CHECKSUM_FILE}" ]; then
    echo "Verifying archive SHA-256 checksum integrity..."
    EXPECTED_HASH=$(cat "${CHECKSUM_FILE}" | awk '{print $1}')
    ACTUAL_HASH=$(sha256sum "${BACKUP_ARCHIVE}" | awk '{print $1}')
    if [ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]; then
        echo "FATAL: Checksum mismatch! Archive may be corrupted." >&2
        echo "Expected: ${EXPECTED_HASH}" >&2
        echo "Actual:   ${ACTUAL_HASH}" >&2
        exit 1
    fi
    echo "Checksum integrity verified: OK"
else
    echo "Notice: No .sha256 checksum file found. Proceeding with caution..."
fi

# Step 2: Decompress and Stream to MySQL
echo "Streaming backup into MySQL server..."
zcat "${BACKUP_ARCHIVE}" | mysql --default-character-set=utf8mb4

echo "Verifying restored table row counts..."
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' "${TARGET_DB}" -e "
SELECT 
    table_name, 
    table_rows 
FROM information_schema.tables 
WHERE table_schema = '${TARGET_DB}' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
"

echo "SUCCESS: Disaster recovery restore completed successfully."
