-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 03: Catalog Taxonomy, Visual Communication Products, and Rich Metadata
-- Features: Hierarchical Trees, JSON Specifications, Generated Columns, Full-Text
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `product_translations_i18n`;
DROP TABLE IF EXISTS `product_collaborators`;
DROP TABLE IF EXISTS `spot_color_plates`;
DROP TABLE IF EXISTS `product_print_profiles`;
DROP TABLE IF EXISTS `print_production_profiles`;
DROP TABLE IF EXISTS `product_preview_media`;
DROP TABLE IF EXISTS `product_tag_relations`;
DROP TABLE IF EXISTS `tags`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `software_ecosystems`;
DROP TABLE IF EXISTS `categories`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Hierarchical Categories (Taxonomy Tree)
CREATE TABLE `categories` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `parent_id` INT UNSIGNED NULL,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(110) NOT NULL,
    `category_code` VARCHAR(50) NOT NULL UNIQUE,
    `description` VARCHAR(255) NULL,
    `icon_svg` TEXT NULL,
    `path` VARCHAR(255) NOT NULL COMMENT 'Materialized hierarchy path e.g. /1/4/12/',
    `depth` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `display_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_category_slug` (`slug`),
    INDEX `idx_category_parent` (`parent_id`),
    INDEX `idx_category_path` (`path`),
    INDEX `idx_category_active_order` (`is_active`, `display_order`),
    CONSTRAINT `fk_cat_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Software Compatibility Registry
CREATE TABLE `software_ecosystems` (
    `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(80) NOT NULL,
    `slug` VARCHAR(90) NOT NULL,
    `vendor` VARCHAR(80) NOT NULL,
    `primary_extension` VARCHAR(10) NOT NULL,
    `icon_url` VARCHAR(255) NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_software_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Core Digital Design Products
