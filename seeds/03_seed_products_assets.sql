-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 03: Products, JSON Metadata, Variants, Pricing Matrix & Media Previews
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `product_tag_relations`;
TRUNCATE TABLE `product_preview_media`;
TRUNCATE TABLE `product_pricing_matrix`;
TRUNCATE TABLE `product_variants`;
TRUNCATE TABLE `products`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Products Master Catalog
INSERT INTO `products` (
    `id`, `uuid`, `creator_id`, `category_id`, `title`, `slug`, `subtitle`, `description`,
    `design_discipline`, `status`, `is_featured`, `is_exclusive_sanara`, `base_standard_price`,
    `total_sales_count`, `average_rating`, `review_count`, `search_keywords`, `design_metadata`, `published_at`
) VALUES
-- Product 1: Highway Billboard / Baliho 14x4m
(
    1, UUID(), 1, 2,
    'Megacity Highway Billboard 14x4m Ultra Print Suite',
    'megacity-highway-billboard-14x4m-ultra-print-suite',
    'Large Format 14x4 Meter Outdoor Unipole & Highway Billboard Vector Template',
    'Industrial-grade outdoor billboard template engineered specifically for large-scale highway printing. Features precise mechanical bleed safety zones, scalable vector artwork, spot color separations, and high-impact typographic hierarchy visible from 150 meters away.',
    'outdoor_advertising', 'published', 1, 1, 89.00, 24, 4.96, 18,
    'baliho outdoor billboard highway large format cmyk unipole advertising billboard 14x4',
    '{
        "dimensions": {"width": 14000, "height": 4000, "unit": "mm", "aspect_ratio": "14:4"},
        "print_specs": {
            "dpi": 72,
            "color_space": "CMYK",
            "bleed_mm": 100,
            "safety_margin_mm": 150,
            "spot_colors": ["Pantone 021 C", "Process Cyan"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 48,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#FF5500", "#002244", "#FFFFFF", "#F4F4F4"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2022", "extension": "AI"},
            {"software": "CorelDRAW", "min_version": "2021", "extension": "CDR"},
            {"software": "Adobe Photoshop", "min_version": "CC 2022", "extension": "PSD"}
        ]
    }',
    '2025-01-12 10:00:00'
),

-- Product 2: Street Vinyl Banner / Spanduk 3x1m
(
    2, UUID(), 1, 3,
    'Commercial Street Spanduk Vinyl Banner 3x1m Grand Opening Series',
    'commercial-street-spanduk-vinyl-banner-3x1m',
    'Outdoor Heavy-Duty Flex Vinyl Banner with Brass Grommet Margin Guides',
    'Complete horizontal street banner template formatted for heavy flex vinyl printing (440-510 gsm). Includes automated brass eyelet/grommet alignment markers every 50cm and reinforced hem allowance for outdoor wind resistance.',
    'outdoor_advertising', 'published', 1, 0, 35.00, 48, 4.90, 32,
    'spanduk vinyl banner street outdoor promo grand opening grommet cmyk 3x1',
    '{
        "dimensions": {"width": 3000, "height": 1000, "unit": "mm", "aspect_ratio": "3:1"},
        "print_specs": {
            "dpi": 150,
            "color_space": "CMYK",
            "bleed_mm": 50,
            "safety_margin_mm": 80,
            "spot_colors": []
        },
        "construction": {
            "is_vector": true,
            "layer_count": 28,
            "has_smart_objects": false,
            "font_embedded": true,
            "color_palette": ["#E63946", "#1D3557", "#F1FAEE", "#A8DADC"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CS6", "extension": "AI"},
            {"software": "CorelDRAW", "min_version": "X7", "extension": "CDR"}
        ]
    }',
    '2025-01-18 14:00:00'
),

