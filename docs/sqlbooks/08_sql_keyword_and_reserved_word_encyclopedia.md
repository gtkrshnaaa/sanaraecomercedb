# Volume 8: Comprehensive SQL Keyword, Operator, and Reserved Word Encyclopedia

## 1. Grammatical Classification of SQL Keywords

SQL keywords constitute the lexical foundation of relational database management systems. Keywords are predefined tokens that possess dedicated syntactic meanings within the SQL query parsing engine.

### 1.1 Reserved Words vs. Non-Reserved Keywords

The MySQL 8.0 lexical analyzer distinguishes between two categories of keywords:

* **Reserved Words**: Tokens permanently reserved by the SQL grammar parser. These cannot be utilized as unquoted identifiers (table names, column names, aliases, stored routine names, or index names). If an identifier conflicts with a reserved word, it must be explicitly escaped using backtick delimiters (`` `select` `` or `` `order` ``) or double quotes under `ANSI_QUOTES` mode.
* **Non-Reserved Keywords**: Tokens that possess specialized grammatical meaning in specific clauses (such as `ENGINE`, `STATUS`, or `ACTION`), but remain permissible as unquoted identifiers in standard identifier contexts without triggering parsing errors.

```sql
-- Syntax Error: 'order' and 'key' are strict reserved words
CREATE TABLE order (
    key INT PRIMARY KEY
);

-- Compliant: Escaping reserved words using backticks
CREATE TABLE `order` (
    `key` INT PRIMARY KEY
);
```

### 1.2 Identifier Escaping and ANSI Portability

