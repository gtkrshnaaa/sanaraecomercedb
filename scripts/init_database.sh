#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Database Initialization & Loader Script
# Sequentially applies all schema migrations, routines, triggers, and seeds
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DB_NAME="sanara_ecommerce"
MIGRATOR_USER="sanara_migrator"
MIGRATOR_PASS="SanaraMigrator_Key2026!"

echo "========================================================================"
echo "Initializing Sanara E-Commerce Database Architecture"
echo "========================================================================"

# Step 1: Base Database & RBAC Users
echo "[1/4] Provisioning database and dedicated remote RBAC accounts..."
mysql < "${PROJECT_ROOT}/schema/01_database_and_users.sql"

# Step 2: DDL Schemas in Dependency Order
echo "[2/4] Applying core database schemas and tables..."
for schema_file in \
    "${PROJECT_ROOT}/schema/02_iam_and_creators.sql" \
    "${PROJECT_ROOT}/schema/03_catalog_and_products.sql" \
    "${PROJECT_ROOT}/schema/04_variants_licenses_pricing.sql" \
    "${PROJECT_ROOT}/schema/05_orders_and_transactions.sql" \
    "${PROJECT_ROOT}/schema/06_delivery_and_entitlements.sql" \
    "${PROJECT_ROOT}/schema/07_wallets_and_payouts.sql" \
    "${PROJECT_ROOT}/schema/08_reviews_and_auditing.sql" \
    "${PROJECT_ROOT}/schema/09_triggers.sql" \
    "${PROJECT_ROOT}/schema/10_stored_procedures_functions.sql" \
    "${PROJECT_ROOT}/schema/11_views.sql"
do
    filename=$(basename "${schema_file}")
    echo "  Applying ${filename}..."
    mysql -u "${MIGRATOR_USER}" -p"${MIGRATOR_PASS}" "${DB_NAME}" < "${schema_file}"
done

# Step 3: Seed Datasets in Order
echo "[3/4] Ingesting rich production seed datasets..."
for seed_file in \
    "${PROJECT_ROOT}/seeds/01_seed_iam_creators.sql" \
    "${PROJECT_ROOT}/seeds/02_seed_catalog_categories.sql" \
    "${PROJECT_ROOT}/seeds/03_seed_products_assets.sql" \
    "${PROJECT_ROOT}/seeds/04_seed_orders_entitlements.sql" \
    "${PROJECT_ROOT}/seeds/05_seed_wallets_reviews.sql"
do
    filename=$(basename "${seed_file}")
    echo "  Loading ${filename}..."
    mysql -u "${MIGRATOR_USER}" -p"${MIGRATOR_PASS}" "${DB_NAME}" < "${seed_file}"
done

# Step 4: Verification Summary
echo "[4/4] Verifying database integrity..."
mysql -u sanara_app -p'SanaraApp_SecurePass2026!' "${DB_NAME}" -e "
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}' AND table_type='BASE TABLE') AS base_tables_count,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='${DB_NAME}') AS views_count,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='${DB_NAME}') AS routines_count,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders;
"

echo "SUCCESS: Sanara E-Commerce database initialized and verified."