-- Product 3: Swiss Exhibition Poster A1
(
    3, UUID(), 3, 7,
    'A1 Swiss Typographic Exhibition Poster Grid System',
    'a1-swiss-typographic-exhibition-poster-grid',
    'Pure International Typographic Style (ITS) 594x841mm Exhibition Posters',
    'Strict 12-column Swiss modernist modular layout engineered for museum exhibitions, cultural festivals, and architectural retrospectives. Calibrated strictly for offset lithographic press printing with ISO A1 mechanical tolerances.',
    'print_editorial', 'published', 1, 1, 45.00, 35, 4.94, 21,
    'swiss poster bauhaus typography grid museum a1 print ready cmyk offset minimal',
    '{
        "dimensions": {"width": 594, "height": 841, "unit": "mm", "aspect_ratio": "A1"},
        "print_specs": {
            "dpi": 300,
            "color_space": "CMYK",
            "bleed_mm": 3,
            "safety_margin_mm": 12,
            "spot_colors": ["Pantone Black 6 C", "Pantone Warm Red C"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 34,
            "has_smart_objects": false,
            "font_embedded": false,
            "color_palette": ["#111111", "#FF2200", "#F5F3E9"]
        },
        "software_compatibility": [
            {"software": "Adobe InDesign", "min_version": "CC 2023", "extension": "INDD"},
            {"software": "Adobe Illustrator", "min_version": "CC 2023", "extension": "AI"}
        ]
    }',
    '2025-02-02 08:30:00'
),

-- Product 4: 3D Character Rig Cyber Samurai
(
    4, UUID(), 2, 14,
    'Cyber-Samurai 3D Low-Poly Character Rig & Animation Suite',
    'cyber-samurai-3d-character-rig-animation-suite',
    'Fully Rigged Blender 4.x Character Avatar with 48 Facial Shape Keys',
    'Production-ready 3D character asset featuring clean quad topology, inverse kinematics (IK/FK switches), PBR metallic-roughness procedural shaders, and 12 pre-baked motion capture action cycles.',
    'illustration_3d', 'published', 1, 1, 120.00, 19, 4.95, 14,
    '3d character rig blender anime cyberpunk samurai low poly animation fbx mesh avatar',
    '{
        "dimensions": {"width": 3840, "height": 2160, "unit": "px", "aspect_ratio": "16:9"},
        "print_specs": {
            "dpi": 72,
            "color_space": "RGB",
            "bleed_mm": 0,
            "safety_margin_mm": 0,
            "spot_colors": []
        },
        "construction": {
            "is_vector": false,
            "layer_count": 12,
            "has_smart_objects": false,
            "has_3d_rig": true,
            "has_animation": true,
            "poly_count": 28400,
            "color_palette": ["#0F1016", "#00FFA3", "#FF0055", "#4D5382"]
        },
        "software_compatibility": [
            {"software": "Blender 3D", "min_version": "4.1", "extension": "BLEND"},
            {"software": "Autodesk FBX", "min_version": "2020", "extension": "FBX"}
        ]
    }',
    '2025-02-10 11:00:00'
),

-- Product 5: Corporate Brand Identity Stationery Kit
(
    5, UUID(), 4, 11,
    'Nexus Modular Corporate Brand Identity & Stationery Toolkit',
    'nexus-modular-corporate-brand-identity-stationery',
    'Comprehensive B2B Corporate Identity Suite across 18 Business Collateral Formats',
    'Multi-format corporate brand system including business cards, letterheads (A4 + US Letter), folders, envelopes, invoices, lanyard badges, and corporate presentation templates with standardized design tokens.',
    'branding_identity', 'published', 0, 0, 65.00, 29, 4.88, 16,
    'branding stationery corporate identity business card invoice letterhead figma indesign',
    '{
        "dimensions": {"width": 210, "height": 297, "unit": "mm", "aspect_ratio": "A4"},
        "print_specs": {
            "dpi": 300,
            "color_space": "CMYK",
            "bleed_mm": 3,
            "safety_margin_mm": 10,
            "spot_colors": ["Pantone 286 C"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 72,
            "has_smart_objects": true,
            "font_embedded": true,
            "color_palette": ["#0B2545", "#134074", "#8DA9C4", "#EEF4F8"]
        },
        "software_compatibility": [
            {"software": "Figma", "min_version": "Latest", "extension": "FIG"},
            {"software": "Adobe InDesign", "min_version": "CC 2024", "extension": "INDD"},
            {"software": "Adobe Illustrator", "min_version": "CC 2024", "extension": "AI"}
        ]
    }',
    '2025-02-16 15:45:00'
),

