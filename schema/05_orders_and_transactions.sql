-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 05: Orders, Items, Coupons, Transactions, and Range Partitioning
-- Features: RANGE Partitioning on Orders by Year for High-Volume Archival
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `payment_transactions`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
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

-- 2. Orders Table (Partitioned by Year for Enterprise Scalability)
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

-- 3. Order Items & Line-Item Royalties
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

-- 4. Payment Gateway Webhook Audit & Transactions
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
