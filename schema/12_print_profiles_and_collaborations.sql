-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 12: Print Pre-Flight Profiles, Spot Color Plates & Creative Collaborations
-- Features: Substrate TAC Ratings, Spot Inks, Die-lines, Multi-Creator Royalty Splits
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `product_collaborators`;
DROP TABLE IF EXISTS `spot_color_plates`;
DROP TABLE IF EXISTS `product_print_profiles`;
DROP TABLE IF EXISTS `print_production_profiles`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Standardized Industrial Print Production & Pre-Flight Profiles
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

-- 2. Product to Print Production Profile Relations (Pre-Press Specifications)
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

-- 3. Spot Color Plates & Finishing Channels (Pantone, White Ink, Foil, Die-cut)
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

-- 4. Multi-Party Creator Collaborations & Split Royalties
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
