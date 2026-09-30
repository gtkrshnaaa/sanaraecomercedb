# Sanara E-Commerce MySQL 8.0 Performance Tuning & OS Optimization Guide

## 1. Executive Summary

A dedicated database server handling high-resolution visual communication assets and financial transactions requires coordinated optimization across two layers:
1. **Linux Kernel & Operating System Subsystems** (memory paging, file descriptors, TCP network sockets).
2. **MySQL 8.0 InnoDB Storage Engine** (buffer pools, redo logs, flushing heuristics, and concurrency limits).

---

## 2. Linux Kernel Optimization (`/etc/sysctl.d/99-mysql-tuning.conf`)

Dedicated database hosts must prioritize memory persistence and avoid swapping out cached InnoDB pages:

```ini
# Virtual Memory Subsystem
# Prevent Linux kernel from swapping InnoDB buffer pool pages to disk
vm.swappiness = 1

# Flush dirty pages in small continuous bursts to avoid I/O stalls
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# Allow high memory allocations for thread and sorting buffers
vm.max_map_count = 262144

# File Descriptor Capacity
fs.file-max = 2097152
fs.aio-max-nr = 1048576

# High-Concurrency Network Socket Tuning
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65535
```

### Applying Sysctl Changes:
```bash
sudo sysctl --system
```

---

## 3. System Resource Limits (`/etc/security/limits.d/99-mysql.conf`)

By default, Ubuntu restricts file descriptors to 1,024 per process, which causes "Too many open files" errors under peak traffic.

```ini
mysql soft nofile 65535
mysql hard nofile 65535
mysql soft nproc 32768
mysql hard nproc 32768
mysql soft memlock unlimited
mysql hard memlock unlimited
```

---

## 4. Production MySQL 8.0 Engine Tuning (`config/mysql.cnf`)

### A. Memory & Buffer Pool Sizing
- **`innodb_buffer_pool_size = 4G`**: Set to 70% to 80% of total host RAM on a dedicated server. Holds data pages, primary keys, and secondary indexes in memory.
- **`innodb_buffer_pool_instances = 4`**: Divides the buffer pool into isolated partitions to eliminate mutex lock contention across multi-core processors.
- **`innodb_redo_log_capacity = 2G`**: Modern replacement for `innodb_log_file_size` in MySQL 8.0.30+. Buffers high-frequency write bursts before asynchronous disk flushes.

### B. I/O and ACID Compliance
- **`innodb_flush_log_at_trx_commit = 1`**: Strict ACID durability. Every transaction commit flushes the redo log to disk, preventing data loss during host power failures.
- **`innodb_flush_method = O_DIRECT`**: Bypasses the Linux page cache, avoiding double buffering of database data between the OS kernel and MySQL.
- **`innodb_io_capacity = 2000`** & **`innodb_io_capacity_max = 4000`**: Tuned for NVMe / enterprise SSD storage to maximize background checkpoint writes.

### C. Concurrency & Network
- **`max_connections = 500`**: Prevents out-of-memory crashes while allowing sufficient concurrency for multi-node PHP connection pools.
- **`back_log = 512`**: Backlog TCP queue length for incoming connections during traffic spikes.
- **`skip-name-resolve = 1`**: Eliminates DNS reverse-lookup overhead on client connections.

---

## 5. Query Optimization & Indexing Strategies

### 1. Partition Pruning on Orders
Queries filtering on `created_at` automatically prune non-matching partitions, drastically reducing searched blocks:

```sql
-- Query plan inspects ONLY partition p2026
EXPLAIN SELECT id, order_number, total_amount 
FROM orders 
WHERE created_at >= '2026-01-01 00:00:00' AND created_at < '2027-01-01 00:00:00';
```
**Optimizer Result**: `partitions: p2026 | type: ALL | rows: 2` (Zero overhead from 2024, 2025, or future partitions).

### 2. Stored Generated Column Indexing
Rather than executing slow unindexed JSON table scans (`JSON_EXTRACT`), pre-computed columns are indexed as native B-tree structures:

```sql
-- Leverages idx_prod_gen_dpi (resolution_dpi = 300)
EXPLAIN ANALYZE 
SELECT id, title, color_mode, resolution_dpi 
FROM products 
WHERE color_mode = 'CMYK' AND resolution_dpi = 300;
```
**Execution Tree**:
```text
-> Filter: (products.color_mode = 'CMYK') (cost=0.8 rows=3) (actual time=0.0465..0.0517 rows=3 loops=1)
    -> Index lookup on products using idx_prod_gen_dpi (resolution_dpi=300) (cost=0.8 rows=3) (actual time=0.0438..0.0482 rows=3 loops=1)
```

### 3. Full-Text Search Plan
```sql
EXPLAIN ANALYZE 
SELECT id, title 
FROM products 
WHERE MATCH(title, subtitle, search_keywords) AGAINST('billboard outdoor');
```
**Execution Tree**:
```text
-> Full-text index search on products using idx_fts_products (title='billboard outdoor') (cost=0.35 rows=1) (actual time=0.041..0.0474 rows=2 loops=1)
```
Cost is 0.35 ms, resolving in under 50 microseconds.
