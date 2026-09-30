-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 10: Stored Procedures & Functions (ACID Checkouts, Tokens, Payouts)
-- Principles: Explicit Transaction Boundaries, Error Handlers, Atomic Invariants
-- ==============================================================================

USE `sanara_ecommerce`;

DROP FUNCTION IF EXISTS `fn_calculate_commission_fee`;
DROP FUNCTION IF EXISTS `fn_generate_license_key`;
DROP FUNCTION IF EXISTS `fn_format_bytes`;

DROP PROCEDURE IF EXISTS `sp_checkout_order`;
DROP PROCEDURE IF EXISTS `sp_generate_secure_download_token`;
DROP PROCEDURE IF EXISTS `sp_consume_download_token`;
DROP PROCEDURE IF EXISTS `sp_request_creator_payout`;

DELIMITER $$

-- 1. Helper Function: Calculate Platform Fee
CREATE FUNCTION `fn_calculate_commission_fee`(
    p_creator_id BIGINT UNSIGNED,
    p_gross_amount DECIMAL(10, 2)
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_creator_rate DECIMAL(5, 2) DEFAULT 80.00;
    DECLARE v_platform_fee DECIMAL(10, 2) DEFAULT 0.00;

    SELECT `commission_rate` INTO v_creator_rate
    FROM `creator_profiles`
    WHERE `id` = p_creator_id
    LIMIT 1;

    -- Platform fee is the remaining percentage (e.g. 100 - 80% = 20%)
    SET v_platform_fee = ROUND(p_gross_amount * ((100.00 - v_creator_rate) / 100.00), 2);
    RETURN v_platform_fee;
END$$

-- 2. Helper Function: Generate Formatted License Grant Key
CREATE FUNCTION `fn_generate_license_key`() 
RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
    DECLARE v_raw CHAR(32);
    SET v_raw = UPPER(REPLACE(UUID(), '-', ''));
    RETURN CONCAT(
        'SANARA-',
        SUBSTRING(v_raw, 1, 4), '-',
        SUBSTRING(v_raw, 5, 4), '-',
        SUBSTRING(v_raw, 9, 4), '-',
        SUBSTRING(v_raw, 13, 4)
    );
END$$

-- 3. Helper Function: Format Raw Bytes into Human-Readable String
CREATE FUNCTION `fn_format_bytes`(p_bytes BIGINT UNSIGNED) 
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    IF p_bytes IS NULL THEN
        RETURN '0 B';
    ELSEIF p_bytes < 1024 THEN
        RETURN CONCAT(p_bytes, ' B');
    ELSEIF p_bytes < 1048576 THEN
        RETURN CONCAT(ROUND(p_bytes / 1024.0, 1), ' KB');
    ELSEIF p_bytes < 1073741824 THEN
        RETURN CONCAT(ROUND(p_bytes / 1048576.0, 1), ' MB');
    ELSE
        RETURN CONCAT(ROUND(p_bytes / 1073741824.0, 2), ' GB');
    END IF;
END$$

-- 4. ACID Transaction Stored Procedure: Complete Checkout Workflow
CREATE PROCEDURE `sp_checkout_order`(
    IN p_buyer_id BIGINT UNSIGNED,
    IN p_currency CHAR(3),
    IN p_payment_method VARCHAR(30),
    IN p_payment_ref VARCHAR(150),
    IN p_items_json JSON,
    OUT p_order_id BIGINT UNSIGNED,
    OUT p_order_number VARCHAR(32)
)
proc_body: BEGIN
    DECLARE v_subtotal DECIMAL(12, 2) DEFAULT 0.00;
    DECLARE v_total DECIMAL(12, 2) DEFAULT 0.00;
    DECLARE v_order_uuid CHAR(36);
    DECLARE v_item_count INT;
    DECLARE i INT DEFAULT 0;
    
    DECLARE v_product_id BIGINT UNSIGNED;
    DECLARE v_variant_id BIGINT UNSIGNED;
    DECLARE v_license_id SMALLINT UNSIGNED;
    DECLARE v_creator_id BIGINT UNSIGNED;
    DECLARE v_unit_price DECIMAL(10, 2);
    DECLARE v_creator_rate DECIMAL(5, 2);
    DECLARE v_platform_fee DECIMAL(10, 2);
    DECLARE v_creator_royalty DECIMAL(10, 2);
    DECLARE v_grant_key VARCHAR(64);
    DECLARE v_order_item_id BIGINT UNSIGNED;
    DECLARE v_order_created_at DATETIME;

    -- Error Handler for Rolling Back on Exceptions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_order_uuid = UUID();
    SET v_order_created_at = NOW();
    SET v_item_count = JSON_LENGTH(p_items_json);

    IF v_item_count = 0 OR v_item_count IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Checkout failed: items JSON cannot be empty';
    END IF;

    -- Generate human-friendly order reference: e.g. ORD-2026-XXXXXX
    SET p_order_number = CONCAT('ORD-', YEAR(NOW()), '-', UPPER(SUBSTRING(REPLACE(UUID(), '-', ''), 1, 8)));

    START TRANSACTION;

    -- Calculate total by iterating item array
    WHILE i < v_item_count DO
        SET v_variant_id = CAST(JSON_EXTRACT(p_items_json, CONCAT('$[', i, '].variant_id')) AS UNSIGNED);
        SET v_license_id = CAST(JSON_EXTRACT(p_items_json, CONCAT('$[', i, '].license_id')) AS UNSIGNED);

        SELECT pv.`product_id`, p.`creator_id`, ppm.`effective_price`
        INTO v_product_id, v_creator_id, v_unit_price
        FROM `product_variants` pv
        JOIN `products` p ON p.`id` = pv.`product_id`
        JOIN `product_pricing_matrix` ppm ON ppm.`product_id` = p.`id` 
             AND ppm.`license_id` = v_license_id 
             AND ppm.`is_active` = 1
        WHERE pv.`id` = v_variant_id
        LIMIT 1;

        IF v_unit_price IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Pricing matrix not found for selected variant and license';
        END IF;

        SET v_subtotal = v_subtotal + v_unit_price;
        SET i = i + 1;
    END WHILE;

    SET v_total = v_subtotal;

    -- Insert Parent Order
    INSERT INTO `orders` (
        `uuid`, `order_number`, `buyer_id`, `currency`, `subtotal_amount`,
        `discount_amount`, `tax_amount`, `total_amount`, `status`,
        `payment_method`, `payment_reference_id`, `paid_at`, `created_at`
    ) VALUES (
        v_order_uuid, p_order_number, p_buyer_id, p_currency, v_subtotal,
        0.00, 0.00, v_total, 'completed',
        p_payment_method, p_payment_ref, NOW(), v_order_created_at
    );

    SET p_order_id = LAST_INSERT_ID();

    -- Insert Line Items & Create Entitlements
    SET i = 0;
    WHILE i < v_item_count DO
        SET v_variant_id = CAST(JSON_EXTRACT(p_items_json, CONCAT('$[', i, '].variant_id')) AS UNSIGNED);
        SET v_license_id = CAST(JSON_EXTRACT(p_items_json, CONCAT('$[', i, '].license_id')) AS UNSIGNED);

        SELECT pv.`product_id`, p.`creator_id`, cp.`commission_rate`, ppm.`effective_price`
        INTO v_product_id, v_creator_id, v_creator_rate, v_unit_price
        FROM `product_variants` pv
        JOIN `products` p ON p.`id` = pv.`product_id`
        JOIN `creator_profiles` cp ON cp.`id` = p.`creator_id`
        JOIN `product_pricing_matrix` ppm ON ppm.`product_id` = p.`id` 
             AND ppm.`license_id` = v_license_id 
             AND ppm.`is_active` = 1
        WHERE pv.`id` = v_variant_id
        LIMIT 1;

        SET v_platform_fee = ROUND(v_unit_price * ((100.00 - v_creator_rate) / 100.00), 2);
        SET v_creator_royalty = v_unit_price - v_platform_fee;
        SET v_grant_key = fn_generate_license_key();

        INSERT INTO `order_items` (
            `order_id`, `order_created_at`, `product_id`, `variant_id`, `license_id`,
            `creator_id`, `unit_price`, `creator_royalty_percentage`,
            `creator_royalty_amount`, `platform_fee_amount`, `license_grant_key`, `status`
        ) VALUES (
            p_order_id, v_order_created_at, v_product_id, v_variant_id, v_license_id,
            v_creator_id, v_unit_price, v_creator_rate,
            v_creator_royalty, v_platform_fee, v_grant_key, 'active'
        );

        SET v_order_item_id = LAST_INSERT_ID();

        -- Create Digital Asset Customer Entitlement
        INSERT INTO `customer_entitlements` (
            `uuid`, `buyer_id`, `product_id`, `variant_id`, `license_id`,
            `order_item_id`, `license_grant_key`, `entitlement_status`
        ) VALUES (
            UUID(), p_buyer_id, v_product_id, v_variant_id, v_license_id,
            v_order_item_id, v_grant_key, 'active'
        );

        SET i = i + 1;
    END WHILE;

    COMMIT;
END$$

-- 5. Stored Procedure: Generate Ephemeral Download Token
CREATE PROCEDURE `sp_generate_secure_download_token`(
    IN p_buyer_id BIGINT UNSIGNED,
    IN p_variant_id BIGINT UNSIGNED,
    IN p_ip_address VARCHAR(45),
    IN p_ttl_hours INT,
    OUT p_raw_token VARCHAR(64),
    OUT p_expires_at TIMESTAMP
)
BEGIN
    DECLARE v_entitlement_id BIGINT UNSIGNED;
    DECLARE v_token_hash CHAR(64);

    -- Verify active entitlement exists
    SELECT `id` INTO v_entitlement_id
    FROM `customer_entitlements`
    WHERE `buyer_id` = p_buyer_id 
      AND `variant_id` = p_variant_id 
      AND `entitlement_status` = 'active'
    LIMIT 1;

    IF v_entitlement_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access Denied: No active entitlement for requested asset';
    END IF;

    SET p_raw_token = SHA2(CONCAT(UUID(), RAND(), NOW()), 256);
    SET v_token_hash = SHA2(p_raw_token, 256);
    SET p_expires_at = TIMESTAMPADD(HOUR, COALESCE(p_ttl_hours, 24), CURRENT_TIMESTAMP);

    INSERT INTO `secure_download_tokens` (
        `token_hash`, `entitlement_id`, `variant_id`, `requested_by_user_id`,
        `bound_ip_address`, `max_allowed_downloads`, `download_count`,
        `is_revoked`, `expires_at`
    ) VALUES (
        v_token_hash, v_entitlement_id, p_variant_id, p_buyer_id,
        p_ip_address, 5, 0, 0, p_expires_at
    );
END$$

-- 6. Stored Procedure: Request Creator Royalty Payout
CREATE PROCEDURE `sp_request_creator_payout`(
    IN p_creator_id BIGINT UNSIGNED,
    IN p_amount DECIMAL(12, 2),
    IN p_payout_method VARCHAR(20),
    IN p_destination_metadata JSON,
    OUT p_payout_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_wallet_id BIGINT UNSIGNED;
    DECLARE v_avail DECIMAL(12, 2);
    DECLARE v_is_blocked TINYINT(1);
    DECLARE v_payout_uuid CHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Lock wallet row with pessimistic lock
    SELECT `id`, `available_balance`, `is_payout_blocked`
    INTO v_wallet_id, v_avail, v_is_blocked
    FROM `creator_wallets`
    WHERE `creator_id` = p_creator_id AND `currency` = 'USD'
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Creator wallet not found';
    END IF;

    IF v_is_blocked = 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payout blocked due to account compliance review';
    END IF;

    IF v_avail < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient available wallet balance for requested payout';
    END IF;

    SET v_payout_uuid = UUID();

    -- Insert payout record
    INSERT INTO `payout_requests` (
        `uuid`, `creator_id`, `amount`, `currency`, `payout_method`,
        `destination_account_metadata`, `status`
    ) VALUES (
        v_payout_uuid, p_creator_id, p_amount, 'USD', p_payout_method,
        p_destination_metadata, 'pending_approval'
    );

    SET p_payout_id = LAST_INSERT_ID();

    -- Deduct available balance
    UPDATE `creator_wallets`
    SET `available_balance` = `available_balance` - p_amount
    WHERE `id` = v_wallet_id;

    -- Record double-entry financial ledger debit
    INSERT INTO `wallet_ledger_entries` (
        `wallet_id`, `creator_id`, `entry_type`, `direction`,
        `amount`, `balance_before`, `balance_after`, `payout_request_id`,
        `reference_note`
    ) VALUES (
        v_wallet_id, p_creator_id, 'payout_withdrawal', 'debit',
        p_amount, v_avail, v_avail - p_amount, p_payout_id,
        CONCAT('Pending payout withdrawal request #', p_payout_id)
    );

    COMMIT;
END$$

DELIMITER ;
