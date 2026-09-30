-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 06: Digital Asset Delivery, Entitlements, Secure Tokens & Partitioned Logs
-- Features: Ephemeral Download Tokens with Rate-Limiting & Partitioned Telemetry
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `download_logs`;
DROP TABLE IF EXISTS `secure_download_tokens`;
DROP TABLE IF EXISTS `customer_entitlements`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Customer Digital Asset Entitlements (License Ownership Record)
CREATE TABLE `customer_entitlements` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `buyer_id` BIGINT UNSIGNED NOT NULL,
    `agency_team_id` BIGINT UNSIGNED NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `license_id` SMALLINT UNSIGNED NOT NULL,
    `order_item_id` BIGINT UNSIGNED NOT NULL,
    `license_grant_key` VARCHAR(64) NOT NULL,
    `entitlement_status` ENUM('active', 'suspended', 'revoked', 'expired') NOT NULL DEFAULT 'active',
    `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL DEFAULT NULL COMMENT 'NULL for perpetual licenses, specific timestamp for subscriptions',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_entitlement_uuid` (`uuid`),
    UNIQUE KEY `uq_entitlement_grant` (`license_grant_key`),
    INDEX `idx_entitlement_buyer_prod` (`buyer_id`, `product_id`, `entitlement_status`),
    INDEX `idx_entitlement_team` (`agency_team_id`),
    CONSTRAINT `fk_entitle_buyer` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_entitle_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_entitle_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_entitle_license` FOREIGN KEY (`license_id`) REFERENCES `licenses` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_entitle_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Secure Ephemeral Download Tokens (Anti-Leech & Expiring Links)
CREATE TABLE `secure_download_tokens` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `token_hash` CHAR(64) NOT NULL COMMENT 'SHA-256 hash of secure raw token sent to client',
    `entitlement_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `requested_by_user_id` BIGINT UNSIGNED NOT NULL,
    `bound_ip_address` VARCHAR(45) NOT NULL,
    `max_allowed_downloads` TINYINT UNSIGNED NOT NULL DEFAULT 5,
    `download_count` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_revoked` TINYINT(1) NOT NULL DEFAULT 0,
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_token_hash` (`token_hash`),
    INDEX `idx_token_lookup` (`token_hash`, `is_revoked`, `expires_at`),
    INDEX `idx_token_entitlement` (`entitlement_id`),
    CONSTRAINT `fk_token_entitlement` FOREIGN KEY (`entitlement_id`) REFERENCES `customer_entitlements` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_token_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_token_user` FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. High-Frequency Download Telemetry & Access Audit (Partitioned by Year)
CREATE TABLE `download_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `download_token_id` BIGINT UNSIGNED NULL,
    `entitlement_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `client_ip` VARCHAR(45) NOT NULL,
    `country_iso` CHAR(2) NOT NULL DEFAULT 'XX',
    `user_agent` VARCHAR(500) NULL,
    `bytes_delivered` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `http_status_code` SMALLINT UNSIGNED NOT NULL DEFAULT 200,
    `delivery_duration_ms` INT UNSIGNED NOT NULL DEFAULT 0,
    `delivery_status` ENUM('completed', 'interrupted', 'expired_token', 'ip_mismatch', 'quota_exceeded') NOT NULL,
    `requested_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`, `requested_at`),
    INDEX `idx_dlog_user_date` (`user_id`, `requested_at`),
    INDEX `idx_dlog_variant` (`variant_id`),
    INDEX `idx_dlog_status` (`delivery_status`),
    INDEX `idx_dlog_client_ip` (`client_ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
PARTITION BY RANGE (YEAR(`requested_at`)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p2027 VALUES LESS THAN (2028),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
