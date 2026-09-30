-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 07: Expanded Catalog Assets, Semantic Revisions, Translations & Compliance
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `coupon_redemption_history`;
TRUNCATE TABLE `creator_kyc_compliance`;
TRUNCATE TABLE `product_translations_i18n`;
TRUNCATE TABLE `product_asset_revisions`;
DELETE FROM `product_print_profiles` WHERE `product_id` >= 9;
DELETE FROM `product_pricing_matrix` WHERE `product_id` >= 9;
DELETE FROM `product_variants` WHERE `id` >= 12 OR `product_id` >= 9;
DELETE FROM `products` WHERE `id` >= 9;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Creator KYC Financial Compliance & Anti-Money Laundering (AML) Records
INSERT INTO `creator_kyc_compliance` (
    `creator_id`, `tax_id_hash`, `vat_number`, `legal_entity_name`,
    `residence_country_iso`, `compliance_status`, `aml_risk_score`,
    `payout_currency_code`, `reviewed_by_admin_id`, `verified_at`
) VALUES
(1, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'ID00982189421', 'PT Nusantara Desain Visual', 'ID', 'verified_approved', 5, 'USD', 1, '2025-01-10 10:00:00'),
(2, 'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb', 'JP81290312901', 'Kyoto Digital Arts GK', 'JP', 'verified_approved', 8, 'USD', 1, '2025-01-15 11:30:00'),
(3, '4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce', 'DE319028401', 'Bauhaus Raster Medien GmbH', 'DE', 'verified_approved', 4, 'USD', 1, '2025-02-01 09:00:00'),
(4, '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08', 'GB921048120', 'Apex Visual Motion Ltd', 'GB', 'verified_approved', 12, 'USD', 1, '2025-02-12 14:00:00'),
(5, '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b', NULL, 'PixelForge Asset Foundry LLC', 'US', 'w8_ben_submitted', 15, 'USD', 1, '2025-02-20 16:00:00');