In ANSI/ISO standard SQL, identifiers are escaped using double quotes (`"`). In MySQL, backticks (``` ` ```) are the default delimiter. To achieve strict ANSI compliance across database engines, configure the server SQL mode:

```sql
SET SESSION sql_mode = 'ANSI_QUOTES';

-- Double quotes now represent identifiers instead of string literals
SELECT "order_id", "total_amount_cents" FROM "orders";
```

---

## 2. Data Query Language (DQL) Keywords

DQL keywords define the declarative specification for retrieving, projecting, filtering, aggregating, and joining relation tuples.

### 2.1 Core Projection and Filtering Keywords

| Keyword | Grammatical Role | Engine Behavior |
| :--- | :--- | :--- |
| `SELECT` | Projection initiator | Specifies the expressions, columns, or aggregates returned to the client cursor. |
| `FROM` | Relation specifier | Identifies base tables, views, subqueries, or table functions providing input rows. |
| `WHERE` | Row predicate filter | Evaluates Boolean expressions for each row before grouping or aggregation occurs. |
| `AS` | Alias binder | Assigns an ephemeral identifier to a projected column expression or relation source. |
| `DISTINCT` | Deduplication operator | Directs the engine to eliminate duplicate tuples using an in-memory hash table or sort. |
| `ALL` | Full projection | Explicit default counterpart to `DISTINCT`; projects every row matching predicates. |

```sql
SELECT DISTINCT p.creator_id, p.currency
FROM products AS p
WHERE p.publication_status = 'published';
```

### 2.2 Aggregation and Grouping Keywords

* `GROUP BY`: Aggregates rows sharing identical values across specified columns into summary tuples. Triggers sort or temporary hash table creation in execution plans.
* `HAVING`: Filters aggregated summary tuples post-aggregation. Evaluates predicates containing aggregate functions (`COUNT()`, `SUM()`) which are illegal in `WHERE`.
* `WITH ROLLUP`: Multi-level aggregation modifier appended to `GROUP BY`. Emits hierarchical super-aggregate summary rows containing `NULL` dimension markers.

```sql
SELECT 
    category_id, 
    license_type_id, 
    COUNT(*) AS total_assets, 
    SUM(price_amount_cents) AS total_value
FROM products
GROUP BY category_id, license_type_id WITH ROLLUP
HAVING total_assets > 0;
```

### 2.3 Ordering and Result Pagination Keywords

* `ORDER BY`: Imposes deterministic sorting on the output row stream using filesort or B-tree index order.
* `ASC`: Explicit ascending order modifier (default: lowest to highest, A to Z).
* `DESC`: Descending order modifier (highest to lowest, Z to A).
* `LIMIT`: Constrains the maximum row count returned to the client.
* `OFFSET`: Skips a specified count of initial tuples before streaming rows.

```sql
SELECT order_id, total_amount_cents, created_at
FROM orders
ORDER BY created_at DESC, order_id DESC
LIMIT 20 OFFSET 40;
```

### 2.4 Set Operation Keywords

* `UNION`: Combines tuples from two queries, eliminating duplicate rows via temporary sort tables.
* `UNION ALL`: Concatenates tuples from two queries without deduplication, streaming results with minimal memory overhead.
* `INTERSECT`: Computes the set intersection between two result sets, preserving only rows common to both relations (MySQL 8.0.31+).
* `EXCEPT`: Computes the set difference, returning rows from the first query that do not exist in the second query (MySQL 8.0.31+).

```sql
-- Union all distinct buyers and creators
SELECT user_id, 'BUYER' AS role FROM users WHERE buyer_status = 'active'
UNION ALL
SELECT user_id, 'CREATOR' AS role FROM creator_profiles;
```

### 2.5 Relational Join Keywords

| Keyword Clause | Algebraic Symbol | Operational Mechanics |
| :--- | :--- | :--- |
| `INNER JOIN` | $R \bowtie_{\theta} S$ | Retains tuples where the join predicate evaluates to `TRUE` in both relations. |
| `LEFT [OUTER] JOIN` | $R \leftouterjoin_{\theta} S$ | Retains all tuples from the left relation, filling unmatched right attributes with `NULL`. |
| `RIGHT [OUTER] JOIN` | $R \rightouterjoin_{\theta} S$ | Retains all tuples from the right relation, filling unmatched left attributes with `NULL`. |
| `CROSS JOIN` | $R \times S$ | Generates Cartesian product pairing every left row with every right row. |
| `NATURAL JOIN` | $R \bowtie S$ | Implicitly joins relations on all columns sharing identical names. High risk in production. |
| `STRAIGHT_JOIN` | N/A | MySQL optimizer hint forcing the join order explicitly as written from left to right. |
| `ON` | Predicate | Defines arbitrary Boolean conditional expressions linking relation tuples. |
| `USING` | Equi-join column | Binds relations sharing identical column names; projects the bound column once. |

```sql
SELECT o.order_id, u.email, i.variant_id
FROM orders o
INNER JOIN users u ON o.buyer_user_id = u.user_id
LEFT JOIN order_items i USING (order_id)
WHERE o.order_status = 'paid';
```

### 2.6 Subquery and Quantification Keywords

* `IN`: Tests whether a scalar matches any element within a list or single-column subquery.
* `NOT IN`: Inverts set inclusion. Caution: returns zero rows if subquery contains even a single `NULL`.
* `EXISTS`: Evaluates whether a correlated subquery produces at least one row, short-circuiting on first match.
* `NOT EXISTS`: Evaluates whether a correlated subquery produces zero matching rows.
* `ANY` / `SOME`: Compares a scalar against a set; evaluates to `TRUE` if the comparison holds for at least one element (`> ANY(...)`).
* `ALL`: Compares a scalar against a set; evaluates to `TRUE` only if the comparison holds for every element (`> ALL(...)`).

---

## 3. Data Manipulation Language (DML) Keywords

DML keywords execute atomic mutations against relational tuples.

### 3.1 Insertion Keywords

* `INSERT`: Mutation initiator writing new tuples to tables.
* `INTO`: Target relation specifier following `INSERT` or `REPLACE`.
* `VALUES` / `VALUE`: Delimits comma-separated row constructor expressions.
* `ON DUPLICATE KEY UPDATE`: Upsert modifier. If an insertion triggers a `PRIMARY KEY` or `UNIQUE` constraint violation, the engine switches to an in-place `UPDATE` on the conflicting row.

```sql
INSERT INTO creator_wallets (wallet_id, available_balance_cents, updated_at)
VALUES (101, 50000, NOW())
ON DUPLICATE KEY UPDATE
    available_balance_cents = available_balance_cents + VALUES(available_balance_cents),
    updated_at = NOW();
```

* `REPLACE`: MySQL-specific atomic DML. If a duplicate key violation occurs, the engine deletes the existing row completely and inserts the new tuple, triggering `DELETE` and `INSERT` triggers.

### 3.2 Update and Deletion Keywords

* `UPDATE`: Modifies attributes within existing tuples.
* `SET`: Assigns explicit scalar expressions to target columns.
* `DELETE`: Removes tuples matching selection predicates.
* `IGNORE`: Directs the engine to downgrade non-fatal errors (e.g. duplicate key, type truncation) to warnings, permitting multi-row operations to complete.

```sql
-- Multi-table bulk update with IGNORE
UPDATE IGNORE products p
INNER JOIN categories c ON p.category_id = c.category_id
SET p.publication_status = 'archived'
WHERE c.is_active = 0;
```

---

## 4. Data Definition Language (DDL) Keywords

DDL keywords govern physical tablespace allocation, schema structures, declarative integrity constraints, and indexes.

### 4.1 Structural Lifecycle Keywords

| Keyword | Target Object | Operational Mechanics |
| :--- | :--- | :--- |
| `CREATE` | Tables, Views, DB | Allocates metadata in data dictionary and formats physical tablespace. |
| `ALTER` | Schema Structures | Modifies column types, adds indexes, updates table engine, or reorganizes partitions. |
| `DROP` | Tables, Views, DB | Destroys object metadata, frees disk space, and invalidates query caches. |
| `TRUNCATE` | Table Data | Drops physical tablespace and re-creates empty table. Resets `AUTO_INCREMENT`. Bypasses DML triggers. |
| `RENAME` | Tables | Atomically changes object identifier within the MySQL data dictionary. |

### 4.2 Declarative Constraints and Attributes

* `CONSTRAINT`: Declares an explicit symbol identifier for an integrity rule.
* `PRIMARY KEY`: Uniquely identifies tuples; mandates `NOT NULL` and builds the clustered index.
* `FOREIGN KEY`: Enforces referential integrity pointing to a target parent table's candidate key.
* `REFERENCES`: Identifies the parent table and column in a foreign key declaration.
* `UNIQUE`: Enforces distinct values across non-null rows; creates a unique secondary B-tree index.
* `CHECK`: Enforces Boolean domain validation expressions on row insertion and mutation.
* `DEFAULT`: Declares standard literal or expression assigned when a column is omitted in `INSERT`.
* `AUTO_INCREMENT`: Auto-generates monotonically increasing integer surrogate keys on insertion.
* `NOT NULL`: Rejects `NULL` state; optimizes physical row header bitmaps.
* `NULL`: Explicitly permits empty attribute state.

```sql
CREATE TABLE product_license_allocations (
    allocation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id BIGINT UNSIGNED NOT NULL,
    license_key VARCHAR(64) NOT NULL,
    max_activations INT UNSIGNED NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_license_alloc PRIMARY KEY (allocation_id),
    CONSTRAINT uk_license_key UNIQUE (license_key),
    CONSTRAINT fk_alloc_product FOREIGN KEY (product_id) 
        REFERENCES products (product_id) ON DELETE CASCADE,
    CONSTRAINT chk_activations CHECK (max_activations > 0)
) ENGINE=InnoDB;
```

### 4.3 Referential Action Keywords

* `ON DELETE`: Triggers actions when a referenced parent row is deleted.
* `ON UPDATE`: Triggers actions when a referenced parent candidate key is updated.
* `CASCADE`: Automatically deletes or updates dependent child rows matching the parent.
* `RESTRICT`: Rejects parent mutation if matching child rows exist (immediate enforcement).
* `NO ACTION`: Identical to `RESTRICT` in MySQL InnoDB (ANSI deferred equivalent).
* `SET NULL`: Sets child foreign key columns to `NULL` upon parent mutation.
* `SET DEFAULT`: Sets child columns to column default (unsupported in InnoDB).

### 4.4 Generated and Virtual Columns

* `GENERATED ALWAYS AS (...)`: Declares a deterministic expression computing column values dynamically.
* `VIRTUAL`: Value is computed on-the-fly during query execution; zero disk footprint.
* `STORED`: Value is computed and written to disk on row insertion and update; supports secondary B-tree indexing.

```sql
ALTER TABLE products 
ADD COLUMN resolution_dpi INT 
GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(metadata_json, '$.dpi'))) STORED;
```

### 4.5 Partitioning Keywords

* `PARTITION BY`: Initiates physical horizontal partitioning.
* `SUBPARTITION BY`: Initiates composite two-tier subpartitioning.
* `RANGE`: Partitions based on value intervals (`VALUES LESS THAN (...)`).
* `RANGE COLUMNS`: Range partitioning supporting native date and string literals.
* `LIST`: Partitions based on discrete enumerated value sets (`VALUES IN (...)`).
* `HASH`: Partitions rows by modulo of an integer expression.
* `KEY`: Partitions rows using internal hashing of primary or unique keys.
* `MAXVALUE`: Boundary marker representing positive infinity for upper range partitions.
* `REORGANIZE PARTITION`: Merges, splits, or restructures existing partitions online.
* `DROP PARTITION`: Deletes partition along with all data contained within it instantly.
* `EXCHANGE PARTITION`: Swaps a partition with a non-partitioned standalone table without copying data.

---

## 5. Transaction Control Language (TCL) Keywords

TCL keywords manage atomic units of work, rollback boundaries, and concurrency isolation.

### 5.1 Transaction State Boundaries

| Keyword Phrase | Operational Mechanics |
| :--- | :--- |
| `START TRANSACTION` | Delimits beginning of atomic transaction block. Accepts `WITH CONSISTENT SNAPSHOT`. |
| `BEGIN` / `BEGIN WORK` | Standard aliases for `START TRANSACTION`. |
| `COMMIT` | Flushes dirty pages to redo log buffer and marks transaction durable in WAL. |
| `ROLLBACK` | Reverts all mutations within current transaction using undo log segments. |
| `SAVEPOINT` | Establishes an intermediate named marker within active transaction. |
| `ROLLBACK TO SAVEPOINT` | Reverts mutations back to named savepoint without aborting outer transaction. |
| `RELEASE SAVEPOINT` | Destroys named savepoint marker, retaining mutations made up to that point. |

```sql
START TRANSACTION;

