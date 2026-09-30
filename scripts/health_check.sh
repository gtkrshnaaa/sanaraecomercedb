#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce MySQL Live Health & Telemetry Diagnostic Script
# Platform: Linux Ubuntu Server
# ==============================================================================

set -euo pipefail

DB_USER="sanara_app"
DB_PASS="SanaraApp_SecurePass2026!"
DB_NAME="sanara_ecommerce"

echo "========================================================================"
echo "Sanara Dedicated Database Server Diagnostic Health Check"
echo "========================================================================"

# 1. Daemon Liveness Check
echo -n "[1/5] Checking MySQL daemon status: "
if mysqladmin ping --silent; then
    echo "HEALTHY (mysqld is responding to ping)"
else
    echo "CRITICAL (mysqld is unreachable)" >&2
    exit 1
fi

# 2. Connection Pool & Thread Metrics
echo "[2/5] Connection Pool & Thread Diagnostics:"
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "
SHOW STATUS WHERE Variable_name IN (
    'Threads_connected',
    'Threads_running',
    'Max_used_connections',
    'Aborted_connects',
    'Uptime'
);
"

# 3. InnoDB Buffer Pool Efficiency
echo "[3/5] InnoDB Buffer Pool Hit Ratio:"
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "
SELECT 
    ROUND((1 - (val_reads.variable_value / val_read_req.variable_value)) * 100, 3) AS buffer_pool_hit_ratio_percent
FROM 
    performance_schema.global_status val_reads
JOIN 
    performance_schema.global_status val_read_req 
    ON val_read_req.variable_name = 'Innodb_buffer_pool_read_requests'
WHERE 
    val_reads.variable_name = 'Innodb_buffer_pool_reads';
"

# 4. Slow Queries and Lock Telemetry
echo "[4/5] Slow Queries & Lock Contention:"
mysql -u "${DB_USER}" -p"${DB_PASS}" -e "
SHOW STATUS WHERE Variable_name IN (
    'Slow_queries',
    'Table_locks_waited',
    'Innodb_row_lock_waits',
    'Innodb_row_lock_time_avg'
);
"

# 5. Partitioned Data Distribution & Storage Footprint
echo "[5/5] Partitioned Orders and Download Logs Distribution:"
mysql -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "
SELECT 
    table_name,
    partition_name,
    table_rows,
    ROUND((data_length + index_length) / 1024, 2) AS size_kb
FROM information_schema.partitions
WHERE table_schema = '${DB_NAME}' 
  AND table_name IN ('orders', 'download_logs')
ORDER BY table_name, partition_ordinal_position;
"

echo "SUCCESS: Database diagnostics passed."