-- 2. Expanded Production Products (Products 9 to 14)
INSERT INTO `products` (
    `id`, `uuid`, `creator_id`, `category_id`, `title`, `slug`, `subtitle`, `description`,
    `design_discipline`, `status`, `is_featured`, `is_exclusive_sanara`, `base_standard_price`,
    `total_sales_count`, `average_rating`, `review_count`, `search_keywords`, `design_metadata`, `published_at`
) VALUES
-- Product 9: Transjakarta 12-Meter Fleet Bus Wrap
(
    9, UUID(), 1, 2,
    'Transjakarta 12-Meter Transit Fleet Bus Wrap Vector Master',
    'transjakarta-12m-transit-fleet-bus-wrap-master',
    'Commercial 12-Meter City Transit Bus Wrap Template with Window Perforation Zones',
    'Precision engineered vector bus wrap template for 12-meter commercial transit vehicles. Includes designated 1-way-vision window safety perimeters, wheel arch clearances, emergency exit cutaways, and high-impact roadside brand visibility guidelines.',
    'outdoor_advertising', 'published', 1, 1, 95.00, 18, 4.94, 14,
    'bus wrap transit advertising transjakarta outdoor transport vehicle vector cmyk perforated vinyl',
    '{
        "dimensions": {"width": 12000, "height": 3200, "unit": "mm", "aspect_ratio": "12:3.2"},
        "print_specs": {
            "dpi": 100,
            "color_space": "CMYK",
            "bleed_mm": 50,
            "safety_margin_mm": 100,
            "spot_colors": ["PANTONE 186 C", "White Underbase"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 64,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#E00000", "#111111", "#FFFFFF"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2023", "extension": "AI"},
            {"software": "CorelDRAW", "min_version": "2022", "extension": "CDR"}
        ]
    }',
    '2025-03-01 10:00:00'
),
-- Product 10: Semarang Simpang Lima 20x8m Curved Unipole
(
    10, UUID(), 1, 2,
    'Simpang Lima Mega Curved Unipole Billboard 20x8m',
    'simpang-lima-mega-curved-unipole-billboard-20x8m',
    'Extra Large Format 20x8 Meter Panoramic Curved Unipole Outdoor Advertising Template',
    'Panoramic large-format curved outdoor billboard layout designed for major roundabout traffic intersections. Engineered with 280% TAC limits, heavy UV ink resistance curves, and reinforced 50mm perimeter hemming specifications.',
    'outdoor_advertising', 'published', 0, 1, 119.00, 12, 4.88, 9,
    'billboard unipole curved panoramic outdoor advertising baliho semarang 20x8 vinyl cmyk',
    '{
        "dimensions": {"width": 20000, "height": 8000, "unit": "mm", "aspect_ratio": "20:8"},
        "print_specs": {
            "dpi": 72,
            "color_space": "CMYK",
            "bleed_mm": 150,
            "safety_margin_mm": 200,
            "spot_colors": ["PANTONE 286 C", "PANTONE 116 C"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 36,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#003399", "#FFCC00", "#050505", "#FFFFFF"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2022", "extension": "AI"}
        ]
    }',
    '2025-03-10 14:00:00'
),
-- Product 11: Tokyo Shibuya 3D Anamorphic LED Billboard
(
    11, UUID(), 2, 6,
    'Shibuya Crossing 3D Anamorphic Curved LED Billboard Pack',
    'shibuya-crossing-3d-anamorphic-curved-led-pack',
    'Corner Curved 4K 3D Illusion Anamorphic Display Scene for Blender & Unreal Engine',
    'Anamorphic optical illusion 3D template calibrated for 90-degree corner-curved LED billboards. Includes exact camera perspective projection rigs, Blender procedural shading setups, and pre-baked 60 FPS animation tracks.',
    'illustration_3d', 'published', 1, 0, 149.00, 22, 4.97, 19,
    '3d anamorphic billboard shibuya led curved corner optical illusion blender 4k cgi animation',
    '{
        "dimensions": {"width": 3840, "height": 2160, "unit": "px", "aspect_ratio": "16:9"},
        "print_specs": {
            "dpi": 72,
            "color_space": "sRGB",
            "bleed_mm": 0,
            "safety_margin_mm": 0,
            "spot_colors": []
        },
        "construction": {
            "is_vector": false,
            "layer_count": 82,
            "has_smart_objects": false,
            "font_embedded": false,
            "color_palette": ["#0A0A0A", "#FF0055", "#00F0FF", "#E5E5E5"]
        },
        "software_compatibility": [
            {"software": "Blender", "min_version": "4.1", "extension": "BLEND"},
            {"software": "Unreal Engine", "min_version": "5.3", "extension": "UPROJECT"}
        ]
    }',
    '2025-03-15 09:30:00'
),
-- Product 12: Berlin Electronic Festival ISO A0 Heavyweight Screen-Print Poster
(
    12, UUID(), 3, 4,
    'Berlin Underground Techno Festival ISO A0 Screen-Print Poster',
    'berlin-underground-techno-festival-iso-a0-poster',
    'Strict International ISO A0 Print Media Template with Custom Halftone Screening',
    'Exhibition-scale ISO A0 poster template honoring classical Swiss international typographic style. Features calibrated 12-column grid alignment, custom stochastic halftone angle presets, and dual spot color separation plates for manual silk-screen printing.',
    'print_editorial', 'published', 1, 1, 55.00, 31, 4.92, 23,
    'poster iso a0 screen print techno festival swiss grid modernist typography cmyk pantone',
    '{
        "dimensions": {"width": 841, "height": 1189, "unit": "mm", "aspect_ratio": "1:1.414"},
        "print_specs": {
            "dpi": 300,
            "color_space": "CMYK",
            "bleed_mm": 5,
            "safety_margin_mm": 8,
            "spot_colors": ["PANTONE Black 6 C", "PANTONE 805 C Neon Red"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 28,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#111111", "#FF2244", "#F4F4F0"]
        },
        "software_compatibility": [
            {"software": "Adobe InDesign", "min_version": "CC 2023", "extension": "INDD"},
            {"software": "Adobe Illustrator", "min_version": "CC 2023", "extension": "AI"}
        ]
    }',
    '2025-03-20 11:00:00'
),
-- Product 13: Luxury Coffee Packaging Die-Line Box with Foil Stamping
(
    13, UUID(), 3, 5,
    'Artisanal Specialty Coffee Packaging Box CAD Die-Line Suite',
    'artisanal-specialty-coffee-packaging-box-dieline',
    'Premium Folding Carton Box Die-Cut with Metallic Foil & Blind Emboss Channels',
    'Industrial packaging engineering template for 250g specialty whole bean coffee boxes. Features precision CAD folding crease vectors, 15mm glue flap tolerances, metallic foil mask channel, and 300gsm Kraft carton substrate compatibility.',
    'print_editorial', 'published', 0, 1, 65.00, 27, 4.89, 21,
    'packaging box dieline folding carton coffee luxury foil stamping emboss cmyk pantone packaging',
    '{
        "dimensions": {"width": 120, "height": 180, "unit": "mm", "aspect_ratio": "12:18"},
        "print_specs": {
            "dpi": 300,
            "color_space": "CMYK",
            "bleed_mm": 3,
            "safety_margin_mm": 5,
            "spot_colors": ["PANTONE 871 C Metallic Gold", "DIELINE_CUT_CREASE"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 42,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#1A1A1A", "#D4AF37", "#FFFFFF"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2022", "extension": "AI"}
        ]
    }',
    '2025-03-25 15:00:00'
),
-- Product 14: OmniGlyph Finance Vector Icons (1,200 Icons)
(
    14, UUID(), 5, 8,
    'OmniGlyph Core Fintech & Banking Iconography System (1,200 SVG)',
    'omniglyph-core-fintech-banking-iconography-system',
    'Comprehensive 24px Grid Vector Icon Library for Enterprise Fintech & Mobile Banking',
    'Standardized corporate financial icon system drawn on a 24x24px pixel-perfect grid with consistent 1.5px and 2.0px live stroke weights. Packaged as individual production-ready SVGs, Figma design tokens, and a complete React icon web component library.',
    'typography_iconography', 'published', 1, 1, 75.00, 44, 4.98, 38,
    'icons vector fintech banking svg figma design system financial icons 24px pixel perfect',
    '{
        "dimensions": {"width": 24, "height": 24, "unit": "px", "aspect_ratio": "1:1"},
        "print_specs": {
            "dpi": 72,
            "color_space": "RGB",
            "bleed_mm": 0,
            "safety_margin_mm": 0,
            "spot_colors": []
        },
        "construction": {
            "is_vector": true,
            "layer_count": 1200,
            "has_smart_objects": false,
            "font_embedded": false,
            "color_palette": ["#000000", "#FFFFFF"]
        },
        "software_compatibility": [
            {"software": "Figma", "min_version": "All", "extension": "FIG"},
            {"software": "SVG", "min_version": "1.1", "extension": "SVG"}
        ]
    }',
    '2025-04-01 10:00:00'
);