-- Product 6: OmniGlyph Vector Icon Pack
(
    6, UUID(), 5, 18,
    'OmniGlyph 2,800+ Ultimate Vector Icon System',
    'omniglyph-2800-ultimate-vector-icon-system',
    'Extensive 24px Grid Vector Icon Library in 3 Precise Visual Weights',
    'Hand-crafted icon library organized across 32 logical semantic domains (Fintech, Healthcare, DevTools, E-Commerce, Navigation). Rendered in Line (2px stroke), Solid (fill), and Duotone styles with matching Figma component tokens.',
    'typography_iconography', 'published', 1, 0, 55.00, 64, 4.97, 42,
    'icon pack vector icons svg figma duotone stroke solid symbols glyphs 24px',
    '{
        "dimensions": {"width": 24, "height": 24, "unit": "px", "aspect_ratio": "1:1"},
        "print_specs": {
            "dpi": 72,
            "color_space": "RGB",
            "bleed_mm": 0,
            "safety_margin_mm": 2,
            "spot_colors": []
        },
        "construction": {
            "is_vector": true,
            "layer_count": 1,
            "icon_count": 2840,
            "color_palette": ["#000000", "#555555", "#A0A0A0"]
        },
        "software_compatibility": [
            {"software": "Figma", "min_version": "Latest", "extension": "FIG"},
            {"software": "SVG Master", "min_version": "1.1", "extension": "SVG"}
        ]
    }',
    '2025-02-22 09:15:00'
),

-- Product 7: Packaging Die-Line & Box Mockup
(
    7, UUID(), 3, 8,
    'Luxury Cosmetic Folding Carton Structural Packaging Die-Line',
    'luxury-cosmetic-folding-carton-packaging-dieline',
    'Production Ready Vector Folding Box Die-Cut with Foil Stamp & Crease Guides',
    'Precision engineered folding carton packaging die-line adhering to ECMA industrial standards. Features designated cutting lines, creasing rules, glue flaps, tuck-in tabs, and spot varnish mask layers.',
    'print_editorial', 'published', 0, 1, 49.00, 15, 4.92, 11,
    'packaging die-cut box dieline packaging luxury cosmetics foil emboss cmyk offset',
    '{
        "dimensions": {"width": 180, "height": 120, "unit": "mm", "aspect_ratio": "Custom"},
        "print_specs": {
            "dpi": 300,
            "color_space": "CMYK",
            "bleed_mm": 5,
            "safety_margin_mm": 6,
            "spot_colors": ["Pantone 871 C Gold", "Spot Gloss UV"]
        },
        "construction": {
            "is_vector": true,
            "layer_count": 22,
            "has_smart_objects": true,
            "color_palette": ["#1A1A1A", "#D4AF37", "#FFFFFF"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2023", "extension": "AI"},
            {"software": "Adobe Photoshop", "min_version": "CC 2023", "extension": "PSD"}
        ]
    }',
    '2025-03-01 13:00:00'
),

-- Product 8: Roll-Up Banner 85x200cm
(
    8, UUID(), 1, 4,
    'Retractable Roll-Up Exhibition Banner Stand 85x200cm Conference Pack',
    'retractable-rollup-exhibition-banner-85x200cm',
    'High-Resolution Trade Show Retractable Banner with Base Tape Margin Margins',
    'Streamlined roll-up banner layout tailored for corporate trade shows, university symposiums, and technology summits. Includes bottom 15cm mechanical feed margin for aluminum cassette insertion.',
    'outdoor_advertising', 'published', 0, 0, 39.00, 31, 4.87, 19,
    'roll-up banner x-banner exhibition display trade show conference 85x200 cmyk print',
    '{
        "dimensions": {"width": 850, "height": 2000, "unit": "mm", "aspect_ratio": "85:200"},
        "print_specs": {
            "dpi": 150,
            "color_space": "CMYK",
            "bleed_mm": 10,
            "safety_margin_mm": 50,
            "spot_colors": []
        },
        "construction": {
            "is_vector": true,
            "layer_count": 18,
            "color_palette": ["#004E92", "#000428", "#FFFFFF", "#FFD700"]
        },
        "software_compatibility": [
            {"software": "Adobe Illustrator", "min_version": "CC 2022", "extension": "AI"},
            {"software": "Adobe Photoshop", "min_version": "CC 2022", "extension": "PSD"}
        ]
    }',
    '2025-03-08 17:30:00'
);

