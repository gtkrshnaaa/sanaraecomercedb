# Volume 5: Transactions, Concurrency Control & Lock Diagnostics
## ACID Internals, MVCC Undo Log Chains, InnoDB Lock Primitives, and Deadlock Graph Diagnosis

### 1. ACID Engineering Primitives

Transactions represent logical units of work that transition a database from one valid state to another without violating relational invariants.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        ACID Implementation Map                         │
├───────────────┬────────────────────────────────────────────────────────┤
│ Atomicity     │ Undo Logs (Rollback segments reverting uncommitted DML)│
│ Consistency   │ Constraints (PK, FK, CHECK), Triggers & Double-Entry   │
│ Isolation     │ MVCC (Multi-Version Read Views) + Row/Gap Locking      │
│ Durability    │ Redo Log (WAL - Write-Ahead Logging) + Doublewrite     │
└───────────────┴────────────────────────────────────────────────────────┘
```

#### 1.1 Durability & The Write-Ahead Log (WAL)
InnoDB does not flush dirty memory pages to `.ibd` tablespace files on every `COMMIT`. Writing random disk pages is prohibitively slow. Instead:
1. Modifications are applied to pages cached in the in-memory **InnoDB Buffer Pool**.
2. Sequential change records are immediately written to the **Redo Log** (`ib_logfile0`).
3. The transaction is acknowledged as committed once the redo log is flushed to disk (`innodb_flush_log_at_trx_commit = 1`).
4. Background threads asynchronously flush dirty buffer pool pages to disk via the **Doublewrite Buffer** (protecting against partial page writes during power loss).

---

### 2. Multi-Version Concurrency Control (MVCC) Internals

InnoDB achieves non-blocking reads (`SELECT` queries do not wait for write locks, and writes do not wait for reads) via Multi-Version Concurrency Control (MVCC).

#### 2.1 Hidden System Columns in Every Clustered Record
Every row stored in an InnoDB table contains hidden metadata columns:
* `DB_TRX_ID` (6 bytes): Identifier of the last transaction that inserted or updated the row.
* `DB_ROLL_PTR` (7 bytes): Roll pointer referencing the previous version of the row located in the Undo Log segment.
* `DB_ROW_ID` (6 bytes): Auto-increment row ID allocated only if a table lacks an explicit `PRIMARY KEY` or `NOT NULL UNIQUE` key.

```text
Clustered Index Record (Visible Row):
┌──────────────┬──────────────────┬─────────────────┬────────────────────┐
│ ID: 1        │ DB_TRX_ID: 1045  │ DB_ROLL_PTR: ──┐│ Title: 'Billboard' │
└──────────────┴──────────────────┴─────────────────┼────────────────────┘
                                                    │
                                                    ▼
Undo Log History Chain (Older Versions in Undo Tablespace):
┌──────────────────┬─────────────────┬────────────────────┐
│ DB_TRX_ID: 1020  │ DB_ROLL_PTR: ──┐│ Title: 'Old Title' │
└──────────────────┴─────────────────┼────────────────────┘
                                     │
                                     ▼
                                   [NULL] (Original Insert)
```

#### 2.2 Read Views & Visibility Rules
When executing under `REPEATABLE READ`, the first `SELECT` statement creates an immutable **Read View** containing:
* `m_low_limit_id`: Transaction ID upper bound. Any row with `DB_TRX_ID >= m_low_limit_id` was created after the snapshot and is invisible.
* `m_up_limit_id`: Smallest active transaction ID when snapshot was taken. Any row with `DB_TRX_ID < m_up_limit_id` was committed and is visible.
* `m_ids`: Array of active transaction IDs. Rows updated by transactions in this set are followed down the Undo Chain until an older committed version is reached.

---

### 3. Transaction Isolation Levels Compared

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Mechanism |
|---|---|---|---|---|
| **READ UNCOMMITTED** | Permitted | Permitted | Permitted | Reads latest row state without checking MVCC visibility. |
| **READ COMMITTED** | Prevented | Permitted | Permitted | Each `SELECT` generates a fresh Read View snapshot. Locks record only (no gap locks). |
| **REPEATABLE READ** (Default) | Prevented | Prevented | Prevented | Single Read View snapshot per transaction. Gap and Next-Key locking blocks phantoms. |
| **SERIALIZABLE** | Prevented | Prevented | Prevented | Implicitly converts every plain `SELECT` into `SELECT ... FOR SHARE`. |

---

### 4. InnoDB Locking Primitives

Locks prevent conflicting concurrent transactions from corrupting shared data.

#### 4.1 Lock Modes
* **Shared Lock (S)**: Read lock. Multiple transactions can hold S locks simultaneously.
* **Exclusive Lock (X)**: Write lock. Only one transaction can hold an X lock; all others are blocked.
* **Intention Locks (IS, IX)**: Table-level locks indicating a transaction intends to acquire row-level locks down the hierarchy. Prevents full-table operations (`LOCK TABLES`, `ALTER TABLE`) from conflicting with active row locks.

#### 4.2 Physical Row Lock Algorithms
1. **Record Lock**: Locks the physical index record.
   * `SELECT * FROM products WHERE id = 1 FOR UPDATE;` (Locks PK index record 1).
2. **Gap Lock**: Locks the gap between index records, or the gap before the first or after the last index record. Does not lock the record itself. Prevents concurrent inserts into the gap.
3. **Next-Key Lock**: A combination of a Record Lock on the index record and a Gap Lock on the gap preceding that index record. (Default locking mode in `REPEATABLE READ`).

---

### 5. Pessimistic vs Optimistic Concurrency Control

#### 5.1 Pessimistic Row Locking (`FOR UPDATE`)
Acquires exclusive X locks immediately, blocking concurrent transactions from modifying or locking the target rows until transaction commit or rollback:

```sql
START TRANSACTION;

