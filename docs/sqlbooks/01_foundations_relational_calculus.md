# Volume 1: Relational Calculus & DDL Architecture
## Theoretical Foundations, Relational Normalization, and Production DDL Design

### 1. Mathematical Foundations of Relational Systems

A relational database management system (RDBMS) is fundamentally an implementation of E.F. Codd's Relational Model (1970), which is rooted in first-order predicate logic and mathematical set theory.

#### 1.1 Relations and Tuples as Mathematical Sets
* **Relation ($R$)**: A relation corresponds to a table. Formally, given $n$ domains $D_1, D_2, \dots, D_n$, a relation $R$ is a subset of the Cartesian product $D_1 \times D_2 \times \dots \times D_n$.
* **Tuple ($t$)**: A tuple corresponds to an individual row in a table. It is an ordered set of attribute-value pairs $(a_1: v_1, a_2: v_2, \dots, a_n: v_n)$ where $v_i \in D_i$.
* **Attribute ($A$)**: An attribute represents a named column associated with a specific data domain $D$.
* **Set Semantics vs Bag Semantics**: Pure relational algebra operates on sets (unordered, strictly distinct tuples). SQL in practice operates on multisets (bags), allowing duplicates unless constrained by a `PRIMARY KEY` or `UNIQUE` constraint.

#### 1.2 Relational Algebra Operators
Relational algebra consists of fundamental unary and binary operators that produce new relations:
1. **Selection ($\sigma_{\text{predicate}}(R)$)**: Filters tuples that satisfy a boolean predicate. Mapped in SQL to the `WHERE` clause.
2. **Projection ($\pi_{A_1, A_2, \dots, A_k}(R)$)**: Extracts specified attribute columns while discarding others. Mapped in SQL to the `SELECT` column list.
3. **Cartesian Product ($R \times S$)**: Combines every tuple of relation $R$ with every tuple of relation $S$. Mapped in SQL to `CROSS JOIN`.
4. **Natural Join ($R \bowtie S$)**: Combines tuples from $R$ and $S$ where shared attribute names have identical values, projecting common attributes once.
5. **Set Union ($R \cup S$)**, **Set Difference ($R - S$)**, and **Set Intersection ($R \cap S$)**: Mapped to `UNION [DISTINCT]`, `EXCEPT [DISTINCT]`, and `INTERSECT [DISTINCT]`.

---

### 2. Relational Normalization Engineering

Normalization is the systematic decomposition of relations to eliminate insertion, update, and deletion anomalies while minimizing structural data redundancy without information loss.

#### 2.1 First Normal Form (1NF)
A relation is in 1NF if and only if:
1. Every attribute value is atomic (indivisible single value from the domain).
2. There are no repeating groups or multi-valued arrays in a single column.
3. Each record is uniquely identifiable by a candidate key.

*Anti-Pattern (Violating 1NF)*:
```sql
-- VIOLATION: Comma-separated list in a scalar column
CREATE TABLE orders_bad (
    order_id INT,
    product_ids VARCHAR(255) -- '1,4,7,12' (Requires regex or string splitting)
);
```

