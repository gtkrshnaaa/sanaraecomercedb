-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 06: Print Profiles, Collaborations, Bundles, Contracts, Vaults & Refunds
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `order_refund_requests`;
TRUNCATE TABLE `variant_storage_locations`;
TRUNCATE TABLE `storage_vault_nodes`;
TRUNCATE TABLE `contract_asset_allocations`;
TRUNCATE TABLE `enterprise_contracts`;
TRUNCATE TABLE `collection_items`;
TRUNCATE TABLE `collections`;
TRUNCATE TABLE `product_collaborators`;
TRUNCATE TABLE `spot_color_plates`;
TRUNCATE TABLE `product_print_profiles`;
TRUNCATE TABLE `print_production_profiles`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Standardized Industrial Print Production Profiles
INSERT INTO `print_production_profiles` (
    `id`, `profile_name`, `icc_profile_tag`, `substrate_type`, `max_ink_density_tac`,
    `screen_ruling_lpi`, `recommended_viewing_distance_meters`, `supports_spot_varnish`, `supports_die_cut`
) VALUES
(1, 'ISO 12647-2 FOGRA39 Coated Commercial Offset', 'FOGRA39_Coated_v2.icc', 'art_carton_310gsm', 320, 175, 0.50, 1, 1),
(2, 'GRACoL 2013 Coated Commercial Sheetfed', 'GRACoL2013_CRPC6.icc', 'art_carton_310gsm', 300, 175, 0.50, 1, 1),
(3, 'Highway Unipole Billboard Heavy Vinyl 510gsm High-UV', 'Sanara_Outdoor_Vinyl_510.icc', 'vinyl_frontlit_510gsm', 280, 85, 15.00, 0, 0),
(4, 'Exhibition Backlit Tension Fabric 650gsm', 'Sanara_Backlit_Fabric_650.icc', 'vinyl_backlit_650gsm', 320, 120, 2.00, 0, 0),
(5, 'Industrial Packaging Folding Carton B-Flute Corrugated', 'ISO12647-6_Flexo_BFlute.icc', 'corrugated_b_flute', 260, 100, 0.80, 1, 1);

-- 2. Product to Print Production Profile Specifications
INSERT INTO `product_print_profiles` (
    `product_id`, `profile_id`, `min_bleed_mm`, `safe_margin_mm`, `resolution_ppi_recommended`, `prepress_notes`
) VALUES
(1, 3, 100.00, 150.00, 72, 'Reinforced grommet hem at 300mm intervals. High UV ink resistance profile.'),
(2, 3, 50.00, 80.00, 100, 'Four corner metal eyelets. Double stitched perimeter hem.'),
(3, 1, 3.00, 5.00, 300, 'Strict FOGRA39 color profile. Dry-trap print sequence CMYK.'),
(7, 5, 5.00, 8.00, 300, 'CAD-cut die strike line in separate 100% Magenta spot color plate.'),
(8, 4, 10.00, 15.00, 150, 'Bottom 200mm concealed inside roller cassette housing.');

-- 3. Spot Color Plates & Finishing Channels
INSERT INTO `spot_color_plates` (
    `product_id`, `pantone_code`, `plate_name`, `color_role`,
    `cmyk_fallback_c`, `cmyk_fallback_m`, `cmyk_fallback_y`, `cmyk_fallback_k`
) VALUES
(1, 'PANTONE 021 C', 'Safety Highway Orange Plate', 'primary_brand_spot', 0, 65, 100, 0),
(1, 'PANTONE 286 C', 'Corporate Highway Deep Blue', 'primary_brand_spot', 100, 75, 0, 0),
(3, 'PANTONE Cool Gray 9 C', 'Neutral Modernist Grid Plate', 'primary_brand_spot', 0, 1, 0, 51),
(3, 'PANTONE 186 C', 'Swiss Flag Graphic Red Accent', 'primary_brand_spot', 0, 100, 81, 4),
(7, 'PANTONE 877 C', 'Cosmetic Silver Metallic Foil Plate', 'metallic_foil_stamping', 0, 0, 0, 40),
(7, 'DIELINE_CUT_CREASE', 'Mechanical Cut and Crease Die Channel', 'emboss_deboss_die', 0, 100, 0, 0);

-- 4. Multi-Party Creator Collaborations & Split Royalties
INSERT INTO `product_collaborators` (
    `product_id`, `creator_id`, `role_in_production`, `royalty_split_percentage`, `is_primary_lead`
) VALUES
-- Product 1: Highway Billboard (Nusantara Guild + Apex Brand)
(1, 1, 'lead_art_director', 70.00, 1),
(1, 4, 'typographer', 30.00, 0),

-- Product 4: Cyber Samurai 3D (Kyoto Vectors + PixelForge 3D)
(4, 2, '3d_modeling_artist', 65.00, 1),
(4, 5, 'texture_shading_artist', 35.00, 0),

-- Product 7: Packaging Box (Bauhaus Grid Lab + Nusantara Guild)
(7, 3, 'lead_art_director', 75.00, 1),
(7, 1, 'die_line_engineer', 25.00, 0);

