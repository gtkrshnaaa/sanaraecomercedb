-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 02: IAM, Users, Studios, Creator Profiles, and Agency Teams
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `creator_kyc_compliance`;
DROP TABLE IF EXISTS `user_activity_sessions`;
DROP TABLE IF EXISTS `agency_members`;
DROP TABLE IF EXISTS `agency_teams`;
DROP TABLE IF EXISTS `creator_social_links`;
DROP TABLE IF EXISTS `creator_profiles`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Core Users Table
CREATE TABLE `users` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `display_name` VARCHAR(100) NOT NULL,
    `role` ENUM('customer', 'creator', 'art_director', 'support', 'super_admin') NOT NULL DEFAULT 'customer',
    `status` ENUM('pending', 'active', 'suspended', 'deactivated') NOT NULL DEFAULT 'active',
    `avatar_url` VARCHAR(500) NULL,
    `email_verified_at` TIMESTAMP NULL DEFAULT NULL,
    `two_factor_enabled` TINYINT(1) NOT NULL DEFAULT 0,
    `two_factor_secret` VARCHAR(255) NULL,
    `preferred_currency` CHAR(3) NOT NULL DEFAULT 'USD',
    `preferred_locale` VARCHAR(10) NOT NULL DEFAULT 'en_US',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_users_uuid` (`uuid`),
    UNIQUE KEY `uq_users_email` (`email`),
    INDEX `idx_users_role_status` (`role`, `status`),
    INDEX `idx_users_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Creator / Design Studio Profiles
CREATE TABLE `creator_profiles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `studio_name` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(160) NOT NULL,
    `bio` TEXT NULL,
    `headline` VARCHAR(255) NULL,
    `banner_url` VARCHAR(500) NULL,
    `country_code` CHAR(2) NOT NULL,
    `tax_id_number` VARCHAR(100) NULL,
    `commission_rate` DECIMAL(5, 2) NOT NULL DEFAULT 80.00 COMMENT 'Percentage creator retains (e.g. 80.00% = creator, 20% = Sanara platform fee)',
    `is_verified_creator` TINYINT(1) NOT NULL DEFAULT 0,
    `verified_at` TIMESTAMP NULL DEFAULT NULL,
    `total_products_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_sales_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_revenue_usd` DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    `average_rating` DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_creator_user_id` (`user_id`),
    UNIQUE KEY `uq_creator_slug` (`slug`),
    INDEX `idx_creator_rating_sales` (`average_rating` DESC, `total_sales_count` DESC),
    INDEX `idx_creator_verified` (`is_verified_creator`, `country_code`),
    CONSTRAINT `fk_creator_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Creator Social & Portfolio Links
CREATE TABLE `creator_social_links` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `platform` ENUM('behance', 'dribbble', 'artstation', 'figma', 'instagram', 'youtube', 'github', 'website') NOT NULL,
    `url` VARCHAR(500) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_creator_platform` (`creator_id`, `platform`),
    CONSTRAINT `fk_social_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Agency Teams (B2B Multi-Seat / Enterprise Accounts)
CREATE TABLE `agency_teams` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_user_id` BIGINT UNSIGNED NOT NULL,
    `team_name` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(160) NOT NULL,
    `billing_email` VARCHAR(255) NOT NULL,
    `seat_limit` SMALLINT UNSIGNED NOT NULL DEFAULT 5,
    `enterprise_plan` ENUM('starter', 'growth', 'enterprise_unlimited') NOT NULL DEFAULT 'starter',
    `status` ENUM('active', 'past_due', 'canceled') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_agency_slug` (`slug`),
    INDEX `idx_agency_owner` (`owner_user_id`),
    CONSTRAINT `fk_agency_owner` FOREIGN KEY (`owner_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. Agency Team Members
CREATE TABLE `agency_members` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `team_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `team_role` ENUM('owner', 'admin', 'art_director', 'designer', 'license_auditor') NOT NULL DEFAULT 'designer',
    `invited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `joined_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_team_user` (`team_id`, `user_id`),
    INDEX `idx_members_user` (`user_id`),
    CONSTRAINT `fk_member_team` FOREIGN KEY (`team_id`) REFERENCES `agency_teams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_member_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. User Activity & Session Auditing
CREATE TABLE `user_activity_sessions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `session_token_hash` CHAR(64) NOT NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `user_agent` VARCHAR(500) NULL,
    `last_active_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_session_user` (`user_id`),
    INDEX `idx_session_token` (`session_token_hash`),
    INDEX `idx_session_expiry` (`expires_at`),
    CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Creator AML / KYC Financial Compliance & Vetting Registry
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

