# Volume 6: Programmable SQL Routines, Triggers, and Error Handling

## 1. Procedural SQL Architecture in MySQL 8.0

MySQL 8.0 executes stored programs (procedures, functions, and triggers) within the server subsystem using compiled execution trees managed directly by the transactional data dictionary. Unlike client-side scripted logic, procedural SQL runs adjacent to the storage engine, avoiding network round-trips for multi-step transactional operations.

### 1.1 Client Delimiter Reassignment

In the MySQL CLI client, the default query delimiter is the semicolon (`;`). Procedural SQL routines contain internal semicolons terminating individual statements within `BEGIN ... END` compound blocks. Before declaring a routine, the client delimiter must be reassigned to prevent premature transmission:

```sql
-- Reassign client delimiter to double slash
DELIMITER //

CREATE PROCEDURE sp_example()
BEGIN
    SELECT 1;
END //

-- Restore standard semicolon delimiter
DELIMITER ;
```

Failure to reassign the delimiter causes the client to split the definition at the first internal semicolon, resulting in syntax error 1064 (42000).

---

## 2. Stored Procedures vs. Stored Functions

| Capability | Stored Procedure (`PROCEDURE`) | Stored Function (`FUNCTION`) |
| :--- | :--- | :--- |
| Invocation | `CALL procedure_name(...)` | Embedded in SQL expressions (`SELECT func(...)`) |
| Return Value | Zero, one, or multiple result sets; `OUT`/`INOUT` params | Strictly returns a single scalar value via `RETURN` |
| Parameter Modes | `IN`, `OUT`, `INOUT` | Implicitly `IN` only |
| Transaction Control | Allows `START TRANSACTION`, `COMMIT`, `ROLLBACK` | Strictly prohibits explicit transaction statements |
| DML Restrictions | Can execute arbitrary DML and DDL | Prohibited from executing DML on tables read by calling query |

### 2.1 Deterministic State and Data Access Characteristics

MySQL 8.0 requires deterministic attributes for stored functions when binary logging is active (`log_bin = ON`). Functions must be annotated with one characteristic from each category:

* **Determinism**:
  * `DETERMINISTIC`: Returns identical results given identical inputs.
  * `NOT DETERMINISTIC`: Output may vary between calls with identical arguments (e.g., uses `NOW()`, `RAND()`, or unconstrained table queries).
* **Data Access**:
  * `CONTAINS SQL`: Routine contains SQL statements but does not read or write database tables.
  * `NO SQL`: Routine contains no SQL statements.
  * `READS SQL DATA`: Routine reads table data (`SELECT`) without modifying state.
  * `MODIFIES SQL DATA`: Routine executes mutating statements (`INSERT`, `UPDATE`, `DELETE`).

```sql
DELIMITER //

CREATE FUNCTION fn_calculate_creator_cut(
    p_amount_cents INT,
    p_commission_rate DECIMAL(5,4)
)
RETURNS INT
DETERMINISTIC
CONTAINS SQL
BEGIN
    DECLARE v_platform_cut INT;
    DECLARE v_creator_cut INT;

    SET v_platform_cut = ROUND(p_amount_cents * p_commission_rate);
    SET v_creator_cut  = p_amount_cents - v_platform_cut;

    RETURN v_creator_cut;
END //

DELIMITER ;
```

---

## 3. Control Flow Constructs and Cursor Lifecycle

Procedural blocks support structured control flow:

```sql
-- Conditional evaluation
IF v_status = 'pending' THEN
    UPDATE orders SET order_status = 'processing' WHERE order_id = p_order_id;
ELSEIF v_status = 'processing' THEN
    -- No-op
    LEAVE proc_block;
ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid order transition state';
END IF;
```

### 3.1 Loop Constructs: `LOOP`, `WHILE`, and `REPEAT`

```sql
-- WHILE loop: Evaluates condition before iteration
WHILE v_counter < 10 DO
    SET v_counter = v_counter + 1;
END WHILE;

-- REPEAT loop: Evaluates condition after iteration
REPEAT
    SET v_counter = v_counter + 1;
UNTIL v_counter >= 10
END REPEAT;

-- Unconditional labeled LOOP with LEAVE (break) and ITERATE (continue)
loop_label: LOOP
    SET v_counter = v_counter + 1;
    IF v_counter < 5 THEN
        ITERATE loop_label;
    END IF;
    IF v_counter >= 10 THEN
        LEAVE loop_label;
    END IF;
END LOOP loop_label;
```

