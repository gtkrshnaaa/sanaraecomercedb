-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 13: Bundles, Enterprise Contracts, Multi-Cloud Storage & Refund Governance
-- Features: Campaign Kits, MSA B2B Licensing, Storage Health, Clawback Auditing
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `order_refund_requests`;
DROP TABLE IF EXISTS `variant_storage_locations`;
DROP TABLE IF EXISTS `storage_vault_nodes`;
DROP TABLE IF EXISTS `contract_asset_allocations`;
DROP TABLE IF EXISTS `enterprise_contracts`;
DROP TABLE IF EXISTS `collection_items`;
DROP TABLE IF EXISTS `collections`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Curated Collections & Campaign Design Bundles
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

-- 2. Collection Items (Products within Bundles)
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

-- 3. Enterprise Agency Master Service Agreements (B2B Multi-Seat Contracts)
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

-- 4. Contract Asset Category Allocations & Quotas
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

-- 5. Multi-Cloud Storage Vault Infrastructure Registry
CREATE TABLE `storage_vault_nodes` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `node_identifier` VARCHAR(60) NOT NULL,
    `provider` ENUM('aws_s3', 'cloudflare_r2', 'wasabi_hot_storage', 'gcp_storage') NOT NULL,
    `region_code` VARCHAR(40) NOT NULL,
    `endpoint_url` VARCHAR(255) NOT NULL,
    `bucket_name` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `health_status` ENUM('healthy', 'degraded', 'offline') NOT NULL DEFAULT 'healthy',
    `latency_ms` SMALLINT UNSIGNED NOT NULL DEFAULT 25,
    `last_heartbeat_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vault_node_id` (`node_identifier`),
    INDEX `idx_vault_status` (`is_active`, `health_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. Variant Multi-Cloud Object Storage Locations & Replication Sync
CREATE TABLE `variant_storage_locations` (
    `variant_id` BIGINT UNSIGNED NOT NULL,
    `node_id` SMALLINT UNSIGNED NOT NULL,
    `storage_path_key` VARCHAR(300) NOT NULL,
    `replication_status` ENUM('pending', 'synced', 'failed', 'purged') NOT NULL DEFAULT 'pending',
    `last_verified_at` TIMESTAMP NULL DEFAULT NULL,
    `checksum_verified` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`variant_id`, `node_id`),
    INDEX `idx_vsl_node` (`node_id`, `replication_status`),
    INDEX `idx_vsl_sync` (`replication_status`, `checksum_verified`),
    CONSTRAINT `fk_vsl_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vsl_node` FOREIGN KEY (`node_id`) REFERENCES `storage_vault_nodes` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Order Item Refund Requests & Clawback Disputes
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
