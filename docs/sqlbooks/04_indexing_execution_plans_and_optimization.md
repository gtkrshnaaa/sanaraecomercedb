# Volume 4: Indexing Engines, Query Execution & Profiling
## InnoDB B+Tree Architecture, Covering Indexes, Leftmost Prefix Rules, and EXPLAIN ANALYZE Deep Dives

### 1. InnoDB Physical Page Architecture

In MySQL InnoDB, data is not stored as an unstructured log, but within strict physical page hierarchies:

```text
┌─────────────────────────────────────────────────────────────┐
│                 Tablespace (.ibd file)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               Extent (1 MB = 64 Pages)                │  │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐            │  │
│  │  │ Page 16KB │ │ Page 16KB │ │ Page 16KB │ ...        │  │
│  │  └───────────┘ └───────────┘ └───────────┘            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### 1.1 The 16 KB Page Structure
Every InnoDB page is 16,384 bytes by default (`innodb_page_size=16k`). A page contains:
* **Page Header**: LSN (Log Sequence Number), page directory slot count, heap pointers.
* **User Records**: The physical row data (or index keys).
* **Free Space**: Unallocated bytes for future inserts/updates.
* **Page Directory**: Sparse index of 4-to-8 row slots enabling $O(\log N)$ binary search within a page in memory.
* **Fil Trailer**: Checksum for verifying data integrity against silent disk block corruption.

#### 1.2 Clustered Index vs Secondary Index
* **Clustered Index**: In InnoDB, every table possesses exactly one clustered index. The `PRIMARY KEY` defines the clustered index. The leaf pages of the clustered index B+Tree contain the complete, physical row data.
* **Secondary Index**: An auxiliary index created on non-PK columns. Crucially, the leaf pages of a secondary index do *not* contain the row data; they contain the indexed column values and the **Primary Key value**.

```text
Secondary Index Lookup (Non-Covering):
[Root Node] -> [Branch Node] -> [Leaf Node: (Status='published', PK=42)]
                                                   │
                                                   ▼
Secondary Index Secondary Lookup (Clustered Index PK Traverse):
[PK Root] -> [PK Branch] -> [PK Leaf (ID=42, All Data Columns)]
```

* **Covering Index Optimization**: If a query's `SELECT`, `WHERE`, and `ORDER BY` clauses reference only attributes present in the secondary index (plus the implicit PK), InnoDB completely skips the clustered index secondary traversal (`Using index` in `EXPLAIN`).

---

### 2. B+Tree Mechanics & Composite Index Rules

A B+Tree maintains sorted key order across high fan-out nodes (often 500 to 1,200 child pointers per 16KB branch page). This guarantees shallow tree depth: a 3-level B+Tree can index over 20 million records with at most 3 page lookups.

#### 2.1 The Leftmost Prefix Rule
A composite index on multiple attributes $(A, B, C)$ is sorted strictly hierarchically: first by $A$, then by $B$ within identical values of $A$, then by $C$ within identical values of $(A, B)$.

```sql
INDEX idx_prod_search (status, category_id, base_standard_price)
```

| Query Filter Pattern | Can Use Index Seeks? | Notes |
|---|---|---|
| `WHERE status = 'published'` | Yes (Column A) | Direct B+Tree range seek. |
| `WHERE status = 'published' AND category_id = 2` | Yes (Columns A + B) | Composite B+Tree seek on (A, B). |
| `WHERE status = 'published' AND category_id = 2 AND base_standard_price < 100` | Yes (Columns A + B + C) | Full composite seek down to range on C. |
| `WHERE category_id = 2` | **No** (Violates Leftmost Prefix) | Requires full index scan or table scan. |
| `WHERE status = 'published' AND base_standard_price < 100` | Partial (A only) | Seeks on $A$; column $C$ filtered via Index Condition Pushdown (ICP). |

#### 2.2 The Range Boundary Stop Rule
Once an index seek encounters a range operator (`>`, `<`, `BETWEEN`, `LIKE 'prefix%'`), the B+Tree cannot perform point seeks on subsequent columns in the composite key.

*Example*:
```sql
-- Column A uses exact equality; Column B uses range. Column C CANNOT seek:
WHERE status = 'published' AND base_standard_price > 50.00 AND category_id = 2
```
*Optimization*: Reorder index attributes so all equality columns appear first: `INDEX (status, category_id, base_standard_price)`.

---

### 3. Specialized Index Types

#### 3.1 Full-Text Search (FTS) Indexes
Standard B+Tree indexes cannot optimize substring wildcards (`LIKE '%billboard%'`). MySQL Full-Text search constructs an Inverted Index mapping tokenized words to document IDs.

```sql
-- Create full-text index across localized descriptions:
ALTER TABLE product_translations_i18n 
ADD FULLTEXT INDEX idx_fts_trans (localized_title, localized_description);

