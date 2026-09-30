-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 08: Quality Assurance, Customer Reviews, and System Audit Logs
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `system_audit_logs`;
DROP TABLE IF EXISTS `review_helpful_votes`;
DROP TABLE IF EXISTS `product_reviews`;
DROP TABLE IF EXISTS `product_quality_reviews`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Art Director Quality Assurance & Technical Inspection
CREATE TABLE `product_quality_reviews` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `inspector_user_id` BIGINT UNSIGNED NOT NULL,
    `review_status` ENUM('passed', 'changes_requested', 'rejected') NOT NULL,
    `technical_checklist` JSON NOT NULL COMMENT 'JSON flags for DPI, Bleed, Color Space, Font Embeds',
    `curator_feedback` TEXT NULL,
    `reviewed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_qa_product` (`product_id`),
    INDEX `idx_qa_inspector` (`inspector_user_id`),
    CONSTRAINT `chk_qa_json` CHECK (JSON_VALID(`technical_checklist`)),
    CONSTRAINT `fk_qa_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_qa_inspector` FOREIGN KEY (`inspector_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Customer Product Reviews & Star Ratings
CREATE TABLE `product_reviews` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `order_item_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `rating` TINYINT UNSIGNED NOT NULL,
    `headline` VARCHAR(150) NOT NULL,
    `review_body` TEXT NOT NULL,
    `is_verified_purchase` TINYINT(1) NOT NULL DEFAULT 1,
    `helpful_votes_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `creator_reply` TEXT NULL,
    `creator_replied_at` TIMESTAMP NULL DEFAULT NULL,
    `status` ENUM('published', 'flagged', 'hidden') NOT NULL DEFAULT 'published',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_review_order_item` (`order_item_id`),
    INDEX `idx_review_product_rating` (`product_id`, `status`, `rating` DESC),
    INDEX `idx_review_user` (`user_id`),
    CONSTRAINT `chk_review_rating_range` CHECK (`rating` BETWEEN 1 AND 5),
    CONSTRAINT `fk_review_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_review_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Review Helpful Votes
CREATE TABLE `review_helpful_votes` (
    `review_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `is_helpful` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`review_id`, `user_id`),
    CONSTRAINT `fk_vote_review` FOREIGN KEY (`review_id`) REFERENCES `product_reviews` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vote_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Central System Security & Operational Audit Log
CREATE TABLE `system_audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `actor_user_id` BIGINT UNSIGNED NULL,
    `action` VARCHAR(60) NOT NULL,
    `entity_type` VARCHAR(60) NOT NULL,
    `entity_id` BIGINT UNSIGNED NOT NULL,
    `old_state` JSON NULL,
    `new_state` JSON NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `user_agent` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_audit_actor` (`actor_user_id`),
    INDEX `idx_audit_entity` (`entity_type`, `entity_id`),
    INDEX `idx_audit_action_date` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
