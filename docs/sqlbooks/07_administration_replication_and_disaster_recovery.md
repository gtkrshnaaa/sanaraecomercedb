# Volume 7: Administration, Replication, and Disaster Recovery

## 1. Horizontal Table Partitioning Mechanics

Table partitioning divides a large table into smaller physical storage units (partitions) managed transparently as a single logical entity by MySQL. Queries against partitioned tables leverage partition pruning: the optimizer scans only matching partitions based on predicate expressions.

### 1.1 Partition Types

| Partition Strategy | Partition Key Characteristics | Best Fit Use Case |
| :--- | :--- | :--- |
| `RANGE` | Contiguous numerical or temporal intervals | Time-series data, historical transaction archives |
| `RANGE COLUMNS` | Multi-column intervals; supports native date/string types | Date partitioning without `YEAR()` or `TO_DAYS()` conversion |
| `LIST` / `LIST COLUMNS` | Discrete enumerated sets of values | Multi-tenant databases, geographic regional isolation |
| `HASH` | Modulo of an integer expression | Evenly distributing write concurrency across disks |
| `KEY` | Internal MD5 hashing of non-integer or primary keys | Balancing primary key access without custom hash functions |

### 1.2 Declarative Constraints on Partitioned Tables

1. **Every Unique Key Must Include Partition Columns**: All columns used in primary keys or unique secondary indexes must be present in the table partition expression.
2. **Foreign Key Ban in InnoDB**: MySQL InnoDB strictly forbids foreign key constraints that reference a partitioned table or are defined on a partitioned table. Relationships must be managed at the application layer or via procedural integrity checks.

### 1.3 Implementation: Multi-Year Time-Series Range Partitioning

The `orders` table in `sanaraecomercedb` is partitioned by the transaction timestamp:

```sql
CREATE TABLE orders (
    order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    buyer_user_id BIGINT UNSIGNED NOT NULL,
    order_status ENUM('pending', 'paid', 'fulfilled', 'cancelled', 'refunded') NOT NULL,
    total_amount_cents INT UNSIGNED NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, created_at),
    KEY idx_orders_buyer (buyer_user_id)
) ENGINE=InnoDB
PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
    PARTITION p_orders_historic VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01 00:00:00')),
    PARTITION p_orders_2025_q1  VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION p_orders_2025_q2  VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION p_orders_2025_q3  VALUES LESS THAN (UNIX_TIMESTAMP('2025-10-01 00:00:00')),
    PARTITION p_orders_2025_q4  VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01 00:00:00')),
    PARTITION p_orders_2026_q1  VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION p_orders_future   VALUES LESS THAN MAXVALUE
);
```

### 1.4 Verifying Partition Pruning

Using `EXPLAIN` to inspect partition access:

```sql
EXPLAIN SELECT * FROM orders 
WHERE created_at >= '2025-04-15 00:00:00' 
  AND created_at < '2025-05-01 00:00:00'\G
```

Output confirms that only partition `p_orders_2025_q2` is evaluated, skipping all historical and future partitions:

```
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: orders
   partitions: p_orders_2025_q2
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1420
     filtered: 100.00
        Extra: Using where
```

### 1.5 Partition Maintenance and Rolling Window Management

```sql
-- Split future partition to append a new quarter
ALTER TABLE orders REORGANIZE PARTITION p_orders_future INTO (
    PARTITION p_orders_2026_q2 VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),
    PARTITION p_orders_future  VALUES LESS THAN MAXVALUE
);

-- Fast archival: Drop expired historical partition instantaneously without undo log bloat
ALTER TABLE orders DROP PARTITION p_orders_historic;

-- Zero-downtime table swap via EXCHANGE PARTITION
ALTER TABLE orders EXCHANGE PARTITION p_orders_2025_q1 WITH TABLE orders_archive_2025_q1;
```

---

## 2. Engine Maintenance and Performance Optimization

