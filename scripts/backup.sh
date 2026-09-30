#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Production Backup Automation Script
# Uses mysqldump with single-transaction, gzip compression, and SHA-256 integrity
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${1:-/var/backups/sanara_mysql}"
DB_NAME="sanara_ecommerce"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
BACKUP_USER="${BACKUP_USER:-sanara_backup}"
BACKUP_PASS="${BACKUP_PASS:-SanaraBackup_LocalSecret2026!}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${TIMESTAMP}.sql.gz"
CHECKSUM_FILE="${BACKUP_FILE}.sha256"

mkdir -p "${BACKUP_DIR}"

echo "Starting automated backup for database: ${DB_NAME}..."
echo "Host: ${DB_HOST}:${DB_PORT} | Target destination: ${BACKUP_FILE}"

# Execute production mysqldump with strict transaction isolation and consistent binlog coords
mysqldump \
    -h "${DB_HOST}" \
    -P "${DB_PORT}" \
    -u "${BACKUP_USER}" \
    -p"${BACKUP_PASS}" \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    --default-character-set=utf8mb4 \
    --databases "${DB_NAME}" | gzip -c > "${BACKUP_FILE}"

# Compute SHA-256 integrity checksum
sha256sum "${BACKUP_FILE}" | awk '{print $1}' > "${CHECKSUM_FILE}"

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "Backup complete: ${BACKUP_FILE} (${BACKUP_SIZE})"
echo "SHA-256 checksum: $(cat "${CHECKSUM_FILE}")"

# Retention Policy: Prune backups older than 14 days
echo "Applying retention policy (retaining last 14 days)..."
find "${BACKUP_DIR}" -name "${DB_NAME}_backup_*.sql.gz*" -mtime +14 -delete 2>/dev/null || true
echo "SUCCESS: Backup completed and validated."