### 3.2 Cursor Lifecycle Pattern

Cursors provide sequential, forward-only iteration over a query result set. Declaration order inside a compound block is mandatory:
1. Variable and condition declarations.
2. Cursor declarations.
3. Handler declarations.
4. Executable procedural logic.

```sql
DELIMITER //

CREATE PROCEDURE sp_reconcile_wallet_snapshots()
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_wallet_id BIGINT;
    DECLARE v_computed_balance BIGINT;

    -- 1. Declare Cursor
    DECLARE cur_wallets CURSOR FOR
        SELECT 
            w.wallet_id,
            COALESCE(SUM(l.credit_amount_cents - l.debit_amount_cents), 0) AS balance
        FROM creator_wallets w
        LEFT JOIN wallet_ledger_entries l ON w.wallet_id = l.wallet_id
        GROUP BY w.wallet_id;

    -- 2. Declare NOT FOUND Handler
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- 3. Open Cursor
    OPEN cur_wallets;

    reconcile_loop: LOOP
        -- 4. Fetch row into local variables
        FETCH cur_wallets INTO v_wallet_id, v_computed_balance;
        IF v_done = 1 THEN
            LEAVE reconcile_loop;
        END IF;

        -- Update snapshot if mismatch detected
        UPDATE creator_wallets
        SET available_balance_cents = v_computed_balance,
            updated_at = NOW()
        WHERE wallet_id = v_wallet_id
          AND available_balance_cents != v_computed_balance;
    END LOOP reconcile_loop;

    -- 5. Close Cursor
    CLOSE cur_wallets;
END //

DELIMITER ;
```

---

## 4. Exception Handling, Custom Conditions, and Diagnostics

MySQL provides ANSI SQL-compliant exception handling through `DECLARE HANDLER`, `SIGNAL`, and `GET DIAGNOSTICS`.

### 4.1 Signaling Custom Exceptions

The generic user-defined error condition uses SQLSTATE `'45000'`:

```sql
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Insufficient balance for requested withdrawal',
    MYSQL_ERRNO = 3001;
```

### 4.2 Robust Handler and Transaction Rollback Pattern

```sql
DELIMITER //

CREATE PROCEDURE sp_transfer_creator_funds(
    IN p_source_wallet_id BIGINT,
    IN p_target_wallet_id BIGINT,
    IN p_amount_cents BIGINT,
    IN p_reference_note VARCHAR(255)
)
BEGIN
    DECLARE v_source_balance BIGINT;
    DECLARE v_err_code INT DEFAULT 0;
    DECLARE v_err_msg VARCHAR(255) DEFAULT '';

    -- Exit handler catches all SQLEXCEPTION states
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_err_code = MYSQL_ERRNO,
            v_err_msg  = MESSAGE_TEXT;
        ROLLBACK;
        RESIGNAL SET MESSAGE_TEXT = v_err_msg;
    END;

    START TRANSACTION;

    -- Lock source wallet row
    SELECT available_balance_cents INTO v_source_balance
    FROM creator_wallets
    WHERE wallet_id = p_source_wallet_id
    FOR UPDATE;

    IF v_source_balance IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Source wallet not found', MYSQL_ERRNO = 3002;
    END IF;

    IF v_source_balance < p_amount_cents THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds in source wallet', MYSQL_ERRNO = 3003;
    END IF;

    -- Execute debit
    UPDATE creator_wallets
    SET available_balance_cents = available_balance_cents - p_amount_cents,
        updated_at = NOW()
    WHERE wallet_id = p_source_wallet_id;

    -- Execute credit
    UPDATE creator_wallets
    SET available_balance_cents = available_balance_cents + p_amount_cents,
        updated_at = NOW()
    WHERE wallet_id = p_target_wallet_id;

    -- Record double-entry ledgers
    INSERT INTO wallet_ledger_entries (
        wallet_id, entry_type, debit_amount_cents, credit_amount_cents, reference_type, description
    ) VALUES 
    (p_source_wallet_id, 'TRANSFER_OUT', p_amount_cents, 0, 'PEER_TRANSFER', p_reference_note),
    (p_target_wallet_id, 'TRANSFER_IN', 0, p_amount_cents, 'PEER_TRANSFER', p_reference_note);

    COMMIT;
END //

DELIMITER ;
```