UPDATE creator_wallets SET available_balance_cents = available_balance_cents - 1000 WHERE wallet_id = 50;
SAVEPOINT sp_payout_deducted;

-- Attempt external transfer
INSERT INTO payout_records (wallet_id, amount_cents) VALUES (50, 1000);

-- If external API rejects, revert only the insertion
ROLLBACK TO SAVEPOINT sp_payout_deducted;

COMMIT;
```

### 5.2 Concurrency and Isolation Clauses

* `SET TRANSACTION ISOLATION LEVEL`: Configures the MVCC visibility rules for transactions:
  * `READ UNCOMMITTED`: Permits dirty reads; bypasses MVCC snapshots.
  * `READ COMMITTED`: Fresh MVCC read view generated on each query statement.
  * `REPEATABLE READ`: Consistent read view established on first `SELECT` and retained until `COMMIT`.
  * `SERIALIZABLE`: Implicitly converts all plain `SELECT` queries to `LOCK IN SHARE MODE`.
* `READ WRITE`: Declares transaction intention to modify relations (default).
* `READ ONLY`: Informs optimizer that transaction will only read; skips transaction ID assignment.

### 5.3 Row-Level Locking Keywords

* `FOR UPDATE`: Acquires Exclusive (`X`) record locks on scanned index records; blocks other transactions from acquiring `X` or `S` locks.
* `FOR SHARE`: Acquires Shared (`S`) record locks; permits concurrent reads but blocks mutations.
* `LOCK IN SHARE MODE`: Legacy MySQL 5.7 syntax for `FOR SHARE`.
* `NOWAIT`: Causes query to fail immediately with error 3572 if target rows are locked by another transaction.
* `SKIP LOCKED`: Skips currently locked rows, returning only unlocked tuples. Essential for high-concurrency worker job queues.

```sql
-- Non-blocking high-concurrency job queue dequeue
SELECT task_id, payload 
FROM background_tasks 
WHERE status = 'pending' 
ORDER BY priority DESC 
LIMIT 1 
FOR UPDATE SKIP LOCKED;
```

---

## 6. Data Control Language (DCL) and Security Keywords

DCL keywords govern access authentication, role assignments, and privilege delegation.

### 6.1 Privilege Granting and Revocation

* `GRANT`: Bestows privileges or roles upon database accounts.
* `REVOKE`: Removes previously granted privileges or roles from database accounts.
* `TO`: Specifies recipient user or role in `GRANT`.
* `FROM`: Specifies target user or role in `REVOKE`.
* `WITH GRANT OPTION`: Authorizes recipient account to delegate its privileges to other users.

```sql
GRANT SELECT, INSERT, UPDATE ON sanara_ecommerce.orders TO 'sanara_app'@'10.0.1.%';
REVOKE DROP ON sanara_ecommerce.* FROM 'sanara_app'@'10.0.1.%';
```

### 6.2 Role-Based Access Control (RBAC) Keywords

* `CREATE ROLE`: Declares named collection of privileges.
* `DROP ROLE`: Destroys named role.
* `SET ROLE`: Activates specific assigned roles for the current database session.
* `SET DEFAULT ROLE`: Configures roles to activate automatically when an account connects.

```sql
CREATE ROLE 'role_analyst';
GRANT SELECT ON sanara_ecommerce.* TO 'role_analyst';
GRANT 'role_analyst' TO 'auditor_user'@'%';
SET DEFAULT ROLE 'role_analyst' TO 'auditor_user'@'%';
```

### 6.3 User Management and Password Rotation

* `CREATE USER`: Provisions new client authentication credentials.
* `ALTER USER`: Modifies password, authentication plugin, or connection limits.
* `DROP USER`: Destroys account credentials.
* `IDENTIFIED BY`: Assigns plaintext password string to be hashed by active authentication plugin.
* `IDENTIFIED WITH`: Specifies explicit authentication plugin (e.g., `caching_sha2_password`).
* `RETAIN CURRENT PASSWORD`: Enables dual-password state for zero-downtime rotation.
* `DISCARD OLD PASSWORD`: Removes secondary legacy password after application rotation.
* `PASSWORD EXPIRE`: Forces password expiration upon next connection.
* `ACCOUNT LOCK`: Disables client authentication for the target user.
* `ACCOUNT UNLOCK`: Re-enables client authentication.

---

## 7. Logical, Comparison, and Predicate Keywords

Predicate keywords govern Boolean truth evaluation in `WHERE`, `HAVING`, `ON`, and `CHECK` clauses.

### 7.1 Three-Valued Logic Operators

SQL implements three-valued logic where expressions evaluate to `TRUE`, `FALSE`, or `UNKNOWN` (`NULL`).

| Keyword | Operation | Truth Table Behavior |
| :--- | :--- | :--- |
| `AND` | Logical Conjunction | Evaluates `TRUE` only if both operands are `TRUE`. `TRUE AND UNKNOWN` yields `UNKNOWN`. |
| `OR` | Logical Disjunction | Evaluates `TRUE` if at least one operand is `TRUE`. `TRUE OR UNKNOWN` yields `TRUE`. |
| `NOT` | Logical Negation | Inverts Boolean truth: `NOT TRUE` -> `FALSE`, `NOT UNKNOWN` -> `UNKNOWN`. |
| `XOR` | Exclusive OR | Evaluates `TRUE` if exactly one operand is `TRUE` and neither is `NULL`. |
| `IS NULL` | Nullity Test | Evaluates `TRUE` if operand is `NULL`. Essential because `col = NULL` yields `UNKNOWN`. |
| `IS NOT NULL` | Value Existence | Evaluates `TRUE` if operand contains a defined value. |
| `IS TRUE` | Truth Test | Evaluates `TRUE` only if expression is strictly `TRUE` (not `UNKNOWN` or `FALSE`). |
| `IS FALSE` | Falsehood Test | Evaluates `TRUE` only if expression is strictly `FALSE`. |
| `IS UNKNOWN` | Unknown Test | Identical to `IS NULL` for Boolean expressions. |

### 7.2 Pattern Matching and Range Keywords

* `LIKE`: Evaluates wildcards (`%` for zero or more characters, `_` for exactly one character).
* `ESCAPE`: Specifies escape character overriding default backslash in `LIKE` expressions.
* `REGEXP` / `RLIKE`: Evaluates POSIX/ICU regular expression matching.
* `BETWEEN ... AND ...`: Inclusive range comparison equivalent to `(col >= low AND col <= high)`.

```sql
SELECT title FROM products 
WHERE title LIKE 'Baliho\_%' ESCAPE '\'
  AND price_amount_cents BETWEEN 10000 AND 50000;