-- Lock creator wallet row exclusively:
SELECT available_balance 
FROM creator_wallets 
WHERE creator_id = 1 
FOR UPDATE;

-- Perform ledger update and balance deduction:
UPDATE creator_wallets 
SET available_balance = available_balance - 500.00 
WHERE creator_id = 1;

INSERT INTO wallet_ledger_entries (...) VALUES (...);

COMMIT;
```

#### 5.2 Optimistic Concurrency Control (Version Checking)
Does not lock rows during read. Verifies that the row has not changed at the moment of update:

```sql
-- Step 1: Read entity and version timestamp:
SELECT id, available_balance, updated_at FROM creator_wallets WHERE creator_id = 1;

-- Step 2: Atomic conditional update asserting unmodified state:
UPDATE creator_wallets 
SET available_balance = available_balance - 500.00
WHERE creator_id = 1 AND updated_at = '2026-09-30 08:00:00';

-- Step 3: Inspect affected rows in application:
-- If ROW_COUNT() == 0, conflict detected; roll back and retry.
```

---

### 6. Deadlock Diagnostics & Graph Analysis

A deadlock occurs when two or more transactions form a circular dependency, each waiting for locks held by the other.

#### 6.1 Inspecting the Deadlock Engine Graph
```sql
SHOW ENGINE INNODB STATUS\G
```

*Locate the `LATEST DETECTED DEADLOCK` Section*:
```text
------------------------
LATEST DETECTED DEADLOCK
------------------------
2026-09-30 10:14:02 0x7f8a12345700
*** (1) TRANSACTION:
TRANSACTION 18402, ACTIVE 2 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 1136, 1 row lock(s)
MySQL thread id 45, OS thread handle 140231, query id 8901 127.0.0.1 sanara_app updating
UPDATE products SET total_sales_count = total_sales_count + 1 WHERE id = 4;
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 28 page no 4 n bits 72 index PRIMARY of table `sanara_ecommerce`.`products` trx id 18402 lock_mode X locks rec but not gap waiting

*** (2) TRANSACTION:
TRANSACTION 18403, ACTIVE 3 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 46, OS thread handle 140232, query id 8904 127.0.0.1 sanara_app updating
UPDATE creator_wallets SET available_balance = available_balance + 80 WHERE creator_id = 1;
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 28 page no 4 n bits 72 index PRIMARY of table `sanara_ecommerce`.`products` trx id 18403 lock_mode X locks rec but not gap
*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 32 page no 3 n bits 72 index uq_wallet_creator of table `sanara_ecommerce`.`creator_wallets` trx id 18403 lock_mode X waiting

*** WE ROLL BACK TRANSACTION (1)
```

#### 6.2 Deadlock Prevention Rules
1. **Uniform Lock Ordering**: Always access and lock tables and rows in identical chronological order across all application services (e.g., always lock `products` first, then `creator_wallets`, never in reverse).
2. **Shorten Transactions**: Keep transaction boundaries tight. Never perform external network calls (payment webhooks, email sending) inside an open database transaction.
3. **Index Predicate Columns**: Ensure every `UPDATE` or `DELETE` filters on an indexed column. Unindexed filters force InnoDB to scan and lock every record in the table, escalating concurrency contention into immediate deadlocks.