---

## 5. Reactive Triggers

Triggers are event-driven procedural blocks attached to base tables, firing automatically during `INSERT`, `UPDATE`, or `DELETE` events.

### 5.1 Trigger Taxonomy and State Transitions

* **Timing**:
  * `BEFORE`: Fires prior to data validation and engine writes. Allows modifying incoming values in `NEW`.
  * `AFTER`: Fires after engine write succeeds. `NEW` and `OLD` are read-only; ideal for cascading audits and cross-table side effects.
* **Pseudorecords**:
  * `INSERT`: `NEW` contains inserted row; `OLD` is undefined.
  * `UPDATE`: `OLD` contains pre-mutation row; `NEW` contains pending mutation row.
  * `DELETE`: `OLD` contains deleted row; `NEW` is undefined.

### 5.2 Trigger Constraints

1. **No Explicit Transaction Control**: Triggers cannot execute `START TRANSACTION`, `COMMIT`, or `ROLLBACK`. They execute entirely within the calling statement's transactional envelope. If a trigger signals an error, the parent transaction rolls back.
2. **No Result Sets**: Triggers cannot return result sets to the client (prohibits naked `SELECT * FROM table;` queries).
3. **No Mutating Calling Table in AFTER Triggers**: Triggers cannot perform DML on the table on which they are defined (avoids infinite recursion).

### 5.3 Production Implementation: Immutable Audit Log Trigger

```sql
DELIMITER //

CREATE TRIGGER trg_products_audit_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    -- Only log when mutable operational state changes
    IF OLD.price_amount_cents != NEW.price_amount_cents 
       OR OLD.publication_status != NEW.publication_status THEN
        INSERT INTO product_audit_log (
            product_id,
            action_type,
            old_price_cents,
            new_price_cents,
            old_status,
            new_status,
            changed_by,
            changed_at
        ) VALUES (
            OLD.product_id,
            'UPDATE',
            OLD.price_amount_cents,
            NEW.price_amount_cents,
            OLD.publication_status,
            NEW.publication_status,
            CURRENT_USER(),
            NOW()
        );
    END IF;
END //

DELIMITER ;
```

### 5.4 Trigger Precedence (`PRECEDES` / `FOLLOWS`)

When multiple triggers exist for the same action and timing on a table, MySQL 8.0 allows explicit ordering:

```sql
CREATE TRIGGER trg_order_validate_promotions
BEFORE INSERT ON order_items
FOR EACH ROW
PRECEDES trg_order_compute_tax
BEGIN
    -- Execution occurs before tax computation trigger
    NULL;
END;
```

---

## 6. Definer vs. Invoker Security Models

Stored programs declare an execution privilege context via `SQL SECURITY`:

```sql
CREATE PROCEDURE sp_privileged_op()
SQL SECURITY DEFINER
BEGIN
    -- Runs with rights of the user defined in DEFINER = 'user'@'host'
END;

CREATE PROCEDURE sp_user_scoped_op()
SQL SECURITY INVOKER
BEGIN
    -- Runs with rights of the connecting client user
END;
```

### 6.1 Security Analysis

| Metric | `SQL SECURITY DEFINER` | `SQL SECURITY INVOKER` |
| :--- | :--- | :--- |
| Privilege Context | The account specified in `DEFINER` clause | The active session calling the routine |
| Escalation Risk | High. Definer bugs can allow unprivileged callers to bypass RBAC | Low. Caller cannot exceed their assigned table grants |
| Use Case | Controlled API gates (e.g. non-admin calling an internal ledger update) | Utility scripts, reporting procedures, or user-scoped queries |

To mitigate privilege escalation vulnerabilities on `SQL SECURITY DEFINER` routines:
1. Avoid wildcard hosts: Set `DEFINER = 'sanara_app'@'10.0.0.%'` instead of `'sanara_app'@'%'`.
2. Do not define routines under `root` unless explicitly necessary.
3. Grant `EXECUTE` only to explicit application service accounts.