-- 5. Curated Campaign Bundles & Collections
INSERT INTO `collections` (
    `id`, `uuid`, `curator_creator_id`, `title`, `slug`, `campaign_theme`,
    `description`, `bundle_discount_rate`, `is_featured`, `is_active`
) VALUES
(
    1, UUID(), 1,
    'Mega Transit & Highway Outdoor Takeover Suite',
    'mega-transit-highway-outdoor-takeover-suite',
    'outdoor_transit_takeover',
    'Complete outdoor advertising domination pack uniting large-format highway unipole billboards (14x4m), commercial street vinyl banners (spanduk), and portable exhibition roll-up displays.',
    25.00, 1, 1
),
(
    2, UUID(), 3,
    'Swiss Grid Exhibition & Packaging Identity Masterpack',
    'swiss-grid-exhibition-packaging-masterpack',
    'fmcg_packaging_suite',
    'Rigorous modernist branding system combining ISO A1 exhibition posters, commercial folding carton packaging die-lines, and cross-platform Figma design token libraries.',
    20.00, 1, 1
);

-- 6. Collection Items Mapping
INSERT INTO `collection_items` (`collection_id`, `product_id`, `display_order`, `is_hero_asset`) VALUES
(1, 1, 1, 1),
(1, 2, 2, 0),
(1, 8, 3, 0),
(2, 3, 1, 1),
(2, 5, 2, 0),
(2, 7, 3, 0);

-- 7. Enterprise Agency Master Service Agreements (B2B Contracts)
INSERT INTO `enterprise_contracts` (
    `id`, `uuid`, `agency_team_id`, `contract_number`, `tier`,
    `monthly_flat_fee_usd`, `annual_minimum_guarantee_usd`, `per_asset_royalty_discount_pct`,
    `max_seats_licensed`, `active_from`, `active_until`, `status`
) VALUES
(1, UUID(), 1, 'MSA-2025-OGILVY-APAC', 'platinum_conglomerate', 3500.00, 42000.00, 20.00, 25, '2025-01-01', '2026-12-31', 'active'),
(2, UUID(), 2, 'MSA-2025-DENTSU-GLOBAL', 'gold_network', 2200.00, 26400.00, 15.00, 15, '2025-02-01', '2026-01-31', 'active');

-- 8. Contract Asset Category Allocations & Quotas
INSERT INTO `contract_asset_allocations` (
    `contract_id`, `category_id`, `is_unlimited_cleared`, `monthly_download_quota`, `current_cycle_consumed`
) VALUES
(1, 2, 1, 500, 84),
(1, 3, 1, 500, 42),
(2, 4, 0, 150, 67),
(2, 6, 0, 100, 38);

-- 9. Multi-Cloud Storage Vault Infrastructure Registry
INSERT INTO `storage_vault_nodes` (
    `id`, `node_identifier`, `provider`, `region_code`, `endpoint_url`, `bucket_name`,
    `is_active`, `health_status`, `latency_ms`, `last_heartbeat_at`
) VALUES
(1, 's3-primary-us-east', 'aws_s3', 'us-east-1', 'https://s3.us-east-1.amazonaws.com/sanara-vault-primary', 'sanara-vault-primary', 1, 'healthy', 18, '2026-09-30 08:00:00'),
(2, 'r2-edge-apac-sg', 'cloudflare_r2', 'apac-singapore', 'https://r2.cloudflarestorage.com/sanara-vault-apac', 'sanara-vault-apac', 1, 'healthy', 12, '2026-09-30 08:00:00'),
(3, 'wasabi-archive-eu-ams', 'wasabi_hot_storage', 'eu-central-1', 'https://s3.eu-central-1.wasabisys.com/sanara-vault-eu', 'sanara-vault-eu', 1, 'healthy', 32, '2026-09-30 08:00:00');

-- 10. Variant Multi-Cloud Object Storage Locations & Replication Sync
INSERT INTO `variant_storage_locations` (
    `variant_id`, `node_id`, `storage_path_key`, `replication_status`, `last_verified_at`, `checksum_verified`
) VALUES
(1, 1, 'deliverables/prod_1/v1/billboard_14x4_ai.zip', 'synced', '2026-09-29 12:00:00', 1),
(1, 2, 'deliverables/prod_1/v1/billboard_14x4_ai.zip', 'synced', '2026-09-29 12:05:00', 1),
(3, 1, 'deliverables/prod_2/v1/spanduk_3x1_ai.zip', 'synced', '2026-09-29 12:00:00', 1),
(3, 2, 'deliverables/prod_2/v1/spanduk_3x1_ai.zip', 'synced', '2026-09-29 12:05:00', 1),
(4, 1, 'deliverables/prod_3/v1/swiss_a1_indesign.zip', 'synced', '2026-09-29 12:00:00', 1),
(4, 3, 'deliverables/prod_3/v1/swiss_a1_indesign.zip', 'synced', '2026-09-29 12:10:00', 1),
(6, 1, 'deliverables/prod_4/v1/cyber_samurai_blender.zip', 'synced', '2026-09-29 12:00:00', 1),
(6, 2, 'deliverables/prod_4/v1/cyber_samurai_blender.zip', 'synced', '2026-09-29 12:05:00', 1);

-- 11. Order Item Refund Requests & Clawback Disputes
INSERT INTO `order_refund_requests` (
    `id`, `uuid`, `order_item_id`, `buyer_id`, `reason_code`,
    `customer_explanation`, `status`, `approved_by_admin_id`, `refund_amount`, `submitted_at`, `resolved_at`
) VALUES
(
    1, UUID(), 7, 9, 'accidental_duplicate_purchase',
    'Purchased single item instead of full Swiss bundle, requesting refund to re-order bundle.',
    'approved_refunded', 1, 49.00, '2026-03-06 10:00:00', '2026-03-06 14:00:00'
);