CREATE TABLE `products` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `category_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `slug` VARCHAR(220) NOT NULL,
    `subtitle` VARCHAR(255) NULL,
    `description` LONGTEXT NOT NULL,
    `design_discipline` ENUM(
        'outdoor_advertising',
        'print_editorial',
        'branding_identity',
        'digital_ui_motion',
        'illustration_3d',
        'typography_iconography'
    ) NOT NULL,
    `status` ENUM('draft', 'submitted', 'under_review', 'published', 'rejected', 'archived') NOT NULL DEFAULT 'draft',
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
    `is_exclusive_sanara` TINYINT(1) NOT NULL DEFAULT 0,
    `base_standard_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `total_sales_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_views_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_downloads_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `average_rating` DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    `review_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `search_keywords` TEXT NULL,
    
    -- High Complexity Visual Specification (JSON Format)
    `design_metadata` JSON NOT NULL,
    
    -- Virtual / Stored Generated Columns for Direct Querying & Indexing
    `color_mode` VARCHAR(15) GENERATED ALWAYS AS (
        JSON_UNQUOTE(JSON_EXTRACT(`design_metadata`, '$.print_specs.color_space'))
    ) STORED,
    `resolution_dpi` SMALLINT UNSIGNED GENERATED ALWAYS AS (
        CAST(JSON_EXTRACT(`design_metadata`, '$.print_specs.dpi') AS UNSIGNED)
    ) STORED,
    `is_vector` TINYINT(1) GENERATED ALWAYS AS (
        CASE WHEN JSON_EXTRACT(`design_metadata`, '$.construction.is_vector') = TRUE THEN 1 ELSE 0 END
    ) STORED,
    `physical_dimensions` VARCHAR(50) GENERATED ALWAYS AS (
        CONCAT(
            JSON_UNQUOTE(JSON_EXTRACT(`design_metadata`, '$.dimensions.width')), 'x',
            JSON_UNQUOTE(JSON_EXTRACT(`design_metadata`, '$.dimensions.height')), ' ',
            JSON_UNQUOTE(JSON_EXTRACT(`design_metadata`, '$.dimensions.unit'))
        )
    ) STORED,
    
    `published_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_products_uuid` (`uuid`),
    UNIQUE KEY `uq_products_slug` (`slug`),
    
    -- Constraints
    CONSTRAINT `chk_products_json` CHECK (JSON_VALID(`design_metadata`)),
    CONSTRAINT `chk_products_price` CHECK (`base_standard_price` >= 0.00),
    CONSTRAINT `fk_product_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_product_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT,
    
    -- Strategic Indexes for E-Commerce Query Patterns
    INDEX `idx_prod_status_published` (`status`, `published_at` DESC),
    INDEX `idx_prod_category_status` (`category_id`, `status`, `base_standard_price`),
    INDEX `idx_prod_discipline_rating` (`design_discipline`, `average_rating` DESC),
    INDEX `idx_prod_creator` (`creator_id`, `status`),
    INDEX `idx_prod_gen_colormode` (`color_mode`),
    INDEX `idx_prod_gen_dpi` (`resolution_dpi`),
    INDEX `idx_prod_gen_vector` (`is_vector`),
    FULLTEXT KEY `idx_fts_products` (`title`, `subtitle`, `search_keywords`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Tag Indexing
CREATE TABLE `tags` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(60) NOT NULL,
    `slug` VARCHAR(70) NOT NULL,
    `usage_count` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tags_slug` (`slug`),
    INDEX `idx_tags_usage` (`usage_count` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. Product-Tag Pivot Table
CREATE TABLE `product_tag_relations` (
    `product_id` BIGINT UNSIGNED NOT NULL,
    `tag_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`product_id`, `tag_id`),
    INDEX `idx_ptr_tag` (`tag_id`),
    CONSTRAINT `fk_ptr_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. Product Visual Preview & Showcase Media
CREATE TABLE `product_preview_media` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `media_type` ENUM('cover_thumbnail', 'detail_slide', 'mockup_scene', 'interactive_3d', 'video_showcase') NOT NULL,
    `storage_key` VARCHAR(255) NOT NULL,
    `cdn_url` VARCHAR(500) NOT NULL,
    `width_px` INT UNSIGNED NOT NULL,
    `height_px` INT UNSIGNED NOT NULL,
    `mime_type` VARCHAR(50) NOT NULL DEFAULT 'image/webp',
    `file_size_bytes` INT UNSIGNED NOT NULL,
    `display_order` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_watermarked` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_preview_product_order` (`product_id`, `display_order`),
    CONSTRAINT `fk_preview_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Standardized Industrial Print Production & Pre-Flight Profiles
CREATE TABLE `print_production_profiles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `profile_name` VARCHAR(120) NOT NULL,
    `icc_profile_tag` VARCHAR(80) NOT NULL,
    `substrate_type` ENUM(
        'vinyl_frontlit_510gsm',
        'vinyl_backlit_650gsm',
        'mesh_banner_windproof',
        'art_carton_310gsm',
        'corrugated_b_flute',
        'one_way_vision_perforated',
        'fine_art_canvas_cotton',
        'aluminum_composite_panel'
    ) NOT NULL,
    `max_ink_density_tac` SMALLINT UNSIGNED NOT NULL DEFAULT 300 COMMENT 'Total Area Coverage in percent e.g. 300%',
    `screen_ruling_lpi` SMALLINT UNSIGNED NOT NULL DEFAULT 150 COMMENT 'Lines Per Inch screening frequency',
    `recommended_viewing_distance_meters` DECIMAL(4, 2) NOT NULL DEFAULT 1.00,
    `supports_spot_varnish` TINYINT(1) NOT NULL DEFAULT 0,
    `supports_die_cut` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_profile_name` (`profile_name`),
    INDEX `idx_profile_substrate` (`substrate_type`, `max_ink_density_tac`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 8. Product to Print Production Profile Relations (Pre-Press Specifications)
CREATE TABLE `product_print_profiles` (
    `product_id` BIGINT UNSIGNED NOT NULL,
    `profile_id` INT UNSIGNED NOT NULL,
    `min_bleed_mm` DECIMAL(5, 2) NOT NULL DEFAULT 3.00,
    `safe_margin_mm` DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
    `resolution_ppi_recommended` SMALLINT UNSIGNED NOT NULL DEFAULT 300,
    `prepress_notes` VARCHAR(255) NULL,
    PRIMARY KEY (`product_id`, `profile_id`),
    INDEX `idx_ppp_profile` (`profile_id`),
    CONSTRAINT `fk_ppp_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ppp_profile` FOREIGN KEY (`profile_id`) REFERENCES `print_production_profiles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 9. Spot Color Plates & Finishing Channels (Pantone, White Ink, Foil, Die-cut)
CREATE TABLE `spot_color_plates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `pantone_code` VARCHAR(50) NOT NULL COMMENT 'e.g. PANTONE 186 C, PANTONE Cool Gray 9 C',
    `plate_name` VARCHAR(80) NOT NULL,
    `color_role` ENUM(
        'primary_brand_spot',
        'metallic_foil_stamping',
        'selective_uv_varnish',
        'emboss_deboss_die',
        'white_underbase_opaque',
        'security_fluorescent'
    ) NOT NULL,
    `cmyk_fallback_c` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_m` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_y` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `cmyk_fallback_k` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_spot_prod` (`product_id`),
    INDEX `idx_spot_pantone` (`pantone_code`),
    INDEX `idx_spot_role` (`color_role`),
    CONSTRAINT `chk_cmyk_c` CHECK (`cmyk_fallback_c` <= 100),
    CONSTRAINT `chk_cmyk_m` CHECK (`cmyk_fallback_m` <= 100),
    CONSTRAINT `chk_cmyk_y` CHECK (`cmyk_fallback_y` <= 100),
    CONSTRAINT `chk_cmyk_k` CHECK (`cmyk_fallback_k` <= 100),
    CONSTRAINT `fk_spot_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 10. Multi-Party Creator Collaborations & Split Royalties
CREATE TABLE `product_collaborators` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `creator_id` BIGINT UNSIGNED NOT NULL,
    `role_in_production` ENUM(
        'lead_art_director',
        '3d_modeling_artist',
        'texture_shading_artist',
        'prepress_colorist',
        'typographer',
        'die_line_engineer',
        'motion_graphics_animator'
    ) NOT NULL,
    `royalty_split_percentage` DECIMAL(5, 2) NOT NULL COMMENT 'Portion of creator net royalty e.g. 60.00%',
    `is_primary_lead` TINYINT(1) NOT NULL DEFAULT 0,
    `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_prod_creator_collab` (`product_id`, `creator_id`),
    INDEX `idx_collab_creator` (`creator_id`),
    INDEX `idx_collab_role` (`role_in_production`),
    CONSTRAINT `chk_royalty_split_range` CHECK (`royalty_split_percentage` > 0.00 AND `royalty_split_percentage` <= 100.00),
    CONSTRAINT `fk_collab_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_collab_creator` FOREIGN KEY (`creator_id`) REFERENCES `creator_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 11. Multi-Language Catalog Localization & Natural Language Indexing
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

