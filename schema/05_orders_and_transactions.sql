-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 05: Orders, Items, Coupons, Transactions, and Range Partitioning
-- Features: RANGE Partitioning on Orders by Year for High-Volume Archival
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `order_refund_requests`;
DROP TABLE IF EXISTS `payment_transactions`;
DROP TABLE IF EXISTS `coupon_redemption_history`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `contract_asset_allocations`;
DROP TABLE IF EXISTS `enterprise_contracts`;
DROP TABLE IF EXISTS `collection_items`;
DROP TABLE IF EXISTS `collections`;
DROP TABLE IF EXISTS `coupons`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Promotional Discounts & Coupons
CREATE TABLE `coupons` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,
    `discount_type` ENUM('percentage', 'fixed_amount') NOT NULL,
    `discount_value` DECIMAL(10, 2) NOT NULL,
    `min_order_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `max_discount_amount` DECIMAL(10, 2) NULL,
    `total_usage_limit` INT UNSIGNED NULL,
    `current_usage_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `starts_at` TIMESTAMP NOT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_coupon_code` (`code`),
    INDEX `idx_coupon_window` (`is_active`, `starts_at`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Curated Collections & Campaign Design Bundles
CREATE TABLE `collections` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `curator_creator_id` BIGINT UNSIGNED NULL COMMENT 'NULL represents official Sanara Editorial curation',
    `title` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(170) NOT NULL,
    `campaign_theme` ENUM(
        'outdoor_transit_takeover',
        'fmcg_packaging_suite',
        '3d_metaverse_brand_world',
        'corporate_rebrand_bundle',
        'exhibition_event_graphics',
        'social_digital_blitz'
    ) NOT NULL,
    `description` TEXT NOT NULL,
    `bundle_discount_rate` DECIMAL(5, 2) NOT NULL DEFAULT 20.00 COMMENT 'Percentage off individual items e.g. 20.00%',
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_collection_uuid` (`uuid`),
    UNIQUE KEY `uq_collection_slug` (`slug`),
    INDEX `idx_coll_curator` (`curator_creator_id`),
    INDEX `idx_coll_theme_active` (`campaign_theme`, `is_active`),
    CONSTRAINT `chk_coll_discount` CHECK (`bundle_discount_rate` >= 0.00 AND `bundle_discount_rate` <= 90.00),
    CONSTRAINT `fk_collection_curator` FOREIGN KEY (`curator_creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Collection Items (Products within Bundles)
CREATE TABLE `collection_items` (
    `collection_id` BIGINT UNSIGNED NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_hero_asset` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`collection_id`, `product_id`),
    INDEX `idx_ci_product` (`product_id`),
    CONSTRAINT `fk_ci_collection` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ci_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Enterprise Agency Master Service Agreements (B2B Multi-Seat Contracts)
CREATE TABLE `enterprise_contracts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `agency_team_id` BIGINT UNSIGNED NOT NULL,
    `contract_number` VARCHAR(50) NOT NULL,
    `tier` ENUM('silver_agency', 'gold_network', 'platinum_conglomerate') NOT NULL,
    `monthly_flat_fee_usd` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `annual_minimum_guarantee_usd` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `per_asset_royalty_discount_pct` DECIMAL(5, 2) NOT NULL DEFAULT 15.00,
    `max_seats_licensed` SMALLINT UNSIGNED NOT NULL DEFAULT 10,
    `active_from` DATE NOT NULL,
    `active_until` DATE NOT NULL,
    `status` ENUM('draft', 'active', 'suspended', 'expired', 'terminated') NOT NULL DEFAULT 'draft',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_contract_uuid` (`uuid`),
    UNIQUE KEY `uq_contract_num` (`contract_number`),
    INDEX `idx_contract_agency` (`agency_team_id`, `status`),
    INDEX `idx_contract_dates` (`active_from`, `active_until`),
    CONSTRAINT `chk_contract_dates` CHECK (`active_until` >= `active_from`),
    CONSTRAINT `fk_contract_agency` FOREIGN KEY (`agency_team_id`) REFERENCES `agency_teams` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. Contract Asset Category Allocations & Quotas
CREATE TABLE `contract_asset_allocations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contract_id` BIGINT UNSIGNED NOT NULL,
    `category_id` INT UNSIGNED NOT NULL,
    `is_unlimited_cleared` TINYINT(1) NOT NULL DEFAULT 0,
    `monthly_download_quota` INT UNSIGNED NOT NULL DEFAULT 100,
    `current_cycle_consumed` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_contract_cat` (`contract_id`, `category_id`),
    INDEX `idx_caa_category` (`category_id`),
    CONSTRAINT `fk_caa_contract` FOREIGN KEY (`contract_id`) REFERENCES `enterprise_contracts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_caa_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. Orders Table (Partitioned by Year for Enterprise Scalability)
