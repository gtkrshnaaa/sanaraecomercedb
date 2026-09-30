#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Automated Partition Maintenance Script
# Purpose: Dynamically reorganizes p_future to provision upcoming annual partitions
# ==============================================================================

set -euo pipefail

NEXT_YEAR="${1:-$(($(date +'%Y') + 2))}"
SPLIT_YEAR="$((NEXT_YEAR + 1))"
MIGRATOR_USER="sanara_migrator"
MIGRATOR_PASS="SanaraMigrator_Key2026!"
DB_NAME="sanara_ecommerce"

echo "Checking partition reorganization for target year: ${NEXT_YEAR}..."

for table_name in "orders" "download_logs"; do
    echo "  Inspecting partitions for table: ${table_name}..."
    
    # Check if partition already exists
    EXISTS=$(mysql -u "${MIGRATOR_USER}" -p"${MIGRATOR_PASS}" -Nse "
        SELECT COUNT(*) FROM information_schema.partitions 
        WHERE table_schema = '${DB_NAME}' 
          AND table_name = '${table_name}' 
          AND partition_name = 'p${NEXT_YEAR}';
    ")

    if [ "${EXISTS}" -gt 0 ]; then
        echo "    Partition p${NEXT_YEAR} already exists on ${table_name}."
    else
        echo "    Reorganizing p_future to create partition p${NEXT_YEAR} on ${table_name}..."
        mysql -u "${MIGRATOR_USER}" -p"${MIGRATOR_PASS}" "${DB_NAME}" -e "
            ALTER TABLE \`${table_name}\` REORGANIZE PARTITION p_future INTO (
                PARTITION p${NEXT_YEAR} VALUES LESS THAN (${SPLIT_YEAR}),
                PARTITION p_future VALUES LESS THAN MAXVALUE
            );
        "
        echo "    Successfully created partition p${NEXT_YEAR} on ${table_name}."
    fi
done

echo "Partition maintenance complete."
