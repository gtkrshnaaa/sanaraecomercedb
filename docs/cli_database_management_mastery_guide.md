# Sanara E-Commerce MySQL Client CLI Database Management Mastery Guide

## 1. Executive Overview

This operational runbook provides production-grade procedures for inspecting, querying, administering, and troubleshooting the Sanara E-Commerce MySQL 8.0 database engine exclusively through the native `mysql` command-line interface (CLI).

Whether connecting from an administrative workstation, an isolated bastion host, or directly on the dedicated database node (`10.0.2.10`), these workflows bypass GUI overhead to deliver deterministic, scriptable, and low-latency database engineering operations.

---

## 2. Interactive Client Session Mastery

### A. Encrypted Remote Connection Strings

#### 1. Application Role (`sanara_app`) - DML Testing
```bash
mysql -h 10.0.2.10 -P 3306 -u sanara_app -p'SanaraApp_SecurePass2026!' \
    --ssl-ca=/etc/ssl/certs/sanara/sanara-db-ca.pem \
    --ssl-mode=VERIFY_CA \
    sanara_ecommerce
```

#### 2. Migration Role (`sanara_migrator`) - DDL / Schema Evolution
```bash
mysql -h 10.0.2.10 -P 3306 -u sanara_migrator -p'SanaraMigrator_Key2026!' \
    --ssl-ca=/etc/ssl/certs/sanara/sanara-db-ca.pem \
    --ssl-mode=VERIFY_CA \
    sanara_ecommerce
```

#### 3. Read-Only Analytics Role (`sanara_ro`) - Safe Exploration
```bash
mysql -h 10.0.2.10 -P 3306 -u sanara_ro -p'SanaraReadOnly_Report2026!' \
    --ssl-ca=/etc/ssl/certs/sanara/sanara-db-ca.pem \
    --ssl-mode=VERIFY_CA \
    --safe-updates \
    sanara_ecommerce
```
*Note: `--safe-updates` restricts unindexed `UPDATE` and `DELETE` statements and forces `LIMIT` clauses on massive selects.*

### B. Interactive CLI Productive Controls

| Command | Action / Purpose | Production Use Case |
| :--- | :--- | :--- |
| `\G` | Vertical row terminator | Replacing `;` when examining wide tables (`products`, `orders`, `JSON` blobs). |
| `\s` | Session status | Verifies active TLS cipher, connection ID, server version, and uptime. |
| `\c` | Clear statement buffer | Aborts a partially typed multiline query without executing an accidental syntax error. |
| `\! <command>` | Escape to OS subshell | Runs local bash commands (e.g. `\! ls -lh /var/backups`) without terminating the MySQL session. |
| `tee <path>` | Session logger | Records all queries and tabular outputs into a text file for post-incident audit. |
| `notee` | Disable session logger | Stops appending outputs to the text log. |

### C. Advanced Pager Integration

Wide result sets wrap around standard terminal windows, obscuring relational schemas. The MySQL CLI `pager` command redirects output through Unix utilities:

```sql
-- 1. Enable horizontal scrolling with arrow keys (Less mode)
pager less -SFX

-- 2. Filter voluminous output to only matching patterns
pager grep -E "Table|Rows|Cost"

-- 3. Count matching rows instantly without executing COUNT(*)
pager wc -l

-- 4. Revert to standard terminal standard output
nopager
```

---

## 3. Non-Interactive Batch Scripting & Pipeline Automation

### A. Formatting Flags for Bash and CI/CD Automation

```bash
# 1. Silent, Raw Tab-Separated Values (TSV) - Perfect for Bash while-read loops
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' sanara_ecommerce -B -N -e "
    SELECT id, order_number, total_amount FROM orders WHERE status = 'completed';
" | while IFS=$'\t' read -r order_id order_num amount; do
    echo "Processing Order #${order_num} (ID: ${order_id}) for Amount: \$${amount}"
done

# 2. Bordered ASCII Table Output (Human Readable)
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' sanara_ecommerce -t -e "
    SELECT id, title, base_standard_price FROM products LIMIT 5;
"

# 3. Native XML Export
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' sanara_ecommerce -X -e "
    SELECT id, name, slug FROM categories WHERE parent_id IS NULL;
" > /tmp/categories.xml

# 4. JSON Generation via MySQL 8.0 Aggregation
mysql -u sanara_ro -p'SanaraReadOnly_Report2026!' sanara_ecommerce -B -N -e "
    SELECT JSON_PRETTY(JSON_ARRAYAGG(
        JSON_OBJECT(
            'id', p.id,
            'title', p.title,
            'price', p.base_standard_price,
            'discipline', p.design_discipline
        )
    ))
    FROM products p
    WHERE p.status = 'published';
" > /tmp/published_products.json
```

---

## 4. Schema, Partition & Storage Engine Administration

### A. High-Density Schema Metadata Queries