CREATE TABLE `orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `order_number` VARCHAR(32) NOT NULL,
    `buyer_id` BIGINT UNSIGNED NOT NULL,
    `agency_team_id` BIGINT UNSIGNED NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'USD',
    `subtotal_amount` DECIMAL(12, 2) NOT NULL,
    `discount_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `tax_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `total_amount` DECIMAL(12, 2) NOT NULL,
    `coupon_id` INT UNSIGNED NULL,
    `status` ENUM('pending_payment', 'processing', 'completed', 'failed', 'refunded', 'canceled') NOT NULL DEFAULT 'pending_payment',
    `payment_method` ENUM('stripe', 'paypal', 'midtrans', 'xendit', 'crypto', 'wallet_balance') NOT NULL,
    `payment_reference_id` VARCHAR(150) NULL,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`, `created_at`),
    INDEX `idx_orders_uuid` (`uuid`),
    INDEX `idx_orders_number` (`order_number`),
    INDEX `idx_orders_buyer` (`buyer_id`, `status`),
    INDEX `idx_orders_status_created` (`status`, `created_at`),
    INDEX `idx_orders_payment_ref` (`payment_reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
PARTITION BY RANGE (YEAR(`created_at`)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p2027 VALUES LESS THAN (2028),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 7. Order Items & Line-Item Royalties
CREATE TABLE `order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `order_created_at` TIMESTAMP NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `license_id` SMALLINT UNSIGNED NOT NULL,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `unit_price` DECIMAL(10, 2) NOT NULL,
    `creator_royalty_percentage` DECIMAL(5, 2) NOT NULL,
    `creator_royalty_amount` DECIMAL(10, 2) NOT NULL,
    `platform_fee_amount` DECIMAL(10, 2) NOT NULL,
    `license_grant_key` VARCHAR(64) NOT NULL,
    `status` ENUM('active', 'refunded', 'revoked') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_items_order` (`order_id`, `order_created_at`),
    INDEX `idx_items_creator` (`creator_id`, `status`),
    INDEX `idx_items_product` (`product_id`),
    INDEX `idx_items_grant_key` (`license_grant_key`),
    CONSTRAINT `fk_item_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_item_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_item_license` FOREIGN KEY (`license_id`) REFERENCES `licenses` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_item_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 8. Coupon Redemption Audit & Fraud Prevention History
CREATE TABLE `coupon_redemption_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `coupon_id` INT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `discount_captured_usd` DECIMAL(10, 2) NOT NULL,
    `redeemed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_crh_coupon` (`coupon_id`),
    INDEX `idx_crh_user_coupon` (`user_id`, `coupon_id`),
    INDEX `idx_crh_order` (`order_id`),
    CONSTRAINT `chk_discount_captured_pos` CHECK (`discount_captured_usd` >= 0.00),
    CONSTRAINT `fk_crh_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_crh_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 9. Payment Gateway Webhook Audit & Transactions
CREATE TABLE `payment_transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `order_id` BIGINT UNSIGNED NOT NULL,
    `gateway_name` ENUM('stripe', 'paypal', 'midtrans', 'xendit', 'coinbase') NOT NULL,
    `transaction_type` ENUM('charge', 'refund', 'chargeback') NOT NULL DEFAULT 'charge',
    `gateway_transaction_id` VARCHAR(150) NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    `currency` CHAR(3) NOT NULL,
    `gateway_fee_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `status` ENUM('pending', 'succeeded', 'failed', 'reversed') NOT NULL,
    `raw_payload` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_pay_gateway_id` (`gateway_name`, `gateway_transaction_id`),
    INDEX `idx_pay_order` (`order_id`),
    INDEX `idx_pay_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 10. Order Item Refund Requests & Clawback Disputes
CREATE TABLE `order_refund_requests` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `order_item_id` BIGINT UNSIGNED NOT NULL,
    `buyer_id` BIGINT UNSIGNED NOT NULL,
    `reason_code` ENUM(
        'corrupt_archive_unusable',
        'license_scope_misunderstanding',
        'unauthorized_account_charge',
        'intellectual_property_claim',
        'accidental_duplicate_purchase'
    ) NOT NULL,
    `customer_explanation` TEXT NOT NULL,
    `status` ENUM('submitted', 'under_review', 'approved_refunded', 'rejected') NOT NULL DEFAULT 'submitted',
    `approved_by_admin_id` BIGINT UNSIGNED NULL,
    `refund_amount` DECIMAL(10, 2) NOT NULL,
    `rejection_reason` VARCHAR(255) NULL,
    `submitted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `resolved_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_refund_uuid` (`uuid`),
    INDEX `idx_refund_order_item` (`order_item_id`),
    INDEX `idx_refund_buyer` (`buyer_id`, `status`),
    INDEX `idx_refund_status_date` (`status`, `submitted_at`),
    CONSTRAINT `chk_refund_positive` CHECK (`refund_amount` > 0.00),
    CONSTRAINT `fk_refund_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_refund_buyer` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_refund_admin` FOREIGN KEY (`approved_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

