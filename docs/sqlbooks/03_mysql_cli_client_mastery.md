# Volume 3: Native MySQL CLI Client Operations
## High-Performance Terminal Administration, Shell Piping, Pager Configurations, and Session Diagnostics

### 1. Terminal Invocation & Authentication Architecture

The native `mysql` CLI client is the primary interface for production database engineering, performance profiling, and emergency incident triage.

#### 1.1 TCP/IP Networking vs UNIX Domain Sockets
* **UNIX Domain Socket (`-S /var/run/mysqld/mysqld.sock`)**: Used when connecting to `localhost` on the same machine. Bypasses the network stack entirely for lower IPC latency.
* **TCP/IP Loopback (`-h 127.0.0.1 -P 3306`)**: Traverses the local TCP/IP stack. Essential when connecting to remote instances, Docker container bridges, or TLS-encrypted endpoints.
* *Note on localhost vs 127.0.0.1*: In MySQL, specifying `-h localhost` causes the client to attempt a UNIX socket connection, ignoring `-P` (port). To connect via TCP over loopback, explicitly use `-h 127.0.0.1`.

#### 1.2 Encrypted Login Paths (`mysql_config_editor`)
Hardcoding passwords in bash scripts or CLI flags exposes secrets in shell history and `ps aux` process tables. Production best practice uses AES-encrypted `.mylogin.cnf` profiles:

```bash
# Store encrypted authentication path
mysql_config_editor set \
    --login-path=sanara_prod \
    --host=127.0.0.1 \
    --port=3306 \
    --user=sanara_app \
    --password

# Connect seamlessly without passwords on the command line
mysql --login-path=sanara_prod sanara_ecommerce
```

---

### 2. Interactive Shell Directives & Pager Mastery

#### 2.1 Statement Terminators
* `;` or `\g`: Standard horizontal grid output.
* `\G`: Vertical tabular output. Essential when inspecting wide rows (e.g., `products`, `system_audit_logs`, or `SHOW ENGINE INNODB STATUS`).

```sql
SELECT id, title, design_metadata FROM products WHERE id = 1\G
```

#### 2.2 Advanced Pagers for Deep Inspections
Long queries often scroll past the terminal buffer. The `pager` command redirects query output to external Unix tools:

* **Horizontal Scrolling with `less`**:
```sql
-- Disable line-wrap and allow horizontal arrow navigation:
pager less -SFX

-- Inspect wide execution plans without line wrapping:
EXPLAIN ANALYZE SELECT * FROM order_items;

-- Reset to default terminal output:
nopager
```

* **Colorized and Formatted Pager**:
```sql
-- Pipe output through grep or awk on-the-fly:
pager grep -E "(rows|cost|Scan)"
EXPLAIN FORMAT=TREE SELECT * FROM products WHERE status = 'published';
```

#### 2.3 Session Recording with `tee`
Capture production migration logs and interactive execution transcripts directly to disk:

```sql
-- Begin recording session transcript:
tee /home/user/audit_session_2026_09_30.log;

-- Execute operations (all input and output are mirrored to file):
SHOW TABLES;
SELECT COUNT(*) FROM orders;

-- Stop recording:
notee;
```

#### 2.4 External Text Editor Buffer (`\e`)
Invoke `$EDITOR` (e.g., `vim`, `nano`) to construct multi-line stored procedures, complex recursive CTEs, or views:
```sql
\e
-- Saves to temporary file and immediately executes on exit.
```

#### 2.5 Defensive Prompt Configuration
Avoid catastrophic human errors by displaying the current user, hostname, and database directly in the interactive shell prompt:

```bash
# Add to ~/.my.cnf:
[mysql]
prompt="[\u@\h:\d]> "
```

Output:
```text
[sanara_app@127.0.0.1:sanara_ecommerce]> 
```

---

### 3. Non-Interactive Batch Execution & Shell Piping

The CLI client integrates into UNIX toolchains (`bash`, `awk`, `sed`, `jq`, `curl`).

#### 3.1 Silent, Raw Output for Data Pipelines (`-Nse`)
* `-N` (`--skip-column-names`): Suppresses column header row.
* `-s` (`--silent`): Emits raw tab-delimited values without ASCII borders.
* `-e` (`--execute`): Executes query string and terminates.

*Extracting IDs for shell loops*:
```bash
# Fetch all active creator user IDs directly into a bash array:
CREATOR_IDS=($(mysql --login-path=sanara_prod -Nse "SELECT id FROM creator_profiles WHERE is_verified_creator = 1;"))

for cid in "${CREATOR_IDS[@]}"; do
    echo "Processing compliance check for creator: ${cid}"
done
```

#### 3.2 High-Throughput Streaming (`--quick`)
By default, the MySQL client fetches the entire result set into client memory before displaying it. For multi-gigabyte queries or exports, add `--quick` (`-q`) to stream rows sequentially:

```bash
mysql --login-path=sanara_prod --quick -Nse "SELECT * FROM download_logs;" > /archive/download_logs_dump.tsv
```

---

### 4. Runtime Variable Diagnostics & Persistence

#### 4.1 Variable Scopes
* **Global Variables (`@@GLOBAL`)**: Affects all incoming client connections.
* **Session Variables (`@@SESSION`)**: Affects only the current interactive connection.

```sql
-- Inspect current session and global buffer settings:
SHOW VARIABLES LIKE 'sort_buffer_size';

-- Tune memory for a single heavy sorting operation in this session only:
SET SESSION sort_buffer_size = 64 * 1024 * 1024; -- 64 MB
```

#### 4.2 System Variable Persistence in MySQL 8.0
In MySQL 8.0, administrators can persist global configuration changes across server restarts without manually editing `/etc/mysql/my.cnf` via `SET PERSIST`:

```sql
-- Updates runtime global setting AND appends to mysqld-auto.cnf on disk:
SET PERSIST max_connections = 500;
SET PERSIST innodb_print_all_deadlocks = ON;
```

---

### 5. Process Monitoring & Runaway Query Termination

Diagnosing locks, spikes, and long-running queries in real-time.

```sql
-- Inspect all active threads and query states:
SHOW FULL PROCESSLIST;

-- Query performance schema for active queries running longer than 10 seconds:
SELECT 
    processlist_id,
    processlist_user,
    processlist_host,
    processlist_db,
    processlist_time AS running_seconds,
    processlist_info AS running_query
FROM performance_schema.threads
WHERE processlist_info IS NOT NULL 
  AND processlist_time > 10
ORDER BY processlist_time DESC;

-- Terminate a runaway query without disconnecting the application client:
KILL QUERY 142;

-- Forcefully sever a deadlocked application connection:
KILL CONNECTION 142;
```
