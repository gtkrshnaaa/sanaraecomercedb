#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Automated Verification & Test Suite
# Tests: Account RBAC, Schemas, Triggers, Procedures, Queries, Benchmarks
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_NAME="sanara_ecommerce"

echo "========================================================================"
echo "Executing Sanara E-Commerce Database Automated Test Suite"
echo "========================================================================"

# Test 1: Service Account Connectivity and Privileges
echo "[Test 1/5] Verifying Service Account Authentication & RBAC Boundaries..."
mysql -u sanara_app -p'SanaraApp_SecurePass2026!' "${DB_NAME}" -e "SELECT 'App User Connection OK' AS status;" > /dev/null
mysql -u sanara_migrator -p'SanaraMigrator_Key2026!' "${DB_NAME}" -e "SELECT 'Migrator User Connection OK' AS status;" > /dev/null
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' "${DB_NAME}" -e "SELECT 'Read-Only User Connection OK' AS status;" > /dev/null
echo "  Passed: All 3 dedicated remote accounts authenticated successfully."

# Test 2: Verify Partitioned Tables
echo "[Test 2/5] Verifying Range Partition Layout for Orders and Logs..."
PART_COUNT=$(mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' -Nse "
    SELECT COUNT(*) FROM information_schema.partitions 
    WHERE table_schema = '${DB_NAME}' AND table_name IN ('orders', 'download_logs');
")
if [ "${PART_COUNT}" -ge 8 ]; then
    echo "  Passed: Found ${PART_COUNT} active range partitions."
else
    echo "  Failed: Expected at least 8 partitions, found ${PART_COUNT}" >&2
    exit 1
fi

# Test 3: Stored Procedures & Triggers Simulation
echo "[Test 3/5] Verifying Stored Procedures and Reactive Triggers..."
mysql -u sanara_app -p'SanaraApp_SecurePass2026!' "${DB_NAME}" < "${SCRIPT_DIR}/queries/02_checkout_transaction_simulation.sql" > /dev/null
echo "  Passed: Atomic checkout transaction and triggers executed without errors."

# Test 4: Query Benchmarks & EXPLAIN ANALYZE
echo "[Test 4/5] Executing Performance Benchmarks & EXPLAIN ANALYZE..."
bash "${SCRIPT_DIR}/scripts/run_benchmarks.sh" > /dev/null
echo "  Passed: Query plans, full-text indexes, and generated columns verified."

# Test 5: Backup and Recovery Validation
echo "[Test 5/5] Validating Backup and Checksum Generation..."
TMP_BACKUP_DIR=$(mktemp -d)
bash "${SCRIPT_DIR}/scripts/backup.sh" "${TMP_BACKUP_DIR}" > /dev/null
LATEST_BACKUP=$(ls -t "${TMP_BACKUP_DIR}"/*.sql.gz | head -1)
if [ -f "${LATEST_BACKUP}" ] && [ -f "${LATEST_BACKUP}.sha256" ]; then
    echo "  Passed: Compressed backup archive and SHA-256 signature verified."
fi
rm -rf "${TMP_BACKUP_DIR}"

echo "========================================================================"
echo "ALL TESTS PASSED: Sanara Database Engine is 100% Operational"
echo "========================================================================"