-- 3. Product Variants for Expanded Products (Variants 12 to 17)
INSERT INTO `product_variants` (
    `id`, `uuid`, `product_id`, `software_id`, `name`, `sku`, `file_format`,
    `file_size_bytes`, `archive_checksum_sha256`, `storage_s3_key`, `is_primary_deliverable`, `version_label`
) VALUES
(12, UUID(), 9, 1, 'Bus Wrap Illustrator Vector Master [.ai]', 'SKU-BUS-09-AI', 'ai', 142606336, 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90', 'deliverables/prod_9/v1/bus_wrap_12m.zip', 1, '1.0.0'),
(13, UUID(), 10, 1, 'Semarang 20x8m Unipole Master Vector [.ai]', 'SKU-SMPG-10-AI', 'ai', 198762496, 'b2c3d4e5f6a10718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f91', 'deliverables/prod_10/v1/semarang_unipole_20x8.zip', 1, '1.0.0'),
(14, UUID(), 11, 4, 'Shibuya Anamorphic Blender 4.1 Master Project', 'SKU-SHIB-11-BLEND', 'blend', 681574400, 'c3d4e5f6a1b20718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f92', 'deliverables/prod_11/v1/shibuya_anamorphic.zip', 1, '1.0.0'),
(15, UUID(), 12, 1, 'Berlin Techno Poster InDesign Master [.indd]', 'SKU-TECH-12-INDD', 'indd', 94371840, 'd4e5f6a1b2c30718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f93', 'deliverables/prod_12/v1/berlin_poster_a0.zip', 1, '1.0.0'),
(16, UUID(), 13, 1, 'Specialty Coffee Box CAD Die-Cut Vector [.ai]', 'SKU-COFF-13-AI', 'ai', 73400320, 'e5f6a1b2c3d40718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f94', 'deliverables/prod_13/v1/coffee_box_dieline.zip', 1, '1.0.0'),
(17, UUID(), 14, 3, 'OmniGlyph 1,200 Fintech Icons Figma Kit [.fig]', 'SKU-FIN-14-FIG', 'fig', 115343360, 'f6a1b2c3d4e50718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f95', 'deliverables/prod_14/v1/omniglyph_fintech_figma.fig', 1, '1.0.0');

-- 4. Pricing Matrix for Expanded Products
INSERT INTO `product_pricing_matrix` (`product_id`, `license_id`, `currency`, `price`, `sale_price`) VALUES
(9, 1, 'USD', 95.00, NULL),
(9, 2, 'USD', 199.00, 179.00),
(9, 3, 'USD', 499.00, NULL),
(10, 1, 'USD', 119.00, NULL),
(10, 2, 'USD', 249.00, NULL),
(10, 3, 'USD', 599.00, NULL),
(11, 1, 'USD', 149.00, 129.00),
(11, 2, 'USD', 299.00, NULL),
(11, 3, 'USD', 750.00, NULL),
(12, 1, 'USD', 55.00, NULL),
(12, 2, 'USD', 119.00, NULL),
(12, 3, 'USD', 289.00, NULL),
(13, 1, 'USD', 65.00, NULL),
(13, 2, 'USD', 139.00, 119.00),
(13, 3, 'USD', 349.00, NULL),
(14, 1, 'USD', 75.00, NULL),
(14, 2, 'USD', 165.00, NULL),
(14, 3, 'USD', 399.00, NULL);

-- 5. Print Production Profiles for Expanded Print Assets
INSERT INTO `product_print_profiles` (`product_id`, `profile_id`, `min_bleed_mm`, `safe_margin_mm`, `resolution_ppi_recommended`, `prepress_notes`) VALUES
(9, 3, 50.00, 100.00, 100, 'Perforated one-way vision vinyl for side windows. UV cured outdoor inks.'),
(10, 3, 150.00, 200.00, 72, 'Reinforced 50mm perimeter hemming with internal nylon rope core.'),
(12, 1, 5.00, 8.00, 300, 'Hand screen-print sequence: Spot Black 6 C first, then Spot 805 C Neon Red overlay.'),
(13, 5, 3.00, 5.00, 300, 'Hot foil stamping plate on 300gsm uncoated Kraft stock.');

-- 6. Semantic Asset Revisions
INSERT INTO `product_asset_revisions` (
    `product_id`, `variant_id`, `semver_major`, `semver_minor`, `semver_patch`,
    `release_title`, `changelog_markdown`, `archive_sha256`, `file_size_bytes`,
    `storage_path`, `is_breaking_change`, `is_deprecated`, `released_by_creator_id`
) VALUES
(1, 1, 1, 0, 0, 'Initial Billboard Master Release', 'Initial production release for 14x4m unipole highway billboard.', '8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4', 125829120, 'deliverables/prod_1/v1/billboard_14x4_ai.zip', 0, 0, 1),
(1, 1, 1, 1, 0, 'Spot Orange Calibration & Grommet Guide', 'Added Pantone 021 C spot plate channel and 300mm interval grommet eyelet placement guides.', '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b', 128974848, 'deliverables/prod_1/v1_1/billboard_14x4_ai.zip', 0, 0, 1),
(1, 1, 2, 0, 0, 'CC 2024 Engine Migration & Optimized Anchor Paths', 'Refactored vector artwork to reduce anchor points by 40% while preserving sub-millimeter curves.', 'c81e728d9d4c2f636f067f89cc14862c1ecd77d84fe45d0891ec355c277fe32a', 120586240, 'deliverables/prod_1/v2/billboard_14x4_ai.zip', 1, 0, 1),
(4, 6, 1, 0, 0, 'Cyber Samurai 3D Initial Rig', 'Initial Blender 4.0 rigged model with basic FK rig.', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 471859200, 'deliverables/prod_4/v1/cyber_samurai_blender.zip', 0, 0, 2),
(4, 6, 1, 1, 0, 'PBR 4K Texture Upgrade & IK Rigs', 'Upgraded roughness/metallic textures to 4K and added Inverse Kinematics (IK) foot controllers.', '6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a', 512000000, 'deliverables/prod_4/v1_1/cyber_samurai_blender.zip', 0, 0, 2);

-- 7. Multi-Language Catalog Localization (i18n)
INSERT INTO `product_translations_i18n` (
    `product_id`, `locale_code`, `localized_title`, `localized_subtitle`, `localized_description`, `is_approved_translation`
) VALUES
-- Product 1 (Billboard)
(1, 'id_ID', 'Suite Cetak Billboard Jalan Tol Megacity 14x4m Ultra', 'Template Vektor Baliho Luar Ruangan 14x4 Meter Format Besar', 'Template billboard luar ruangan standar industri yang dirancang khusus untuk pencetakan format besar di jalan tol bebas hambatan. Dilengkapi zona batas bleed presisi, karya seni vektor yang dapat diskalakan tanpa batas, pemisahan warna spot, dan hierarki tipografi berjarak pandang 150 meter.', 1),
(1, 'ja_JP', 'メガシティ高速道路看板 14x4m ウルトラプリントスイート', '大型屋外ユニポール＆高速道路看板ベクターテンプレート 14x4m', '高速道路の大規模印刷向けに設計された産業グレードの屋外看板テンプレート。正確な機械裁ち落とし安全ゾーン、スケーラブルなベクターアートワーク、スポットカラー分解、150m先からでも視認性の高いタイポグラフィ階層を備えています。', 1),
(1, 'de_DE', 'Megacity Autobahn-Plakatwand 14x4m Ultra-Druck-Suite', 'Großformatige 14x4 Meter Outdoor Unipol- und Autobahn-Plakatwand-Vektorvorlage', 'Industrielle Außenplakatwand-Vorlage speziell für den großformatigen Autobahndruck. Bietet präzise Sicherheitszonen für den Beschnitt, skalierbare Vektorgrafiken und Sonderfarbenauszüge.', 1),

-- Product 3 (Swiss Poster)
(3, 'id_ID', 'Poster Pameran Swiss Grid Minimalis Modern Seri A1', 'Tata Letak Tipografi Swiss Modernis Standar ISO A1 Siap Cetak', 'Poster pameran berpresisi tinggi dengan grid modular Swiss 12-kolom, kalibrasi profil warna FOGRA39, dan hierarki tipografi Grotesk klasik.', 1),
(3, 'de_DE', 'Modernistisches Schweizer Raster Ausstellungsplakat A1 Serie', 'Druckfertiges ISO A1 Standard Schweizer Typografie-Layout', 'Präzises Ausstellungsposter mit klassischem 12-Spalten-Raster im Schweizer Stil. Streng typografische Ausrichtung nach ISO 12647-2 FOGRA39.', 1),

-- Product 9 (Transjakarta Bus Wrap)
(9, 'id_ID', 'Master Template Vektor Branding Bus Kota Transjakarta 12M', 'Template Branding Armada Transportasi Umum 12 Meter Komersial', 'Desain branding armada bus transit komersial 12 meter dengan batas presisi stiker kaca one-way vision, lengkungan roda, dan kaca darurat.', 1),

-- Product 14 (OmniGlyph Icons)
(14, 'ja_JP', 'OmniGlyph フィンテック＆バンキング アイコンシステム (1,200 SVG)', 'エンタープライズ金融およびモバイルバンキング向け 24px ベクターアイコンライブラリ', '一貫した1.5pxおよび2.0pxのストロークウェイトを持つ、24x24pxピクセルパーフェクトグリッド上に描かれた標準化された企業向け金融アイコンシステム。', 1);

-- 8. Coupon Redemption History Records
INSERT INTO `coupon_redemption_history` (
    `coupon_id`, `user_id`, `order_id`, `discount_captured_usd`, `redeemed_at`
) VALUES
(1, 11, 3, 71.80, '2026-02-10 16:45:00'),
(2, 10, 2, 50.00, '2025-09-20 09:12:00');