-- 2. Deliverable Variants & Download Source Archives
INSERT INTO `product_variants` (
    `id`, `uuid`, `product_id`, `software_id`, `name`, `sku`, `file_format`,
    `file_size_bytes`, `archive_checksum_sha256`, `storage_s3_key`, `is_primary_deliverable`, `version_label`
) VALUES
-- Product 1 Variants (Billboard)
(1, UUID(), 1, 1, 'Master Vector Bundle [AI + EPS + Press PDF]', 'SKU-BALIHO-01-AI', 'ai', 398458880, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'deliverables/prod_1/v1/baliho_14x4m_ai_master.zip', 1, '1.2.0'),
(2, UUID(), 1, 7, 'CorelDRAW Large Format Package [CDR]', 'SKU-BALIHO-01-CDR', 'cdr', 314572800, 'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e', 'deliverables/prod_1/v1/baliho_14x4m_cdr.zip', 0, '1.2.0'),

-- Product 2 Variants (Spanduk)
(3, UUID(), 2, 1, 'Vector Street Spanduk Kit [AI + EPS]', 'SKU-SPANDUK-02-AI', 'ai', 184549376, 'bf58c72a1619cee4a0b93d1d5948b7838b752f5bf7ccfa73144e00d9ced97844', 'deliverables/prod_2/v1/spanduk_3x1m_vector.zip', 1, '1.0.0'),

-- Product 3 Variants (Swiss Poster)
(4, UUID(), 3, 5, 'InDesign Editorial Grid Package [INDD + IDML]', 'SKU-POSTER-03-INDD', 'indd', 125829120, '4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a', 'deliverables/prod_3/v1/swiss_a1_indesign.zip', 1, '2.0.0'),
(5, UUID(), 3, 1, 'Illustrator Vector Poster File [AI]', 'SKU-POSTER-03-AI', 'ai', 89128960, 'ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d', 'deliverables/prod_3/v1/swiss_a1_ai.zip', 0, '2.0.0'),

-- Product 4 Variants (Cyber Samurai 3D)
(6, UUID(), 4, 4, 'Blender 4.x Rigged Character Project [.blend]', 'SKU-CHAR3D-04-BLEND', 'blend', 471859200, '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', 'deliverables/prod_4/v1/cyber_samurai_blender.zip', 1, '1.1.0'),

-- Product 5 Variants (Brand Identity)
(7, UUID(), 5, 3, 'Figma Design Tokens & Collateral Kit [.fig]', 'SKU-BRAND-05-FIG', 'fig', 68157440, '8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4', 'deliverables/prod_5/v1/nexus_brand_figma.fig', 1, '1.0.0'),

-- Product 6 Variants (Icon Pack)
(8, UUID(), 6, 3, 'OmniGlyph Master Figma Component File', 'SKU-ICONS-06-FIG', 'fig', 146800640, 'eccbc87e4b5ce2fe28308fd9f2a7baf3a87ff9838f2e19dcf8e27182f4f0cb1f', 'deliverables/prod_6/v1/omniglyph_icons_figma.fig', 1, '3.2.0'),
(9, UUID(), 6, NULL, 'Clean Raw SVG Master Archive (2,840 Files)', 'SKU-ICONS-06-SVG', 'svg', 52428800, 'c81e728d9d4c2f636f067f89cc14862c1ecd77d84fe45d0891ec355c277fe32a', 'deliverables/prod_6/v1/omniglyph_svg_bundle.zip', 0, '3.2.0'),

-- Product 7 Variants (Packaging)
(10, UUID(), 7, 1, 'Packaging Box Die-Cut Production Vector [AI]', 'SKU-PACK-07-AI', 'ai', 78643200, 'c4ca4238a0b923820dcc509a6f75849b3a87ff9838f2e19dcf8e27182f4f0cb1', 'deliverables/prod_7/v1/cosmetic_box_dieline.zip', 1, '1.0.0'),

-- Product 8 Variants (Rollup Banner)
(11, UUID(), 8, 1, 'Roll-Up Banner Vector Production Package [AI]', 'SKU-ROLLUP-08-AI', 'ai', 115343360, 'c81e728d9d4c2f636f067f89cc14862c1ecd77d84fe45d0891ec355c277fe32a', 'deliverables/prod_8/v1/rollup_85x200_ai.zip', 1, '1.0.0');