*Correct 1NF Architecture*:
```sql
CREATE TABLE order_items_1nf (
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

#### 2.2 Second Normal Form (2NF)
A relation is in 2NF if:
1. It is in 1NF.
2. Every non-prime attribute is fully functionally dependent on the entire primary key, not a proper subset of a composite primary key.

*Anti-Pattern (Violating 2NF)*:
```sql
-- Composite Key: (order_id, product_id)
CREATE TABLE order_line_items_bad (
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT NOT NULL,
    product_title VARCHAR(200) NOT NULL, -- Depends ONLY on product_id, not order_id!
    PRIMARY KEY (order_id, product_id)
);
```

*Decomposition into 2NF*:
* `products`: `(product_id [PK], product_title, ...)`
* `order_line_items`: `(order_id, product_id, quantity) [PK: (order_id, product_id)]`

#### 2.3 Third Normal Form (3NF)
A relation is in 3NF if:
1. It is in 2NF.
2. No non-prime attribute is transitively dependent on the primary key ($X \to Y \to Z$ where $Z$ depends on $Y$, which depends on the candidate key $X$).

*Anti-Pattern (Violating 3NF)*:
```sql
CREATE TABLE creator_profiles_bad (
    creator_id BIGINT UNSIGNED PRIMARY KEY,
    studio_name VARCHAR(150),
    country_iso CHAR(2),
    country_name VARCHAR(100), -- Transitive: creator_id -> country_iso -> country_name
    currency_code CHAR(3)      -- Transitive: creator_id -> country_iso -> currency_code
);
```

*Decomposition into 3NF*:
* `countries`: `(country_iso [PK], country_name, default_currency)`
* `creator_profiles`: `(creator_id [PK], studio_name, country_iso [FK])`

#### 2.4 Boyce-Codd Normal Form (BCNF)
A relation is in BCNF if for every functional dependency $X \to Y$, $X$ is a superkey. BCNF addresses overlapping composite candidate keys that can still retain subtle redundancies in 3NF.

#### 2.5 Controlled Denormalization
In high-throughput e-commerce systems, strict 3NF can result in excessive joins on hot analytical paths. Denormalization is acceptable only when:
1. The denormalized field is an immutable historical snapshot (e.g., storing `unit_price` at the moment of checkout on `order_items` rather than joining `products.base_standard_price`).
2. The value is a pure deterministic generated column calculated and indexed on write.

---

### 3. MySQL 8.0 Data Types & Storage Layout

Choosing precise data types minimizes on-disk footprint, maximizes memory density within the InnoDB Buffer Pool, and eliminates implicit conversion overhead during query filtering.

#### 3.1 Numeric Data Types
* `TINYINT` (1 byte, -128 to 127 or 0 to 255 unsigned). Ideal for boolean flags, status codes, small enum mappings.
* `SMALLINT` (2 bytes, 0 to 65,535 unsigned). Ideal for license types, software IDs, DPI resolutions.
* `MEDIUMINT` (3 bytes, 0 to 16,777,215 unsigned). Ideal for medium catalogs and ZIP code indexes.
* `INT` (4 bytes, 0 to 4.29 billion unsigned). Ideal for standard entity IDs.
* `BIGINT` (8 bytes, 0 to 18.44 quintillion unsigned). Mandatory for primary keys on ledger lines, orders, telemetry logs, and high-frequency transactions.
* `DECIMAL(M, D)`: Exact fixed-point numeric representation. Stored in binary chunks of 4 bytes per 9 decimal digits. Never use `FLOAT` or `DOUBLE` for financial, monetary, or accounting calculations due to IEEE 754 floating-point rounding errors.

#### 3.2 String & Character Types
* `CHAR(N)`: Fixed-length character string. If the stored string is shorter than $N$, it is right-padded with spaces. Recommended for fixed formats: UUIDs (`CHAR(36)`), SHA-256 hashes (`CHAR(64)`), ISO country codes (`CHAR(2)`), currency codes (`CHAR(3)`).
* `VARCHAR(N)`: Variable-length character string. Requires 1 extra byte for lengths up to 255 bytes, or 2 extra bytes for lengths exceeding 255 bytes.
* `utf8mb4` vs `utf8mb3`: Always specify `utf8mb4` with collation `utf8mb4_0900_ai_ci` (Unicode 9.0, accent-insensitive, case-insensitive) or `utf8mb4_bin` (binary sorting for exact case sensitivity).

#### 3.3 Temporal Data Types
| Feature | `DATETIME` | `TIMESTAMP` |
|---|---|---|
| Storage Size | 5 bytes (+ fractional seconds) | 4 bytes (+ fractional seconds) |
| Range | `1000-01-01 00:00:00` to `9999-12-31 23:59:59` | `1970-01-01 00:00:01` UTC to `2038-01-19 03:14:07` UTC |
| Timezone Behavior | Stores literal value as entered | Converts to UTC on storage, converts back to connection timezone on retrieval |
| Best Usage | Partitioned logs, historical contracts, long-lived dates | Audit timestamps (`created_at`, `updated_at`, session expiration) |

#### 3.4 Generated Columns (Virtual vs Stored)
MySQL 8.0 allows columns computed via deterministic expressions:
* `VIRTUAL`: Computed on-the-fly during read. Consumes zero disk storage. Can be indexed in InnoDB.
* `STORED`: Computed and written to disk upon `INSERT` or `UPDATE`. Consumes storage, but eliminates calculation overhead on read.

```sql
`effective_subtotal_idr` BIGINT UNSIGNED GENERATED ALWAYS AS (
    CAST(`unit_price_idr` * `quantity` AS UNSIGNED)
) STORED
```

---

### 4. DDL Syntax Mastery & Declarative Constraints

Declarative constraints protect database invariants at the storage engine level, preventing corrupt data states regardless of upstream application bugs.

#### 4.1 Constraint Types
1. `PRIMARY KEY`: Imposes both `NOT NULL` and `UNIQUE`. Defines the physical clustered index in InnoDB.
2. `FOREIGN KEY`: Enforces referential integrity.
   * `ON DELETE RESTRICT` (Default): Rejects deletion of parent row if child rows exist.
   * `ON DELETE CASCADE`: Automatically deletes dependent child rows.
   * `ON DELETE SET NULL`: Sets child foreign key column to NULL (column must allow NULL).
3. `UNIQUE KEY`: Guarantees attribute singularity across non-null values.
4. `CHECK`: Validates boolean condition expressions before commit.
   * Example: `CONSTRAINT chk_price_positive CHECK (price >= 0.00)`

#### 4.2 Online DDL Algorithms in MySQL 8.0
When executing `ALTER TABLE`:
* `ALGORITHM=INSTANT`: Modifies metadata only without rebuilding the table or blocking reads/writes. (Supported in MySQL 8.0 for adding columns at the end or renaming columns).
* `ALGORITHM=INPLACE`: Modifies table in-place without copying data to a temporary table; allows concurrent DML.
* `ALGORITHM=COPY`: Creates a full shadow copy of the table; blocks writes during execution.

---

### 5. Production Reference Architecture

The following DDL illustrates a fully constrained, 3NF-compliant relational subsystem with industrial print pre-flight checks, spot colors, and generated metrics:

```sql
USE `sanara_ecommerce`;