```

### 7.3 Conditional Expressions

* `CASE`: Initiates conditional branch expression.
* `WHEN`: Evaluates condition.
* `THEN`: Specifies result expression when `WHEN` condition holds.
* `ELSE`: Fallback result expression if no `WHEN` conditions match.
* `END`: Concludes `CASE` expression.
* `COALESCE(...)`: Returns first non-null argument in list.
* `NULLIF(expr1, expr2)`: Returns `NULL` if `expr1 = expr2`, otherwise returns `expr1`.

```sql
SELECT 
    order_id,
    CASE 
        WHEN total_amount_cents >= 100000 THEN 'VIP'
        WHEN total_amount_cents >= 50000  THEN 'PREMIUM'
        ELSE 'STANDARD'
    END AS customer_tier,
    COALESCE(discount_amount_cents, 0) AS safe_discount
FROM orders;
```

---

## 8. Analytical, Window, and Aggregation Keywords

Windowing keywords compute calculations across relation subsets without collapsing tuples into single rows.

### 8.1 Window Definition Keywords

* `OVER`: Signals an analytical window function call.
* `PARTITION BY`: Divides input row stream into independent analytical partitions.
* `WINDOW`: Defines a named, reusable window specification at the query level.

```sql
SELECT 
    product_id, 
    category_id, 
    price_amount_cents,
    AVG(price_amount_cents) OVER w AS avg_cat_price,
    RANK() OVER w AS price_rank
FROM products
WINDOW w AS (PARTITION BY category_id ORDER BY price_amount_cents DESC);
```

### 8.2 Frame Specification Keywords

Frames define the dynamic subset of rows within a partition evaluated for running calculations:

* `ROWS`: Evaluates physical row offsets relative to current row.
* `RANGE`: Evaluates logical value differences relative to current row value.
* `GROUPS`: Evaluates peer value groups.
* `BETWEEN ... AND ...`: Frame boundary delimiter.
* `UNBOUNDED PRECEDING`: Frame starts at first row of partition.
* `UNBOUNDED FOLLOWING`: Frame extends to final row of partition.
* `CURRENT ROW`: Frame boundary anchored at active evaluated row.
* `n PRECEDING`: Frame boundary starts or ends $n$ units before current row.
* `n FOLLOWING`: Frame boundary starts or ends $n$ units after current row.

```sql
-- 7-day rolling sales volume average
SELECT 
    order_date,
    daily_revenue,
    AVG(daily_revenue) OVER (
        ORDER BY order_date
        RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW
    ) AS rolling_7day_avg
