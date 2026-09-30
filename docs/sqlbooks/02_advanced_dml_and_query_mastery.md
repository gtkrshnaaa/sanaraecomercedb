# Volume 2: Advanced DML & Query Engineering
## Logical Query Processing, Modern Analytical Functions, Recursive CTEs, and JSON Shredding

### 1. The Logical Processing Order of SQL Clauses

While written from `SELECT` to `LIMIT`, an ANSI SQL query is executed by the query engine in a strict logical sequence. Understanding this sequence is vital for predicting filtering behavior, alias visibility, and aggregation boundaries:

```text
Step 1: FROM (Cross join / Table resolution)
Step 2: ON (Join condition evaluation)
Step 3: JOIN (Outer / Left / Right join preservation)
Step 4: WHERE (Row-level filtering before aggregation)
Step 5: GROUP BY (Set partitioning)
Step 6: WITH ROLLUP (Hierarchical summary rows)
Step 7: HAVING (Group-level filtering)
Step 8: SELECT (Projection and scalar expressions)
Step 9: DISTINCT (Duplicate tuple elimination)
Step 10: ORDER BY (Sorting)
Step 11: LIMIT / OFFSET (Result set windowing)
```

*Crucial Consequence*: Column aliases defined in `SELECT` cannot be referenced in `WHERE` or `HAVING` clauses because `SELECT` is evaluated after `WHERE` and `HAVING`.

---

### 2. Advanced Relational Joins & Join Algorithms

#### 2.1 Join Semantics
* **`INNER JOIN`**: Retains only matching rows where the join predicate evaluates to `TRUE`.
* **`LEFT JOIN`**: Retains all rows from the left table; fills right-side attributes with `NULL` where no match exists.
* **`RIGHT JOIN`**: Mirror of left join (prefer left join for code readability).
* **`FULL OUTER JOIN`**: Retains all rows from both tables. MySQL lacks native full outer join syntax; simulated using `UNION`:
```sql
SELECT a.id, b.id FROM table_a a LEFT JOIN table_b b ON a.id = b.id
UNION
SELECT a.id, b.id FROM table_a a RIGHT JOIN table_b b ON a.id = b.id;
```
* **`CROSS JOIN`**: Cartesian product ($|R| \times |S|$ rows). Used for generating matrices, permutations, or date ranges.
* **`SELF JOIN`**: A table joined to itself, essential for adjacency list trees (e.g., category parent-child hierarchies).

#### 2.2 MySQL 8.0 Join Execution Mechanics
MySQL 8.0 features modern join algorithms:
1. **Nested Loop Join (NLJ)**: Evaluates outer table rows one-by-one, seeking corresponding rows in the inner table via an index lookup ($O(N \log M)$).
2. **Hash Join**: Introduced in MySQL 8.0.18 to replace Block Nested Loop (BNL). Builds an in-memory hash table on the smaller relation, then streams the larger relation through the hash table for exact key matching. Extremely efficient for unindexed equality joins.

---

### 3. Window Functions (Analytical SQL)

Window functions perform calculations across a defined set of rows related to the current row without collapsing the result set into a single summary row like `GROUP BY`.

#### 3.1 Structure of the `OVER` Clause
```sql
FUNCTION(...) OVER (
    [PARTITION BY partition_column]
    [ORDER BY sort_column [ASC|DESC]]
    [ROWS|RANGE BETWEEN frame_start AND frame_end]
)
```

#### 3.2 Ranking Functions
* `ROW_NUMBER()`: Assigns a unique sequential integer starting at 1 within each partition.
* `RANK()`: Assigns sequential ranks with gaps when ties occur (e.g., 1, 2, 2, 4).
* `DENSE_RANK()`: Assigns sequential ranks without gaps when ties occur (e.g., 1, 2, 2, 3).
* `NTILE(k)`: Divides the partition into $k$ equal buckets (e.g., quartiles, percentiles).