-- 1. Standardized Industrial Print Profiles (Lookup Master)
CREATE TABLE `print_production_profiles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `profile_name` VARCHAR(120) NOT NULL,
    `icc_profile_tag` VARCHAR(80) NOT NULL,
    `substrate_type` ENUM(
        'vinyl_frontlit_510gsm',
        'vinyl_backlit_650gsm',
        'mesh_banner_windproof',
        'art_carton_310gsm',
        'corrugated_b_flute'
    ) NOT NULL,
    `max_ink_density_tac` SMALLINT UNSIGNED NOT NULL DEFAULT 300,
    `screen_ruling_lpi` SMALLINT UNSIGNED NOT NULL DEFAULT 150,
    `recommended_viewing_distance_meters` DECIMAL(4, 2) NOT NULL DEFAULT 1.00,
    `supports_spot_varnish` TINYINT(1) NOT NULL DEFAULT 0,
    `supports_die_cut` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_profile_name` (`profile_name`),
    CONSTRAINT `chk_tac_limit` CHECK (`max_ink_density_tac` BETWEEN 100 AND 400)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Spot Color Finishing Plates (Composite Dependent Table)
CREATE TABLE `spot_color_plates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `pantone_code` VARCHAR(50) NOT NULL,
    `plate_name` VARCHAR(80) NOT NULL,
    `color_role` ENUM('primary_brand_spot', 'metallic_foil_stamping', 'emboss_deboss_die') NOT NULL,
    `cmyk_fallback_c` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_m` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_y` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_k` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_spot_product` (`product_id`),
    CONSTRAINT `chk_cmyk_c` CHECK (`cmyk_fallback_c` <= 100),
    CONSTRAINT `chk_cmyk_m` CHECK (`cmyk_fallback_m` <= 100),
    CONSTRAINT `chk_cmyk_y` CHECK (`cmyk_fallback_y` <= 100),
    CONSTRAINT `chk_cmyk_k` CHECK (`cmyk_fallback_k` <= 100),
    CONSTRAINT `fk_spot_product` FOREIGN KEY (`product_id`) 
        REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```
