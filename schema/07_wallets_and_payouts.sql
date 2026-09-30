-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 07: Creator Wallets, Immutable Ledger Entries, Escrow & Payouts
-- Principles: Strict Financial Auditability, Non-Destructive Double-Entry Ledger
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `wallet_ledger_entries`;
DROP TABLE IF EXISTS `payout_requests`;
DROP TABLE IF EXISTS `creator_wallets`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Creator Wallets (State Snapshot)
CREATE TABLE `creator_wallets` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'USD',
    `available_balance` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `pending_escrow_balance` DECIMAL(12, 2) NOT NULL DEFAULT 0.00 COMMENT 'Funds held in 14-day escrow window against chargebacks',
    `lifetime_withdrawn_total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    `is_payout_blocked` TINYINT(1) NOT NULL DEFAULT 0,
    `payout_block_reason` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_wallet_creator_curr` (`creator_id`, `currency`),
    CONSTRAINT `chk_wallet_positive_avail` CHECK (`available_balance` >= 0.00),
    CONSTRAINT `chk_wallet_positive_escrow` CHECK (`pending_escrow_balance` >= 0.00),
    CONSTRAINT `fk_wallet_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Payout Requests
CREATE TABLE `payout_requests` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    `currency` CHAR(3) NOT NULL DEFAULT 'USD',
    `payout_method` ENUM('wise', 'paypal', 'bank_wire', 'payoneer', 'crypto_usdc') NOT NULL,
    `destination_account_metadata` JSON NOT NULL,
    `status` ENUM('pending_approval', 'approved', 'processing', 'completed', 'rejected', 'failed') NOT NULL DEFAULT 'pending_approval',
    `payout_fee_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `gateway_batch_id` VARCHAR(150) NULL,
    `rejection_reason` VARCHAR(255) NULL,
    `reviewed_by_admin_id` BIGINT UNSIGNED NULL,
    `processed_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_payout_uuid` (`uuid`),
    INDEX `idx_payout_creator` (`creator_id`, `status`),
    INDEX `idx_payout_status_created` (`status`, `created_at`),
    CONSTRAINT `chk_payout_dest_json` CHECK (JSON_VALID(`destination_account_metadata`)),
    CONSTRAINT `chk_payout_amount` CHECK (`amount` > 0.00),
    CONSTRAINT `fk_payout_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payout_admin` FOREIGN KEY (`reviewed_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Immutable Financial Ledger Entries (Audit Trail)
CREATE TABLE `wallet_ledger_entries` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `wallet_id` BIGINT UNSIGNED NOT NULL,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `entry_type` ENUM(
        'sale_royalty',
        'escrow_release',
        'payout_withdrawal',
        'chargeback_reversal',
        'bonus_adjustment',
        'platform_fee_correction'
    ) NOT NULL,
    `direction` ENUM('credit', 'debit') NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    `balance_before` DECIMAL(12, 2) NOT NULL,
    `balance_after` DECIMAL(12, 2) NOT NULL,
    `order_item_id` BIGINT UNSIGNED NULL,
    `payout_request_id` BIGINT UNSIGNED NULL,
    `reference_note` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_ledger_wallet_date` (`wallet_id`, `created_at`),
    INDEX `idx_ledger_creator_type` (`creator_id`, `entry_type`),
    INDEX `idx_ledger_order_item` (`order_item_id`),
    INDEX `idx_ledger_payout` (`payout_request_id`),
    CONSTRAINT `chk_ledger_amount_positive` CHECK (`amount` > 0.00),
    CONSTRAINT `fk_ledger_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `creator_wallets` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ledger_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ledger_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ledger_payout` FOREIGN KEY (`payout_request_id`) REFERENCES `payout_requests` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