FROM daily_sales_summary;
```

---

## 9. Procedural Programming, Control Flow, and Exception Keywords

Procedural keywords construct server-side business logic, transaction workflows, and reactive triggers.

### 9.1 Block and Control Flow Keywords

| Keyword | Grammatical Context | Functionality |
| :--- | :--- | :--- |
| `BEGIN ... END` | Compound statement | Delimits structured block containing declarations and procedural logic. |
| `DELIMITER` | Client utility | Reassigns query delimiter string in MySQL CLI client. |
| `DECLARE` | Block initialization | Declares local variables, conditions, cursors, and handlers. |
| `IF ... THEN ... ELSEIF ... ELSE ... END IF` | Branching | Conditional logic branching based on Boolean evaluation. |
| `WHILE ... DO ... END WHILE` | Pre-test Loop | Repeats statements while condition evaluates to `TRUE`. |
| `REPEAT ... UNTIL ... END REPEAT` | Post-test Loop | Repeats statements until condition evaluates to `TRUE`. |
| `LOOP ... END LOOP` | Labeled Loop | Unconditional iteration loop controlled via `LEAVE` and `ITERATE`. |
| `LEAVE` | Loop termination | Immediately breaks execution out of labeled compound block or loop. |
| `ITERATE` | Loop jump | Skips remaining statements and starts next iteration of labeled loop. |
| `CALL` | Procedure execution | Invokes a stored procedure passing `IN`, `OUT`, or `INOUT` parameters. |
| `RETURN` | Function exit | Terminating statement in stored function returning computed scalar. |

### 9.2 Cursor Management Keywords

* `CURSOR FOR`: Defines a forward-only, read-only result set cursor.
* `OPEN`: Evaluates cursor query and allocates cursor memory structures.
* `FETCH`: Retrieves next row from cursor into local variables.
* `CLOSE`: Deallocates cursor memory.

### 9.3 Exception Handling and Signaling Keywords

* `DECLARE ... HANDLER FOR`: Configures procedural error catch block.
* `CONTINUE`: Resumes procedural execution at the next statement after handler executes.
* `EXIT`: Immediately terminates the enclosing `BEGIN ... END` block after handler executes.
* `SQLEXCEPTION`: Catch-all condition matching any error code with SQLSTATE not starting with `'00'`, `'01'`, or `'02'`.
* `SQLWARNING`: Condition matching warnings (SQLSTATE starting with `'01'`).
* `NOT FOUND`: Condition matching cursor end-of-data (SQLSTATE starting with `'02'`).
* `SIGNAL`: Raises custom error state and user-defined message (`SIGNAL SQLSTATE '45000'`).
* `RESIGNAL`: Re-raises active error from within a handler block.
* `GET DIAGNOSTICS`: Extracts error numbers, messages, and condition counts from diagnostic area.

```sql
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    GET DIAGNOSTICS CONDITION 1
        @err_no = MYSQL_ERRNO, @err_msg = MESSAGE_TEXT;
    ROLLBACK;
    RESIGNAL SET MESSAGE_TEXT = @err_msg;
END;
```

### 9.4 Routine and Trigger Modifiers

* `DETERMINISTIC`: Declares function produces identical results given identical parameters.
* `NOT DETERMINISTIC`: Declares function output may vary dynamically.
* `CONTAINS SQL` / `NO SQL` / `READS SQL DATA` / `MODIFIES SQL DATA`: Explicit data access assertions.
* `SQL SECURITY DEFINER`: Executes routine with privileges of the user declared in `DEFINER`.
* `SQL SECURITY INVOKER`: Executes routine with privileges of the invoking session user.
* `BEFORE` / `AFTER`: Specifies trigger execution timing relative to engine write.
* `FOR EACH ROW`: Mandates row-level trigger execution for every mutated tuple.
* `NEW`: Trigger pseudorecord referencing pending row attributes.
* `OLD`: Trigger pseudorecord referencing pre-mutation row attributes.
* `PRECEDES` / `FOLLOWS`: Explicitly establishes trigger execution sequence.

---

## 10. Semi-Structured, Full-Text, and Spatial Keywords

Keywords facilitating modern hybrid relational workflows.

### 10.1 Relational JSON Projection (`JSON_TABLE`)

`JSON_TABLE` transforms hierarchical JSON arrays into standard relational row sets directly within the `FROM` clause:

* `JSON_TABLE(...)`: Table function converting JSON document into relation.
* `COLUMNS`: Delimits column projection specifications.
* `PATH`: JSONPath expression identifying target attribute (`'$.item_id'`).
* `NESTED PATH`: Unnests child JSON arrays into multiple relational rows.
* `EXISTS`: Projects Boolean flag indicating whether target JSON path exists.
* `ERROR ON EMPTY` / `NULL ON EMPTY` / `DEFAULT ... ON EMPTY`: Defines handling when JSON path produces zero data.
* `ERROR ON ERROR` / `NULL ON ERROR`: Defines handling when JSON type conversion fails.

```sql
SELECT jt.tag_name
FROM products p,
JSON_TABLE(p.metadata_json, '$.tags[*]' COLUMNS (
    tag_name VARCHAR(50) PATH '$'
)) AS jt;
```

### 10.2 Full-Text Search Keywords

* `MATCH (...) AGAINST (...)`: Full-text inverted index search expression.
* `IN BOOLEAN MODE`: Evaluates search operators (`+` must exist, `-` exclude, `*` wildcard, `"` phrase).
* `IN NATURAL LANGUAGE MODE`: Standard relevance scoring based on word frequency.
* `WITH QUERY EXPANSION`: Two-phase blind relevance feedback expansion.