-- High-speed natural language boolean search:
SELECT product_id, localized_title, MATCH(localized_title, localized_description) AGAINST('+billboard +highway -vinyl' IN BOOLEAN MODE) AS relevance_score
FROM product_translations_i18n
WHERE MATCH(localized_title, localized_description) AGAINST('+billboard +highway -vinyl' IN BOOLEAN MODE)
ORDER BY relevance_score DESC;
```

#### 3.2 Generated Column Indexing
Index complex JSON attributes or arithmetic computations without modifying application code:

```sql
-- Create virtual generated column and index it:
ALTER TABLE products 
ADD COLUMN resolution_dpi SMALLINT UNSIGNED 
    GENERATED ALWAYS AS (CAST(design_metadata->>'$.print_specs.dpi' AS UNSIGNED)) VIRTUAL,
ADD INDEX idx_prod_dpi (resolution_dpi);

-- Direct sub-millisecond B+Tree seek on JSON attribute:
SELECT id, title FROM products WHERE resolution_dpi = 300;
```

---

### 4. Reading `EXPLAIN` and `EXPLAIN ANALYZE` Profiles

#### 4.1 Traditional `EXPLAIN` Access Types (Ranked from Best to Worst)
1. `system` / `const`: Single row match against primary or unique key in memory.
2. `eq_ref`: 1 row retrieved from this table for each combination of rows from the prior table (indexed primary/unique key join).
3. `ref`: Matching rows retrieved using non-unique index.
4. `range`: Index range scan (`BETWEEN`, `>`, `<`, `IN`).
5. `index`: Full index scan (scans secondary index leaf chain; avoids table scan if index is covering).
6. `ALL`: Full table scan (reads every page from disk; optimize immediately).

#### 4.2 Modern `EXPLAIN ANALYZE` Tree Decoding
Introduced in MySQL 8.0.18, `EXPLAIN ANALYZE` executes the query, tracks physical wall-clock timings, and emits tree metrics:

```sql
EXPLAIN ANALYZE
SELECT o.id, o.order_number, i.unit_price
FROM orders o
JOIN order_items i ON o.id = i.order_id
WHERE o.status = 'completed';
```

*Output Tree Breakdown*:
```text
-> Nested loop inner join  (cost=2.45 rows=7) (actual time=0.038..0.082 rows=7 loops=1)
    -> Filter: (o.`status` = 'completed')  (cost=0.65 rows=4) (actual time=0.021..0.032 rows=4 loops=1)
        -> Table scan on o  (cost=0.65 rows=4) (actual time=0.018..0.028 rows=4 loops=1)
    -> Index lookup on i using idx_items_order (order_id=o.id)  (cost=0.41 rows=2) (actual time=0.010..0.011 rows=2 loops=4)
```

*Reading Metrics*:
* `(cost=2.45 rows=7)`: Optimizer's cost calculation and cardinality estimate.
* `actual time=0.038..0.082`: Time in milliseconds to return the first row (0.038ms) and all matching rows (0.082ms).
* `rows=7 loops=1`: Actual number of rows returned, and how many times the operation iterated. (Notice inner index lookup executed `loops=4` for the 4 matching orders).

#### 4.3 Optimizer Hints
Force or prevent specific index behaviors when statistics drift:

```sql
SELECT /*+ INDEX(p idx_prod_status_published) */ 
    id, title, base_standard_price 
FROM products p 
WHERE status = 'published';
```
