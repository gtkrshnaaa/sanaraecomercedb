-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 04: Product Variants, Deliverable File Assets, Licenses, and Pricing Matrix
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `product_bundle_items`;
DROP TABLE IF EXISTS `product_pricing_matrix`;
DROP TABLE IF EXISTS `product_variants`;
DROP TABLE IF EXISTS `licenses`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Licensing Model Master
CREATE TABLE `licenses` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(40) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `default_price_multiplier` DECIMAL(5, 2) NOT NULL DEFAULT 1.00,
    `max_seats` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1 = Single user, 0 = Unlimited enterprise',
    `max_print_impressions` BIGINT UNSIGNED NOT NULL DEFAULT 5000 COMMENT '0 = Unlimited run',
    `merchandise_allowed` TINYINT(1) NOT NULL DEFAULT 0,
    `broadcast_tv_allowed` TINYINT(1) NOT NULL DEFAULT 0,
    `resale_prohibited` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `display_order` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_license_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Product Deliverable Variants & Source Archives
CREATE TABLE `product_variants` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `software_id` SMALLINT UNSIGNED NULL,
    `name` VARCHAR(150) NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `file_format` ENUM('ai', 'psd', 'fig', 'eps', 'blend', 'c4d', 'indd', 'pdf', 'svg', 'zip', 'cdr') NOT NULL,
    `file_size_bytes` BIGINT UNSIGNED NOT NULL,
    `archive_checksum_sha256` CHAR(64) NOT NULL,
    `storage_s3_key` VARCHAR(300) NOT NULL,
    `storage_bucket` VARCHAR(100) NOT NULL DEFAULT 'sanara-assets-vault-prod',
    `is_primary_deliverable` TINYINT(1) NOT NULL DEFAULT 0,
    `version_label` VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_variant_uuid` (`uuid`),
    UNIQUE KEY `uq_variant_sku` (`sku`),
    INDEX `idx_variant_product` (`product_id`, `is_primary_deliverable`),
    INDEX `idx_variant_format` (`file_format`),
    CONSTRAINT `fk_variant_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_variant_software` FOREIGN KEY (`software_id`) REFERENCES `software_ecosystems` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Multi-Tier License Pricing Matrix
CREATE TABLE `product_pricing_matrix` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `license_id` SMALLINT UNSIGNED NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'USD',
    `price` DECIMAL(10, 2) NOT NULL,
    `sale_price` DECIMAL(10, 2) NULL,
    `sale_starts_at` TIMESTAMP NULL DEFAULT NULL,
    `sale_ends_at` TIMESTAMP NULL DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `effective_price` DECIMAL(10, 2) GENERATED ALWAYS AS (
        LEAST(COALESCE(`sale_price`, `price`), `price`)
    ) STORED,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_product_license_curr` (`product_id`, `license_id`, `currency`),
    INDEX `idx_pricing_lookup` (`product_id`, `is_active`, `price`),
    INDEX `idx_pricing_license` (`license_id`),
    CONSTRAINT `chk_pricing_positive` CHECK (`price` >= 0.00),
    CONSTRAINT `fk_pricing_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pricing_license` FOREIGN KEY (`license_id`) REFERENCES `licenses` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Product Bundle Composition
CREATE TABLE `product_bundle_items` (
    `bundle_product_id` BIGINT UNSIGNED NOT NULL,
    `included_product_id` BIGINT UNSIGNED NOT NULL,
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`bundle_product_id`, `included_product_id`),
    CONSTRAINT `fk_bundle_parent` FOREIGN KEY (`bundle_product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bundle_child` FOREIGN KEY (`included_product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
