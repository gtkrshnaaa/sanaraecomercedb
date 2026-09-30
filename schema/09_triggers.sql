-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 09: Business Logic Triggers (Real-Time Balances, Ratings, Telemetry)
-- ==============================================================================

USE `sanara_ecommerce`;

DROP TRIGGER IF EXISTS `trg_after_order_item_insert`;
DROP TRIGGER IF EXISTS `trg_after_review_insert`;
DROP TRIGGER IF EXISTS `trg_after_review_update`;
DROP TRIGGER IF EXISTS `trg_after_download_log_insert`;

DELIMITER $$

-- 1. Real-Time Creator Royalties, Escrow Ingestion, and Product Sales Counter
CREATE TRIGGER `trg_after_order_item_insert`
AFTER INSERT ON `order_items`
FOR EACH ROW
BEGIN
    DECLARE v_current_avail DECIMAL(12, 2) DEFAULT 0.00;
    DECLARE v_wallet_id BIGINT UNSIGNED;

    -- Update Product Sales Aggregate Counter
    UPDATE `products`
    SET `total_sales_count` = `total_sales_count` + 1
    WHERE `id` = NEW.`product_id`;

    -- Update Creator Profile High-Level Stats
    UPDATE `creator_profiles`
    SET `total_sales_count` = `total_sales_count` + 1,
        `total_revenue_usd` = `total_revenue_usd` + NEW.`creator_royalty_amount`
    WHERE `id` = NEW.`creator_id`;

    -- Fetch or Ensure Creator Wallet Exists
    SELECT `id`, `available_balance` INTO v_wallet_id, v_current_avail
    FROM `creator_wallets`
    WHERE `creator_id` = NEW.`creator_id` AND `currency` = 'USD'
    LIMIT 1;

    IF v_wallet_id IS NOT NULL THEN
        -- Add to Escrow Balance
        UPDATE `creator_wallets`
        SET `pending_escrow_balance` = `pending_escrow_balance` + NEW.`creator_royalty_amount`
        WHERE `id` = v_wallet_id;

        -- Record Immutable Accounting Ledger Entry
        INSERT INTO `wallet_ledger_entries` (
            `wallet_id`,
            `creator_id`,
            `entry_type`,
            `direction`,
            `amount`,
            `balance_before`,
            `balance_after`,
            `order_item_id`,
            `reference_note`
        ) VALUES (
            v_wallet_id,
            NEW.`creator_id`,
            'sale_royalty',
            'credit',
            NEW.`creator_royalty_amount`,
            v_current_avail,
            v_current_avail + NEW.`creator_royalty_amount`,
            NEW.`id`,
            CONCAT('Royalty earned from license grant key: ', NEW.`license_grant_key`)
        );
    END IF;
END$$

-- 2. Star Rating Recalculation on Review Submission
CREATE TRIGGER `trg_after_review_insert`
AFTER INSERT ON `product_reviews`
FOR EACH ROW
BEGIN
    DECLARE v_avg_product DECIMAL(3, 2);
    DECLARE v_count_product INT UNSIGNED;
    DECLARE v_creator_id BIGINT UNSIGNED;
    DECLARE v_avg_creator DECIMAL(3, 2);

    IF NEW.`status` = 'published' THEN
        -- Compute new product average rating
        SELECT ROUND(AVG(`rating`), 2), COUNT(`id`)
        INTO v_avg_product, v_count_product
        FROM `product_reviews`
        WHERE `product_id` = NEW.`product_id` AND `status` = 'published';

        UPDATE `products`
        SET `average_rating` = COALESCE(v_avg_product, 0.00),
            `review_count` = COALESCE(v_count_product, 0)
        WHERE `id` = NEW.`product_id`;

        -- Compute creator portfolio average rating
        SELECT `creator_id` INTO v_creator_id FROM `products` WHERE `id` = NEW.`product_id`;
        
        IF v_creator_id IS NOT NULL THEN
            SELECT ROUND(AVG(p.`average_rating`), 2)
            INTO v_avg_creator
            FROM `products` p
            WHERE p.`creator_id` = v_creator_id AND p.`review_count` > 0;

            UPDATE `creator_profiles`
            SET `average_rating` = COALESCE(v_avg_creator, 0.00)
            WHERE `id` = v_creator_id;
        END IF;
    END IF;
END$$

-- 3. Review Status Change or Rating Update
CREATE TRIGGER `trg_after_review_update`
AFTER UPDATE ON `product_reviews`
FOR EACH ROW
BEGIN
    DECLARE v_avg_product DECIMAL(3, 2);
    DECLARE v_count_product INT UNSIGNED;

    IF (OLD.`rating` != NEW.`rating`) OR (OLD.`status` != NEW.`status`) THEN
        SELECT ROUND(AVG(`rating`), 2), COUNT(`id`)
        INTO v_avg_product, v_count_product
        FROM `product_reviews`
        WHERE `product_id` = NEW.`product_id` AND `status` = 'published';

        UPDATE `products`
        SET `average_rating` = COALESCE(v_avg_product, 0.00),
            `review_count` = COALESCE(v_count_product, 0)
        WHERE `id` = NEW.`product_id`;
    END IF;
END$$

-- 4. Successful Download Telemetry Counter
CREATE TRIGGER `trg_after_download_log_insert`
AFTER INSERT ON `download_logs`
FOR EACH ROW
BEGIN
    DECLARE v_product_id BIGINT UNSIGNED;

    IF NEW.`delivery_status` = 'completed' THEN
        SELECT `product_id` INTO v_product_id 
        FROM `product_variants` 
        WHERE `id` = NEW.`variant_id`;

        IF v_product_id IS NOT NULL THEN
            UPDATE `products`
            SET `total_downloads_count` = `total_downloads_count` + 1
            WHERE `id` = v_product_id;
        END IF;
    END IF;
END$$

DELIMITER ;
