# The Sanara SQL & Database Systems Engineering Handbook
## Comprehensive Curriculum for Relational Algebra, MySQL 8.0 Internals, and CLI Administration

### Overview

This handbook is an authoritative, engineering-grade reference manual covering modern SQL design, relational calculus, query optimization, InnoDB storage engine internals, and native terminal database administration via the MySQL CLI.

All examples, queries, and system commands are verified against production MySQL 8.0 instances.

---

### Volumes Directory

| Volume | Title | Core Subject Matter |
|---|---|---|
| [Volume 1](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/01_foundations_relational_calculus.md) | Relational Calculus & DDL Architecture | Set theory, relational algebra, normal forms (1NF-BCNF), declarative constraints, data types, and InnoDB table storage. |
| [Volume 2](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/02_advanced_dml_and_query_mastery.md) | Advanced DML & Query Engineering | Window functions, Common Table Expressions (CTEs), recursive hierarchies, correlated subqueries, set operations, and JSON functions. |
| [Volume 3](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/03_mysql_cli_client_mastery.md) | Native MySQL CLI Client Operations | Command-line switches, client options, interactive shortcuts, custom pagers, batch execution, tee logging, vertical formatting, and prompt customization. |
| [Volume 4](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/04_indexing_execution_plans_and_optimization.md) | Indexing Engines, Query Execution & Profiling | B+Tree internals, covering indexes, composite leftmost prefix rule, full-text indexes, generated columns, and EXPLAIN ANALYZE cost-based optimization. |
| [Volume 5](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/05_transactions_concurrency_and_locking.md) | Transactions, Concurrency & Locking | ACID compliance, isolation levels (RU, RC, RR, Serial), MVCC undo logs, InnoDB lock types (Record, Gap, Next-Key), and deadlock graphs. |
| [Volume 6](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/06_programmable_sql_routines_and_triggers.md) | Programmable SQL Routines & Triggers | Stored procedures, user-defined functions, reactive triggers, cursors, error signaling (`SIGNAL SQLSTATE`), handlers, and definer security. |
| [Volume 7](file:///home/user/space/project/dbengineering/sanaraecomercedb/docs/sqlbooks/07_administration_replication_and_disaster_recovery.md) | Administration, Partitioning & Disaster Recovery | RANGE partitioning, table optimization, RBAC permission matrices, dual-password rotation, GTID binary replication, and Point-In-Time Recovery. |

---

### Pedagogical Methodology

1. **Declarative Grounding**: Concepts are introduced from formal relational calculus and mathematical set theory before mapping to ANSI/ISO SQL syntax.
2. **Engine Mechanical Sympathy**: Queries are analyzed not merely as text, but through how the MySQL InnoDB storage engine parses, optimizes, indexes, and fetches data from memory buffer pools and disk pages.
3. **Reproducible Production Code**: Every code block is syntactically valid and directly executable against the `sanara_ecommerce` schema or isolated self-contained tables.
4. **Zero Fluff**: Focus is strictly placed on high-density technical analysis, concrete CLI pipelines, performance implications, and failure mode diagnosis.