-- 3. Product Pricing Matrix Across Licenses
INSERT INTO `product_pricing_matrix` (`product_id`, `license_id`, `currency`, `price`, `sale_price`) VALUES
-- Product 1: Highway Billboard
(1, 1, 'USD', 89.00, NULL),
(1, 2, 'USD', 189.00, 169.00),
(1, 3, 'USD', 499.00, NULL),

-- Product 2: Spanduk
(2, 1, 'USD', 35.00, 29.00),
(2, 2, 'USD', 79.00, NULL),
(2, 3, 'USD', 199.00, NULL),

-- Product 3: Swiss Poster
(3, 1, 'USD', 45.00, NULL),
(3, 2, 'USD', 99.00, NULL),
(3, 3, 'USD', 249.00, NULL),

-- Product 4: Cyber Samurai 3D
(4, 1, 'USD', 120.00, NULL),
(4, 2, 'USD', 260.00, 239.00),
(4, 3, 'USD', 650.00, NULL),

-- Product 5: Brand Identity
(5, 1, 'USD', 65.00, NULL),
(5, 2, 'USD', 145.00, NULL),
(5, 3, 'USD', 350.00, NULL),

-- Product 6: Icon Pack
(6, 1, 'USD', 55.00, 45.00),
(6, 2, 'USD', 129.00, NULL),
(6, 3, 'USD', 299.00, NULL),

-- Product 7: Packaging Box
(7, 1, 'USD', 49.00, NULL),
(7, 2, 'USD', 119.00, NULL),
(7, 3, 'USD', 279.00, NULL),

-- Product 8: Rollup Banner
(8, 1, 'USD', 39.00, NULL),
(8, 2, 'USD', 89.00, NULL),
(8, 3, 'USD', 219.00, NULL);

-- 4. Preview Showcase Media
INSERT INTO `product_preview_media` (
    `product_id`, `media_type`, `storage_key`, `cdn_url`, `width_px`, `height_px`, `file_size_bytes`, `display_order`
) VALUES
(1, 'cover_thumbnail', 'previews/prod_1/cover.webp', 'https://cdn.sanara.design/previews/prod_1/cover.webp', 1920, 1080, 245000, 1),
(1, 'mockup_scene', 'previews/prod_1/mockup_highway.webp', 'https://cdn.sanara.design/previews/prod_1/mockup_highway.webp', 1920, 1080, 312000, 2),
(2, 'cover_thumbnail', 'previews/prod_2/cover.webp', 'https://cdn.sanara.design/previews/prod_2/cover.webp', 1920, 1080, 189000, 1),
(3, 'cover_thumbnail', 'previews/prod_3/cover.webp', 'https://cdn.sanara.design/previews/prod_3/cover.webp', 1920, 1080, 198000, 1),
(4, 'cover_thumbnail', 'previews/prod_4/cover.webp', 'https://cdn.sanara.design/previews/prod_4/cover.webp', 1920, 1080, 340000, 1),
(5, 'cover_thumbnail', 'previews/prod_5/cover.webp', 'https://cdn.sanara.design/previews/prod_5/cover.webp', 1920, 1080, 210000, 1),
(6, 'cover_thumbnail', 'previews/prod_6/cover.webp', 'https://cdn.sanara.design/previews/prod_6/cover.webp', 1920, 1080, 165000, 1),
(7, 'cover_thumbnail', 'previews/prod_7/cover.webp', 'https://cdn.sanara.design/previews/prod_7/cover.webp', 1920, 1080, 225000, 1),
(8, 'cover_thumbnail', 'previews/prod_8/cover.webp', 'https://cdn.sanara.design/previews/prod_8/cover.webp', 1920, 1080, 195000, 1);

-- 5. Product-Tag Relations
INSERT INTO `product_tag_relations` (`product_id`, `tag_id`) VALUES
-- Product 1: Billboard
(1, 1), (1, 3), (1, 4), (1, 6),
-- Product 2: Spanduk
(2, 2), (2, 4), (2, 6),
-- Product 3: Swiss Poster
(3, 4), (3, 5), (3, 11), (3, 12),
-- Product 4: Cyber Samurai
(4, 8), (4, 9), (4, 13),
-- Product 5: Brand Identity
(5, 4), (5, 5), (5, 7), (5, 14),
-- Product 6: Icon Pack
(6, 6), (6, 7),
-- Product 7: Packaging Box
(7, 4), (7, 5), (7, 10),
-- Product 8: Rollup Banner
(8, 4), (8, 5), (8, 15);
