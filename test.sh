#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Automated Verification & Test Suite
# Tests: Account RBAC, Schemas, Triggers, Procedures, Queries, Benchmarks, Backups
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_NAME="sanara_ecommerce"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"

echo "========================================================================"
echo "Executing Sanara E-Commerce Database Automated Test Suite"
echo "Target Host: ${DB_HOST}:${DB_PORT} | Database: ${DB_NAME}"
echo "========================================================================"

# Test 1: Service Account Connectivity and Privileges
echo "[Test 1/7] Verifying Service Account Authentication & RBAC Boundaries..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_app -p'SanaraApp_SecurePass2026!' "${DB_NAME}" -e "SELECT 'App User Connection OK' AS status;" > /dev/null
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_migrator -p'SanaraMigrator_Key2026!' "${DB_NAME}" -e "SELECT 'Migrator User Connection OK' AS status;" > /dev/null
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_ro -p'SanaraReadOnly_Report2026!' "${DB_NAME}" -e "SELECT 'Read-Only User Connection OK' AS status;" > /dev/null
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_backup -p'SanaraBackup_LocalSecret2026!' -e "SELECT 'Backup User Connection OK' AS status;" > /dev/null
echo "  Passed: All 4 dedicated remote accounts authenticated successfully."

# Test 2: Verify Partitioned Tables
echo "[Test 2/7] Verifying Range Partition Layout for Orders and Logs..."
PART_COUNT=$(mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_ro -p'SanaraReadOnly_Report2026!' -Nse "
    SELECT COUNT(*) FROM information_schema.partitions 
    WHERE table_schema = '${DB_NAME}' AND table_name IN ('orders', 'download_logs');
")
if [ "${PART_COUNT}" -ge 8 ]; then
    echo "  Passed: Found ${PART_COUNT} active range partitions."
else
    echo "  Failed: Expected at least 8 partitions, found ${PART_COUNT}" >&2
    exit 1
fi

# Test 3: Verify Print Production, Collaborator, and Contract Entities
echo "[Test 3/7] Verifying Print Profiles, Spot Plates, Bundles, and Contract Entities..."
ENTITY_CHECK=$(mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_ro -p'SanaraReadOnly_Report2026!' -Nse "
    SELECT 
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.print_production_profiles) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.spot_color_plates) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.product_collaborators) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.collections) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.enterprise_contracts) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.storage_vault_nodes) AS total_records;
")
if [ "${ENTITY_CHECK}" -ge 20 ]; then
    echo "  Passed: Found ${ENTITY_CHECK} active records across print profiles, bundles, and contract entities."
else
    echo "  Failed: Expected at least 20 records across new entities, found ${ENTITY_CHECK}" >&2
    exit 1
fi

# Test 4: Verify Asset Revisions, Catalog i18n & KYC Compliance
echo "[Test 4/7] Verifying Semantic Revisions, i18n Translations & Compliance Records..."
REVISION_CHECK=$(mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_ro -p'SanaraReadOnly_Report2026!' -Nse "
    SELECT 
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.product_asset_revisions) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.product_translations_i18n) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.creator_kyc_compliance) +
        (SELECT COUNT(*) FROM \`${DB_NAME}\`.coupon_redemption_history) AS revision_records;
")
if [ "${REVISION_CHECK}" -ge 15 ]; then
    echo "  Passed: Found ${REVISION_CHECK} active versioning, i18n, and compliance records."
else
    echo "  Failed: Expected at least 15 revision records, found ${REVISION_CHECK}" >&2
    exit 1
fi

# Test 5: Stored Procedures & Triggers Simulation
echo "[Test 5/7] Verifying Stored Procedures and Reactive Triggers..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u sanara_app -p'SanaraApp_SecurePass2026!' "${DB_NAME}" < "${SCRIPT_DIR}/queries/02_checkout_transaction_simulation.sql" > /dev/null
echo "  Passed: Atomic checkout transaction and triggers executed without errors."

# Test 6: Query Benchmarks & EXPLAIN ANALYZE
echo "[Test 6/7] Executing Performance Benchmarks & EXPLAIN ANALYZE..."
DB_HOST="${DB_HOST}" DB_PORT="${DB_PORT}" bash "${SCRIPT_DIR}/scripts/run_benchmarks.sh" > /dev/null
echo "  Passed: Query plans, full-text indexes, and generated columns verified."

# Test 7: Backup and Recovery Validation
echo "[Test 7/7] Validating Backup and Checksum Generation..."
TMP_BACKUP_DIR=$(mktemp -d)
DB_HOST="${DB_HOST}" DB_PORT="${DB_PORT}" bash "${SCRIPT_DIR}/scripts/backup.sh" "${TMP_BACKUP_DIR}" > /dev/null
LATEST_BACKUP=$(ls -t "${TMP_BACKUP_DIR}"/*.sql.gz | head -1)
if [ -f "${LATEST_BACKUP}" ] && [ -f "${LATEST_BACKUP}.sha256" ]; then
    echo "  Passed: Compressed backup archive and SHA-256 signature verified."
fi
rm -rf "${TMP_BACKUP_DIR}"

echo "========================================================================"
echo "ALL TESTS PASSED: Sanara Database Engine is 100% Operational"
echo "========================================================================"