InnoDB tables require proactive maintenance to manage physical B-tree fragmentation and keep optimizer statistical distributions accurate.

### 2.1 B-Tree Fragmentation and Compaction

Heavy random `UPDATE` or `DELETE` activity produces empty spaces within 16KB InnoDB index pages. `OPTIMIZE TABLE` rebuilds the table and clustered indexes online:

```sql
OPTIMIZE TABLE orders;
```

Under InnoDB, `OPTIMIZE TABLE` translates internally to:

```sql
ALTER TABLE orders ENGINE=InnoDB;
```

This allocates fresh contiguous extents, packs B-tree nodes to the target fill factor, and reclaims disk space back to the underlying operating system.

### 2.2 Cardinality Updates via `ANALYZE TABLE`

The Cost-Based Optimizer (CBO) relies on sampled index statistics stored in `mysql.innodb_index_stats` and `mysql.innodb_table_stats`. If large bulk inserts or deletions occur, statistics become stale:

```sql
ANALYZE TABLE products, order_items, wallet_ledger_entries;
```

`ANALYZE TABLE` gathers non-blocking statistical samples, recalculating cardinality values without locking concurrent reads or writes.

### 2.3 Buffer Pool Warmup across Restarts

To eliminate latency spikes caused by cold cache queries following database restarts, configure persistent buffer pool dumping and loading in `my.cnf`:

```ini
[mysqld]
innodb_buffer_pool_dump_at_shutdown = 1
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_pct = 75
```

During shutdown, InnoDB writes the memory page addresses (tablespace ID and page number) to `ib_buffer_pool`. Upon startup, the engine reads this file and pre-warms the buffer pool asynchronously.

---

## 3. Role-Based Access Control (RBAC) and Zero-Downtime Password Rotation

MySQL 8.0 implements full ANSI SQL role-based access control, allowing permission sets to be bundled into reusable roles.

### 3.1 Creating and Granting Roles

```sql
-- 1. Declare abstract operational roles
CREATE ROLE IF NOT EXISTS 'role_developer_ro', 'role_app_rw', 'role_dba_admin';

-- 2. Grant permissions to roles
GRANT SELECT ON sanaraecomercedb.* TO 'role_developer_ro';

GRANT SELECT, INSERT, UPDATE, DELETE ON sanaraecomercedb.* TO 'role_app_rw';
GRANT EXECUTE ON sanaraecomercedb.* TO 'role_app_rw';

GRANT ALL PRIVILEGES ON *.* TO 'role_dba_admin' WITH GRANT OPTION;

-- 3. Create service accounts and assign roles
CREATE USER 'sanara_backend'@'10.0.%.%' IDENTIFIED BY 'StrongBackendSecret#2026';
GRANT 'role_app_rw' TO 'sanara_backend'@'10.0.%.%';

-- 4. Enable role activation by default upon connection
SET DEFAULT ROLE 'role_app_rw' TO 'sanara_backend'@'10.0.%.%';
```

### 3.2 Dual-Password Rotation Protocol

To rotate production database credentials without service downtime, MySQL 8.0 supports dual passwords:

```sql
-- Step 1: Assign new password while retaining existing password
ALTER USER 'sanara_backend'@'10.0.%.%' 
IDENTIFIED BY 'NewSecureToken$2026' 
RETAIN CURRENT PASSWORD;

-- At this point, application servers can connect using EITHER the old or new password.
-- Step 2: Deploy updated configuration to all application pods/instances.

-- Step 3: Discard the old password once all instances are on the new credential
ALTER USER 'sanara_backend'@'10.0.%.%' 
DISCARD OLD PASSWORD;
```

---

## 4. GTID-Based Binary Replication Architecture

Global Transaction Identifiers (GTID) assign a unique coordinate to every committed transaction across a database cluster:

$$\text{GTID} = \text{server\_uuid} : \text{transaction\_id}$$

GTID simplifies replica provisioning and automated failover by eliminating manual binlog file and offset tracking.

