-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 14: Semantic Asset Revisions, Catalog i18n, AML/KYC & Coupon Redemptions
-- Features: Semver Version Control, Multi-Language Full-Text, Compliance Holds
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `coupon_redemption_history`;
DROP TABLE IF EXISTS `creator_kyc_compliance`;
DROP TABLE IF EXISTS `product_translations_i18n`;
DROP TABLE IF EXISTS `product_asset_revisions`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Semantic Asset Versioning & Revision Lifecycle
CREATE TABLE `product_asset_revisions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `semver_major` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `semver_minor` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `semver_patch` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `version_string` VARCHAR(20) GENERATED ALWAYS AS (
        CONCAT(`semver_major`, '.', `semver_minor`, '.', `semver_patch`)
    ) STORED,
    `release_title` VARCHAR(150) NOT NULL,
    `changelog_markdown` TEXT NOT NULL,
    `archive_sha256` CHAR(64) NOT NULL,
    `file_size_bytes` BIGINT UNSIGNED NOT NULL,
    `storage_path` VARCHAR(255) NOT NULL,
    `is_breaking_change` TINYINT(1) NOT NULL DEFAULT 0,
    `is_deprecated` TINYINT(1) NOT NULL DEFAULT 0,
    `released_by_creator_id` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_prod_variant_semver` (`variant_id`, `semver_major`, `semver_minor`, `semver_patch`),
    INDEX `idx_revisions_product` (`product_id`),
    INDEX `idx_revisions_semver` (`version_string`),
    CONSTRAINT `fk_par_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_par_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_par_creator` FOREIGN KEY (`released_by_creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Multi-Language Catalog Localization & Natural Language Indexing
CREATE TABLE `product_translations_i18n` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `locale_code` VARCHAR(10) NOT NULL COMMENT 'ISO locale e.g. id_ID, ja_JP, de_DE, en_US',
    `localized_title` VARCHAR(200) NOT NULL,
    `localized_subtitle` VARCHAR(255) NULL,
    `localized_description` LONGTEXT NOT NULL,
    `is_approved_translation` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_prod_locale` (`product_id`, `locale_code`),
    INDEX `idx_trans_locale` (`locale_code`),
    FULLTEXT KEY `idx_fts_trans` (`localized_title`, `localized_subtitle`, `localized_description`),
    CONSTRAINT `fk_trans_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Creator AML / KYC Financial Compliance & Vetting Registry
CREATE TABLE `creator_kyc_compliance` (
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `tax_id_hash` VARCHAR(128) NOT NULL COMMENT 'SHA-256 hashed tax identification number',
    `vat_number` VARCHAR(50) NULL,
    `legal_entity_name` VARCHAR(180) NOT NULL,
    `residence_country_iso` CHAR(2) NOT NULL,
    `compliance_status` ENUM('pending_review', 'verified_approved', 'w8_ben_submitted', 'rejected_sanctioned') NOT NULL DEFAULT 'pending_review',
    `aml_risk_score` TINYINT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'Risk scale 0 to 100, scores above 75 trigger payout holds',
    `payout_currency_code` CHAR(3) NOT NULL DEFAULT 'USD',
    `reviewed_by_admin_id` BIGINT UNSIGNED NULL,
    `verified_at` TIMESTAMP NULL DEFAULT NULL,
    `last_screened_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`creator_id`),
    INDEX `idx_kyc_status` (`compliance_status`, `aml_risk_score`),
    CONSTRAINT `chk_aml_range` CHECK (`aml_risk_score` <= 100),
    CONSTRAINT `fk_kyc_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_kyc_admin` FOREIGN KEY (`reviewed_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Coupon Redemption Audit & Fraud Prevention History
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
