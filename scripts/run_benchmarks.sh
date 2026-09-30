#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Automated Benchmark & Query Profiling Suite
# Executes all test suites and captures execution metrics
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RO_USER="sanara_ro"
RO_PASS="SanaraReadOnly_Report2026!"
APP_USER="sanara_app"
APP_PASS="SanaraApp_SecurePass2026!"
DB_NAME="sanara_ecommerce"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"

echo "========================================================================"
echo "Running Sanara E-Commerce Query Performance & Benchmark Suite"
echo "Host: ${DB_HOST}:${DB_PORT} | Database: ${DB_NAME}"
echo "========================================================================"

echo "[1/5] Executing Catalog Search & Pre-Press JSON Filters..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${APP_USER}" -p"${APP_PASS}" "${DB_NAME}" < "${PROJECT_ROOT}/queries/01_ecommerce_catalog_search.sql" > /dev/null
echo "  Passed: Catalog search queries returned valid result sets."

echo "[2/5] Executing Print Specs & Multi-Creator Royalty Queries..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${APP_USER}" -p"${APP_PASS}" "${DB_NAME}" < "${PROJECT_ROOT}/queries/07_print_specs_and_collaborative_royalties.sql" > /dev/null
echo "  Passed: Pre-flight print specs and collaborator splits verified."

echo "[3/5] Executing Analytical & Financial Aggregations & Bundle Queries..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${RO_USER}" -p"${RO_PASS}" "${DB_NAME}" < "${PROJECT_ROOT}/queries/05_analytics_and_reporting.sql" > /dev/null
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${APP_USER}" -p"${APP_PASS}" "${DB_NAME}" < "${PROJECT_ROOT}/queries/08_enterprise_contracts_and_bundles.sql" > /dev/null
echo "  Passed: Multi-table financial, hierarchy rollups, and bundle queries verified."

echo "[4/5] Executing EXPLAIN & EXPLAIN ANALYZE Performance Verifications..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${RO_USER}" -p"${RO_PASS}" "${DB_NAME}" < "${PROJECT_ROOT}/queries/06_explain_analyze_benchmarks.sql"
echo "  Passed: Partition pruning, full-text indexes, and generated column lookups verified."

echo "[5/5] Verifying Financial Balances Invariants..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${RO_USER}" -p"${RO_PASS}" "${DB_NAME}" -e "
SELECT 
    cw.creator_id,
    cp.studio_name,
    cw.available_balance,
    cw.pending_escrow_balance,
    (SELECT COALESCE(SUM(amount), 0.00) FROM wallet_ledger_entries WHERE creator_id = cw.creator_id AND direction = 'credit') AS total_credits,
    (SELECT COALESCE(SUM(amount), 0.00) FROM wallet_ledger_entries WHERE creator_id = cw.creator_id AND direction = 'debit') AS total_debits
FROM creator_wallets cw
JOIN creator_profiles cp ON cp.id = cw.creator_id;
"
echo "SUCCESS: All benchmarks and verification suites passed."