### 4.1 Master Node Configuration (`my.cnf`)

```ini
[mysqld]
server_id                = 101
gtid_mode                = ON
enforce_gtid_consistency = ON
binlog_format            = ROW
binlog_row_image         = FULL
log_bin                  = /var/log/mysql/mysql-bin.log
log_replica_updates      = ON
sync_binlog              = 1
innodb_flush_log_at_trx_commit = 1
```

### 4.2 Establishing GTID-Based Replica Replication

On the replica node (`server_id = 102`):

```sql
-- Configure connection to primary source
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = '10.0.1.10',
    SOURCE_PORT = 3306,
    SOURCE_USER = 'repl_service',
    SOURCE_PASSWORD = 'ReplPassphrase2026',
    SOURCE_AUTO_POSITION = 1,
    SOURCE_SSL = 1;

-- Start replication threads
START REPLICA;

-- Inspect replica lag and GTID execution coordinates
SHOW REPLICA STATUS\G
```

Key verification metrics in `SHOW REPLICA STATUS`:
* `Replica_IO_Running: Yes`: The I/O thread is receiving binlog events from source.
* `Replica_SQL_Running: Yes`: The SQL applier thread is writing transactions to engine.
* `Seconds_Behind_Source: 0`: Replication lag is zero.
* `Retrieved_Gtid_Set`: Set of transactions received by the replica.
* `Executed_Gtid_Set`: Set of transactions written to storage engine.

---

## 5. Backup Strategies and Point-In-Time Recovery (PITR)

A production backup architecture requires consistent baseline snapshots paired with continuous binary log shipping for fine-grained Point-In-Time Recovery (PITR).

### 5.1 Single-Transaction Consistent Logical Backup

Using `mysqldump` with transactional snapshot guarantees:

```bash
mysqldump \
  --host=127.0.0.1 \
  --port=3306 \
  --user=root \
  --password \
  --single-transaction \
  --quick \
  --source-data=2 \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  --default-character-set=utf8mb4 \
  sanaraecomercedb | gzip -9 > sanara_backup_$(date +%F_%H%M%S).sql.gz
```

* `--single-transaction`: Starts a `REPEATABLE READ` transaction before dumping, ensuring point-in-time consistency without locking tables.
* `--source-data=2` (or `--master-data=2` in legacy clients): Records the active binary log coordinates and GTID state as a comment in the dump header.
* `--quick`: Streams rows directly from server without buffering the entire table in client RAM.

### 5.2 Point-In-Time Recovery (PITR) Execution Workflow

Assume a corrupting command (`DROP TABLE orders;` or mistaken `UPDATE`) executed at `2026-09-30 14:22:15`. The recovery goal is restoring the database to state at `2026-09-30 14:22:10`.

#### Step 1: Isolate the Instance and Restore Baseline Snapshot

```bash
# Decompress and restore baseline snapshot to clean staging instance
gunzip < sanara_backup_2026-09-30_020000.sql.gz | mysql -u root -p sanaraecomercedb
```

#### Step 2: Extract Post-Backup Binary Logs

Inspect the dump file header to locate the baseline coordinates:

```sql
-- CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE='mysql-bin.000042', SOURCE_LOG_POS=1945;
```

#### Step 3: Replay Transactions up to the Exact Event

Use `mysqlbinlog` to extract and replay all transactions from the baseline log position up to the exact moment before the corruption event:

```bash
mysqlbinlog \
  --read-from-remote-server \
  --host=10.0.1.10 \
  --user=root \
  --password \
  --start-position=1945 \
  --stop-datetime="2026-09-30 14:22:10" \
  /var/log/mysql/mysql-bin.000042 /var/log/mysql/mysql-bin.000043 \
  | mysql -u root -p sanaraecomercedb
```

#### Step 4: Verification and Re-linking

Verify the restored data state, recalculate table statistics, and promote the staging instance to active production.