#### 1. Measure Exact On-Disk Storage Footprint per Table
```sql
SELECT 
    table_name AS `Table`,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS `Total_MB`,
    ROUND((data_length / 1024 / 1024), 2) AS `Data_MB`,
    ROUND((index_length / 1024 / 1024), 2) AS `Index_MB`,
    table_rows AS `Est_Rows`
FROM information_schema.tables
WHERE table_schema = 'sanara_ecommerce'
ORDER BY (data_length + index_length) DESC;
```

#### 2. Audit Range Partition Row Distribution & Sizes
```sql
SELECT 
    table_name AS `Partitioned_Table`,
    partition_name AS `Partition`,
    partition_ordinal_position AS `Pos`,
    table_rows AS `Rows_Count`,
    ROUND((data_length / 1024 / 1024), 2) AS `Data_MB`,
    ROUND((index_length / 1024 / 1024), 2) AS `Index_MB`
FROM information_schema.partitions
WHERE table_schema = 'sanara_ecommerce' 
  AND partition_name IS NOT NULL
ORDER BY table_name, partition_ordinal_position;
```

### B. Partition Lifecycle Operations (Adding Future Years)

Annual range partitions on `orders` and `download_logs` terminate with `p_future VALUES LESS THAN MAXVALUE`. Reorganize partitions directly from CLI without table recreation:

```sql
-- Step 1: Reorganize p_future into 2028 and a new p_future
ALTER TABLE sanara_ecommerce.orders REORGANIZE PARTITION p_future INTO (
    PARTITION p2028 VALUES LESS THAN (2029),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Step 2: Repeat for download_logs telemetry table
ALTER TABLE sanara_ecommerce.download_logs REORGANIZE PARTITION p_future INTO (
    PARTITION p2028 VALUES LESS THAN (2029),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Step 3: Verify updated partition topology
SELECT table_name, partition_name, partition_description 
FROM information_schema.partitions 
WHERE table_schema = 'sanara_ecommerce' AND partition_name LIKE 'p2028';
```

### C. Identifying Unused Indexes via Performance Schema

Unused secondary indexes consume buffer pool RAM and degrade write throughput:

```sql
SELECT 
    object_schema AS `database`,
    object_name AS `table`,
    index_name AS `unused_index`
FROM sys.schema_unused_indexes
WHERE object_schema = 'sanara_ecommerce';
```

---

## 5. Query Optimization & Execution Plan Profiling

### A. Deep EXPLAIN ANALYZE Inspection

Execute queries directly with the iterator engine profiler to capture actual execution time, startup cost, and loop iterations:

```sql
EXPLAIN ANALYZE
SELECT 
    p.id,
    p.title,
    p.color_mode,
    p.resolution_dpi,
    cp.studio_name
FROM products p
JOIN creator_profiles cp ON cp.id = p.creator_id
WHERE p.color_mode = 'CMYK' 
  AND p.resolution_dpi >= 300
  AND p.status = 'published'\G
```

Key Metrics to Examine:
- `Index lookup`: Confirms usage of `idx_prod_gen_dpi` or `idx_prod_gen_colormode`.
- `cost`: Total optimizer computational units.
- `actual time`: Time elapsed to produce the first row versus all rows (e.g. `0.045..0.052 ms`).
- `loops`: Number of iteration cycles executed by the nested loop join.

### B. Full-Text Search Plan Verification

```sql
EXPLAIN ANALYZE
SELECT id, title, subtitle, average_rating
FROM products
WHERE MATCH(title, subtitle, search_keywords) AGAINST('+billboard +highway' IN BOOLEAN MODE)\G
```

Verify that `type` reports `fulltext` on `idx_fts_products` rather than an unindexed table scan.

### C. Profiling Fine-Grained Query CPU/IO Phases

```sql
-- Step 1: Enable profiling for the current CLI session
SET profiling = 1;

-- Step 2: Run target query
SELECT * FROM vw_product_catalog_searchable WHERE category_id = 2;

-- Step 3: View execution list
SHOW PROFILES;

-- Step 4: Examine exact subsystem duration for Query ID 1
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;

-- Step 5: Disable profiling
SET profiling = 0;
```

---

## 6. Concurrency, Locks & Transaction Troubleshooting

### A. Inspecting Live Transactions & Locks

When application requests stall on row locks during checkout (`sp_checkout_order`) or payout processing (`sp_request_creator_payout`), query the lock tables:

```sql
-- 1. Identify transactions waiting for locks
SELECT 
    r.trx_id AS waiting_trx_id,
    r.trx_mysql_thread_id AS waiting_thread,
    r.trx_query AS waiting_query,
    b.trx_id AS blocking_trx_id,
    b.trx_mysql_thread_id AS blocking_thread,
    b.trx_query AS blocking_query
FROM performance_schema.data_lock_waits w
JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_engine_transaction_id
JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_engine_transaction_id\G

-- 2. Inspect exact rows and lock modes (Exclusive vs Shared)
SELECT 
    engine_transaction_id,
    thread_id,
    object_schema,
    object_name,
    index_name,
    lock_type,
    lock_mode,
    lock_status,
    lock_data
FROM performance_schema.data_locks
WHERE object_schema = 'sanara_ecommerce'\G
```