```sql
SELECT product_id, title 
FROM products 
WHERE MATCH(title, subtitle, search_keywords) AGAINST('+billboard -banner' IN BOOLEAN MODE);
```

---

## 11. Administrative, Diagnostic, and Inspection Keywords

Keywords utilized for database engine telemetry, query profiling, and system maintenance.

### 11.1 Query Execution Plan Profiling

* `EXPLAIN`: Requests optimizer execution plan for query.
* `ANALYZE`: Executes query and measures actual iterator runtimes, row counts, and loop iterations.
* `FORMAT = TREE`: Outputs query plan as hierarchical iterator cost tree.
* `FORMAT = JSON`: Outputs comprehensive JSON structure detailing optimizer costs and memory allocations.

### 11.2 Diagnostics and Server State

* `SHOW`: Displays metadata, server status, process lists, or engine telemetry.
  * `SHOW PROCESSLIST` / `SHOW FULL PROCESSLIST`: Displays active client threads and execution states.
  * `SHOW ENGINE INNODB STATUS`: Displays lock graphs, MVCC coordinates, and buffer pool stats.
  * `SHOW VARIABLES`: Inspects active system variables.
  * `SHOW STATUS`: Inspects cumulative server telemetry counters.
* `DESCRIBE` / `DESC`: Inspects table column definitions and index nullability.
* `USE`: Sets active default database for session.
* `KILL`: Terminates client thread or running query (`KILL QUERY <thread_id>`, `KILL CONNECTION <thread_id>`).

### 11.3 Engine Maintenance

* `OPTIMIZE TABLE`: Rebuilds clustered index and defragments tablespace.
* `ANALYZE TABLE`: Samples B-tree keys to update optimizer index cardinality statistics.
* `CHECK TABLE`: Scans table for physical page corruption.
* `FLUSH`: Flushes internal caches to disk (`FLUSH TABLES`, `FLUSH PRIVILEGES`, `FLUSH LOGS`).

---

## 12. Exhaustive A-Z SQL Keyword Reference Matrix

The following index provides an exhaustive classification of SQL keywords, their reserved status under ANSI SQL and MySQL 8.0, functional domains, and canonical syntax patterns.