*Example: Top 3 Highest Earning Products per Category*:
```sql
WITH ranked_catalog AS (
    SELECT 
        p.id AS product_id,
        p.category_id,
        p.title,
        p.total_sales_count * p.base_standard_price AS gross_revenue_usd,
        DENSE_RANK() OVER (
            PARTITION BY p.category_id 
            ORDER BY (p.total_sales_count * p.base_standard_price) DESC
        ) AS category_revenue_rank
    FROM `products` p
    WHERE p.status = 'published'
)
SELECT * FROM ranked_catalog WHERE category_revenue_rank <= 3;
```

#### 3.3 Offset & Navigation Functions
* `LAG(col, offset, default)`: Accesses data from a previous row within the partition without a self-join.
* `LEAD(col, offset, default)`: Accesses data from a subsequent row within the partition.

*Example: Month-over-Month Revenue Growth Percentage*:
```sql
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.created_at, '%Y-%m-01') AS sales_month,
        SUM(o.total_amount) AS current_month_revenue
    FROM `orders` o
    WHERE o.status = 'completed'
    GROUP BY DATE_FORMAT(o.created_at, '%Y-%m-01')
)
SELECT 
    sales_month,
    current_month_revenue,
    LAG(current_month_revenue, 1) OVER (ORDER BY sales_month) AS prior_month_revenue,
    ROUND(
        ((current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY sales_month)) /
         LAG(current_month_revenue, 1) OVER (ORDER BY sales_month)) * 100.0, 2
    ) AS mom_growth_pct
FROM monthly_sales;
```

---

### 4. Common Table Expressions (CTEs) & Recursive Hierarchies

Common Table Expressions (CTEs) provide modular, readable query decomposition and unlock graph traversal through recursion.

#### 4.1 Recursive CTE Anatomy
A recursive CTE consists of:
1. **Anchor Member**: The initial base query (non-recursive).
2. **UNION ALL**: The combiner linking anchor to recursion.
3. **Recursive Member**: The iterative query referencing the CTE itself.
4. **Termination Condition**: Guarantees termination when no further tuples are returned.

*Example: Traversal of Category Hierarchy Trees*:
```sql
WITH RECURSIVE category_tree AS (
    -- Anchor Member: Root Categories (Level 1)
    SELECT 
        c.id,
        c.parent_id,
        c.name,
        c.slug,
        CAST(c.name AS CHAR(1000)) AS breadcrumb_path,
        1 AS tree_depth
    FROM `categories` c
    WHERE c.parent_id IS NULL AND c.is_active = 1

    UNION ALL

    -- Recursive Member: Subcategories
    SELECT 
        sub.id,
        sub.parent_id,
        sub.name,
        sub.slug,
        CONCAT(parent.breadcrumb_path, ' > ', sub.name),
        parent.tree_depth + 1
    FROM `categories` sub
    INNER JOIN category_tree parent ON sub.parent_id = parent.id
    WHERE sub.is_active = 1
)
SELECT 
    id,
    tree_depth,
    breadcrumb_path,
    slug
FROM category_tree
ORDER BY breadcrumb_path;
```

---

### 5. MySQL 8.0 JSON Manipulation & `JSON_TABLE` Shredding

MySQL 8.0 provides native binary JSON document storage (`JSON` data type) and functions to index, filter, and normalize semi-structured attributes directly into relational projections.

#### 5.1 Operators and Extraction
* `JSON_EXTRACT(doc, path)` or `doc->path`: Returns JSON-formatted scalar or object.
* `doc->>path`: Unquoted extraction (equivalent to `JSON_UNQUOTE(JSON_EXTRACT(doc, path))`).

#### 5.2 Relational Shredding with `JSON_TABLE`
The `JSON_TABLE()` function transforms semi-structured JSON arrays into relational rows that can be joined, grouped, and filtered using standard SQL:

```sql
SELECT 
    p.id AS product_id,
    p.title,
    jt.software_name,
    jt.min_version,
    jt.file_extension
FROM `products` p,
JSON_TABLE(
    p.design_metadata,
    '$.software_compatibility[*]' COLUMNS (
        software_name VARCHAR(80) PATH '$.software',
        min_version VARCHAR(30) PATH '$.min_version',
        file_extension VARCHAR(10) PATH '$.extension'
    )
) AS jt
WHERE p.status = 'published';
```