### B. Killing Blocked or Runaway Queries

```sql
-- Step 1: Inspect currently running threads
SHOW FULL PROCESSLIST;

-- Step 2: Terminate only the query (keeps client connection alive)
KILL QUERY 42;

-- Step 3: Forcefully disconnect an unresponsive connection
KILL 42;
```

### C. Comprehensive InnoDB Engine Diagnostic

```sql
SHOW ENGINE INNODB STATUS\G
```
Key sections to analyze in the output:
- **LATEST DETECTED DEADLOCK**: Full lock graph of the most recent deadlock, including SQL statements and held locks.
- **TRANSACTIONS**: Active transaction list, undo log record counts, and lock hold durations.
- **BUFFER POOL AND MEMORY**: Buffer pool hit rate (target > 995/1000) and pending read/write dirty page counts.

---

## 7. Security, User Grants & TLS Auditing

### A. Auditing Remote User Privileges

```sql
-- View specific grants for the application user
SHOW GRANTS FOR 'sanara_app'@'%';

-- View specific grants for the CI/CD migration user
SHOW GRANTS FOR 'sanara_migrator'@'%';

-- Inspect authentication plugins and password policies
SELECT 
    user, 
    host, 
    plugin, 
    account_locked, 
    password_lifetime, 
    password_last_changed 
FROM mysql.user 
WHERE user LIKE 'sanara_%';
```

### B. Rotating Service Passwords via CLI

```sql
-- Rotate application password with zero downtime dual-password strategy
ALTER USER 'sanara_app'@'%' 
    IDENTIFIED WITH caching_sha2_password BY 'NewSecret_Pass2026!'
    RETAIN CURRENT PASSWORD;

-- (After PHP servers update to NewSecret_Pass2026!): Discard older password
ALTER USER 'sanara_app'@'%' DISCARD OLD PASSWORD;
FLUSH PRIVILEGES;
```

### C. Auditing Active TLS Ciphers

Verify that all active remote connections are using TLS 1.3:

```sql
SELECT 
    t.processlist_id,
    t.processlist_user,
    t.processlist_host,
    s.variable_value AS tls_cipher
FROM performance_schema.threads t
LEFT JOIN performance_schema.status_by_thread s 
    ON s.thread_id = t.thread_id AND s.variable_name = 'Ssl_cipher'
WHERE t.processlist_user LIKE 'sanara_%'\G
```

### D. Dynamic SSL Certificate Reloading Without Daemon Restart

When certificates are renewed via Let's Encrypt or private CA:
```sql
ALTER INSTANCE RELOAD TLS;
```

---

## 8. High Availability, Replication & Disaster Recovery CLI Operations

### A. Checking Primary GTID Binary Log Status

```sql
-- On Primary Node (10.0.2.10)
SHOW MASTER STATUS\G
-- or in modern syntax:
SHOW BINARY LOG STATUS\G
```
Outputs current binary log file (e.g. `binlog.000024`), position, and executed GTID set.

### B. Checking Replica Health & Lag

```sql
-- On Replica Node (10.0.2.11)
SHOW REPLICA STATUS\G
```
Critical fields to verify:
- `Replica_IO_Running: Yes`
- `Replica_SQL_Running: Yes`
- `Seconds_Behind_Source: 0`
- `Last_IO_Error:` (Must be empty)
- `Last_SQL_Error:` (Must be empty)

### C. Emergency Failover / Replica Promotion

To promote a read replica to primary RW master in the event of an unrecoverable primary failure:

```sql
-- Step 1: Confirm all queued relay logs are applied
STOP REPLICA IO_THREAD;
SHOW REPLICA STATUS\G -- Wait until Seconds_Behind_Source is 0

-- Step 2: Break replication link
STOP REPLICA;
RESET REPLICA ALL;

-- Step 3: Remove read-only lock
SET GLOBAL read_only = OFF;
SET GLOBAL super_read_only = OFF;

-- Step 4: Verify write status
SELECT @@GLOBAL.read_only, @@GLOBAL.super_read_only;
```

### D. Point-In-Time Recovery (PITR) with `mysqlbinlog`

To recover from an accidental administrative table drop or corrupt batch at a precise timestamp:

```bash
# 1. Restore the latest consistent full backup
gunzip < /var/backups/sanara_mysql/sanara_ecommerce_backup_20260930_003319.sql.gz | mysql -u root -p sanara_ecommerce

# 2. Extract and replay binary log events up to the exact second before the incident
mysqlbinlog \
    --read-from-remote-server \
    --host=10.0.2.10 \
    -u sanara_backup -p'SanaraBackup_LocalSecret2026!' \
    --start-datetime="2026-09-30 00:33:19" \
    --stop-datetime="2026-09-30 08:14:59" \
    binlog.000024 binlog.000025 | mysql -u sanara_migrator -p'SanaraMigrator_Key2026!' sanara_ecommerce
```