| Keyword | Domain | ANSI Reserved | MySQL 8.0 Reserved | Canonical Syntax Pattern |
| :--- | :--- | :--- | :--- | :--- |
| `ADD` | DDL | Yes | Yes | `ALTER TABLE t ADD COLUMN c INT;` |
| `ALL` | DQL | Yes | Yes | `SELECT ALL col FROM t;` |
| `ALTER` | DDL | Yes | Yes | `ALTER TABLE t DROP COLUMN c;` |
| `ANALYZE` | Admin | No | Yes | `ANALYZE TABLE t;` / `EXPLAIN ANALYZE SELECT ...;` |
| `AND` | Logical | Yes | Yes | `WHERE a = 1 AND b = 2;` |
| `ANY` | DQL | Yes | Yes | `WHERE x > ANY(SELECT y FROM t);` |
| `AS` | DQL | Yes | Yes | `SELECT col AS alias FROM t;` |
| `ASC` | DQL | Yes | Yes | `ORDER BY col ASC;` |
| `AUTO_INCREMENT` | DDL | No | No | `id INT AUTO_INCREMENT PRIMARY KEY;` |
| `BEFORE` | Trigger | Yes | Yes | `CREATE TRIGGER trg BEFORE INSERT ON t ...;` |
| `BEGIN` | TCL/Flow | Yes | No | `START TRANSACTION;` / `BEGIN ... END;` |
| `BETWEEN` | Predicate | Yes | Yes | `WHERE price BETWEEN 10 AND 50;` |
| `BY` | DQL | Yes | Yes | `GROUP BY col;` / `ORDER BY col;` |
| `CALL` | Flow | Yes | Yes | `CALL sp_process_order(101);` |
| `CASCADE` | DDL | Yes | Yes | `FOREIGN KEY (...) REFERENCES ... ON DELETE CASCADE;` |
| `CASE` | Predicate | Yes | Yes | `CASE WHEN a THEN 1 ELSE 0 END;` |
| `CHANGE` | DDL | No | Yes | `ALTER TABLE t CHANGE old_col new_col VARCHAR(50);` |
| `CHECK` | DDL | Yes | Yes | `CONSTRAINT chk_qty CHECK (qty > 0);` |
| `COLLATE` | DDL | Yes | Yes | `CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;` |
| `COLUMN` | DDL | Yes | Yes | `ALTER TABLE t DROP COLUMN c;` |
| `COMMIT` | TCL | Yes | No | `COMMIT;` |
| `CONSTRAINT` | DDL | Yes | Yes | `CONSTRAINT pk_orders PRIMARY KEY (order_id);` |
| `CONTINUE` | Flow | Yes | Yes | `DECLARE CONTINUE HANDLER FOR NOT FOUND ...;` |
| `CREATE` | DDL | Yes | Yes | `CREATE TABLE t (...);` |
| `CROSS` | DQL | Yes | Yes | `SELECT * FROM t1 CROSS JOIN t2;` |
| `CURRENT_TIMESTAMP` | Temporal | Yes | Yes | `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;` |
| `CURSOR` | Flow | Yes | Yes | `DECLARE cur CURSOR FOR SELECT ...;` |
| `DATABASE` | DDL | No | Yes | `CREATE DATABASE sanara_ecommerce;` |
| `DECLARE` | Flow | Yes | Yes | `DECLARE v_total INT DEFAULT 0;` |
| `DEFAULT` | DDL | Yes | Yes | `status VARCHAR(20) DEFAULT 'pending';` |
| `DELETE` | DML | Yes | Yes | `DELETE FROM t WHERE id = 1;` |
| `DESC` | DQL | Yes | Yes | `ORDER BY created_at DESC;` / `DESC table_name;` |
| `DETERMINISTIC` | Routine | Yes | Yes | `CREATE FUNCTION f(...) RETURNS INT DETERMINISTIC ...;` |
| `DISTINCT` | DQL | Yes | Yes | `SELECT DISTINCT category_id FROM products;` |
| `DROP` | DDL | Yes | Yes | `DROP TABLE t;` |
| `ELSE` | Flow | Yes | Yes | `IF cond THEN ... ELSE ... END IF;` |
| `ELSEIF` | Flow | Yes | Yes | `IF a THEN ... ELSEIF b THEN ... END IF;` |
| `END` | Flow | Yes | No | `BEGIN ... END;` / `CASE ... END;` |
| `ENGINE` | DDL | No | No | `CREATE TABLE t (...) ENGINE=InnoDB;` |
| `ESCAPE` | Predicate | Yes | No | `WHERE col LIKE '%\%%' ESCAPE '\';` |
| `EXCEPT` | Set | Yes | Yes | `SELECT a FROM t1 EXCEPT SELECT a FROM t2;` |
| `EXCLUDE` | Window | Yes | No | `WINDOW w AS (... EXCLUDE CURRENT ROW);` |
| `EXECUTE` | DCL/Routine| Yes | No | `GRANT EXECUTE ON PROCEDURE sp TO 'app'@'%';` |
| `EXISTS` | Predicate | Yes | Yes | `WHERE EXISTS (SELECT 1 FROM t WHERE ...);` |
| `EXIT` | Flow | Yes | Yes | `DECLARE EXIT HANDLER FOR SQLEXCEPTION ...;` |
| `EXPLAIN` | Admin | No | Yes | `EXPLAIN ANALYZE SELECT * FROM t;` |
| `FETCH` | Flow | Yes | Yes | `FETCH cur INTO v_id, v_val;` |
| `FOR` | DQL/Lock | Yes | Yes | `SELECT * FROM t FOR UPDATE;` |
| `FOREIGN` | DDL | Yes | Yes | `FOREIGN KEY (user_id) REFERENCES users (id);` |
| `FROM` | DQL | Yes | Yes | `SELECT * FROM orders;` |
| `FULL` | DQL | Yes | No | `SELECT * FROM t1 FULL OUTER JOIN t2;` |
| `FUNCTION` | DDL | Yes | Yes | `CREATE FUNCTION fn_tax(...) RETURNS DECIMAL;` |
| `GENERATED` | DDL | Yes | Yes | `col INT GENERATED ALWAYS AS (a + b) STORED;` |
| `GRANT` | DCL | Yes | Yes | `GRANT SELECT ON db.* TO 'user'@'%';` |
| `GROUP` | DQL | Yes | Yes | `GROUP BY category_id;` |
| `HAVING` | DQL | Yes | Yes | `HAVING COUNT(*) > 5;` |
| `IF` | Flow | No | Yes | `IF v_count = 0 THEN ... END IF;` |
| `IGNORE` | DML | No | Yes | `INSERT IGNORE INTO t (...) VALUES (...);` |
| `IN` | Predicate | Yes | Yes | `WHERE status IN ('paid', 'shipped');` |
| `INDEX` | DDL | No | Yes | `CREATE INDEX idx_name ON t (col);` |
| `INNER` | DQL | Yes | Yes | `SELECT * FROM a INNER JOIN b ON a.id = b.id;` |
| `INOUT` | Routine | Yes | Yes | `CREATE PROCEDURE p(INOUT counter INT) ...;` |
| `INSERT` | DML | Yes | Yes | `INSERT INTO t (col) VALUES (1);` |
| `INTERSECT` | Set | Yes | Yes | `SELECT a FROM t1 INTERSECT SELECT a FROM t2;` |
| `INTO` | DML | Yes | Yes | `INSERT INTO t ...;` / `SELECT col INTO v_var ...;` |
| `IS` | Predicate | Yes | Yes | `WHERE col IS NULL;` / `WHERE val IS TRUE;` |
| `ITERATE` | Flow | Yes | Yes | `IF v_done THEN ITERATE loop_lbl; END IF;` |
| `JOIN` | DQL | Yes | Yes | `FROM t1 JOIN t2 ON t1.id = t2.id;` |
| `KEY` | DDL | Yes | Yes | `PRIMARY KEY (id);` / `KEY idx_col (col);` |
| `KILL` | Admin | No | Yes | `KILL QUERY 142;` |
| `LEAVE` | Flow | Yes | Yes | `LEAVE proc_label;` |
| `LEFT` | DQL | Yes | Yes | `FROM t1 LEFT JOIN t2 ON t1.id = t2.id;` |
| `LIKE` | Predicate | Yes | Yes | `WHERE title LIKE '%graphic%';` |
| `LIMIT` | DQL | No | Yes | `LIMIT 10 OFFSET 20;` |
| `LOCK` | Lock | No | Yes | `LOCK TABLES orders WRITE;` |
| `MATCH` | FTS | Yes | Yes | `WHERE MATCH(title) AGAINST('poster');` |
| `MODIFY` | DDL | No | No | `ALTER TABLE t MODIFY COLUMN c BIGINT NOT NULL;` |
| `NATURAL` | DQL | Yes | Yes | `SELECT * FROM t1 NATURAL JOIN t2;` |
| `NOT` | Logical | Yes | Yes | `WHERE NOT (a = 1);` |
| `NOWAIT` | Lock | No | No | `SELECT * FROM t FOR UPDATE NOWAIT;` |
| `NULL` | Value | Yes | Yes | `WHERE deleted_at IS NULL;` |
| `OFFSET` | DQL | Yes | No | `LIMIT 10 OFFSET 30;` |
| `ON` | DQL/DDL | Yes | Yes | `ON a.id = b.id;` / `ON DELETE CASCADE;` |
| `OPEN` | Flow | Yes | Yes | `OPEN cur;` |
| `OPTIMIZE` | Admin | No | Yes | `OPTIMIZE TABLE orders;` |
| `OR` | Logical | Yes | Yes | `WHERE a = 1 OR b = 2;` |
| `ORDER` | DQL | Yes | Yes | `ORDER BY created_at DESC;` |
| `OUT` | Routine | Yes | Yes | `CREATE PROCEDURE p(OUT res INT) ...;` |
| `OUTER` | DQL | Yes | Yes | `LEFT OUTER JOIN t2 ON ...;` |
| `OVER` | Window | Yes | Yes | `ROW_NUMBER() OVER (ORDER BY id);` |
| `PARTITION` | DDL/Window| Yes | Yes | `PARTITION BY RANGE (...);` / `OVER (PARTITION BY c);` |
| `PRIMARY` | DDL | Yes | Yes | `PRIMARY KEY (id);` |
| `PROCEDURE` | DDL | Yes | Yes | `CREATE PROCEDURE sp_init() ...;` |
| `RANGE` | DDL/Window| Yes | Yes | `PARTITION BY RANGE;` / `RANGE BETWEEN ...;` |
| `READS` | Routine | Yes | Yes | `CREATE FUNCTION f(...) READS SQL DATA ...;` |
| `REFERENCES` | DDL | Yes | Yes | `REFERENCES parent_table (parent_id);` |
| `REGEXP` | Predicate | No | Yes | `WHERE sku REGEXP '^[A-Z]{3}-[0-9]{4}$';` |
| `RELEASE` | TCL | Yes | Yes | `RELEASE SAVEPOINT sp1;` |
| `RENAME` | DDL | No | Yes | `RENAME TABLE t1 TO t2;` |
| `REPEAT` | Flow | Yes | Yes | `REPEAT ... UNTIL cond END REPEAT;` |
| `REPLACE` | DML | No | Yes | `REPLACE INTO t (id, val) VALUES (1, 'A');` |
| `RESTRICT` | DDL | Yes | Yes | `ON DELETE RESTRICT;` |
| `RETURN` | Flow | Yes | Yes | `RETURN v_computed_val;` |
| `REVOKE` | DCL | Yes | Yes | `REVOKE ALL PRIVILEGES ON db.* FROM 'user'@'%';` |
| `RIGHT` | DQL | Yes | Yes | `FROM t1 RIGHT JOIN t2 ON ...;` |
| `ROLLBACK` | TCL | Yes | No | `ROLLBACK;` |
| `ROW` | Window/DML| Yes | Yes | `VALUES ROW(1, 2), ROW(3, 4);` |
| `ROWS` | Window | Yes | No | `ROWS BETWEEN 1 PRECEDING AND CURRENT ROW;` |
| `SAVEPOINT` | TCL | Yes | No | `SAVEPOINT sp_checkpoint;` |
| `SCHEMA` | DDL | No | Yes | `CREATE SCHEMA IF NOT EXISTS sanara_ecommerce;` |
| `SELECT` | DQL | Yes | Yes | `SELECT col FROM t;` |
| `SET` | DML/DCL/DDL| Yes | Yes | `UPDATE t SET c = 1;` / `SET @var = 1;` |
| `SIGNAL` | Flow | Yes | Yes | `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Err';` |
| `SKIP` | Lock | No | No | `SELECT * FROM t FOR UPDATE SKIP LOCKED;` |
| `START` | TCL/Repl | Yes | No | `START TRANSACTION;` / `START REPLICA;` |
| `STORED` | DDL | No | Yes | `col INT GENERATED ALWAYS AS (x) STORED;` |
| `STRAIGHT_JOIN`| Hint | No | Yes | `SELECT * FROM t1 STRAIGHT_JOIN t2;` |
| `TABLE` | DDL | Yes | Yes | `CREATE TABLE t (...);` |
| `THEN` | Flow | Yes | Yes | `CASE WHEN cond THEN val END;` |
| `TO` | DCL | Yes | Yes | `GRANT 'role' TO 'user'@'%';` |
| `TRIGGER` | DDL | Yes | Yes | `CREATE TRIGGER trg AFTER INSERT ON t ...;` |
| `TRUNCATE` | DDL | No | No | `TRUNCATE TABLE t;` |
| `UNION` | Set | Yes | Yes | `SELECT a FROM t1 UNION SELECT a FROM t2;` |
| `UNIQUE` | DDL | Yes | Yes | `CONSTRAINT uk_email UNIQUE (email);` |
| `UNLOCK` | Lock | No | Yes | `UNLOCK TABLES;` |
| `UPDATE` | DML | Yes | Yes | `UPDATE t SET col = 1 WHERE id = 10;` |
| `USE` | Admin | No | Yes | `USE sanara_ecommerce;` |
| `USING` | DQL/DDL | Yes | Yes | `JOIN t2 USING (order_id);` |
| `VALUES` | DML | Yes | Yes | `INSERT INTO t (c) VALUES (1), (2);` |
| `VIEW` | DDL | No | No | `CREATE VIEW v_active_users AS SELECT ...;` |
| `VIRTUAL` | DDL | No | Yes | `col INT GENERATED ALWAYS AS (x) VIRTUAL;` |
| `WHEN` | Predicate | Yes | Yes | `WHEN cond THEN val;` |
| `WHERE` | DQL/DML | Yes | Yes | `WHERE id = 5;` |
| `WHILE` | Flow | Yes | Yes | `WHILE cond DO ... END WHILE;` |
| `WINDOW` | Window | Yes | Yes | `WINDOW w AS (PARTITION BY cat ORDER BY dt);` |
| `WITH` | CTE | Yes | Yes | `WITH cte AS (SELECT ...) SELECT * FROM cte;` |
| `XOR` | Logical | No | Yes | `WHERE a XOR b;` |
