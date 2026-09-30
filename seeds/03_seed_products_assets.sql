-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 03: Products, Print Profiles, Spot Plates, Variants, Pricing & i18n
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `product_tag_relations`;
TRUNCATE TABLE `product_preview_media`;
TRUNCATE TABLE `product_translations_i18n`;
TRUNCATE TABLE `product_asset_revisions`;
TRUNCATE TABLE `product_collaborators`;
TRUNCATE TABLE `product_pricing_matrix`;
TRUNCATE TABLE `product_variants`;
TRUNCATE TABLE `spot_color_plates`;
TRUNCATE TABLE `product_print_profiles`;
TRUNCATE TABLE `print_production_profiles`;
TRUNCATE TABLE `products`;
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

-- 2. Products Master Catalog (Products 1 to 14)
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
),
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

-- 3. Product to Print Production Profile Specifications
INSERT INTO `product_print_profiles` (
    `product_id`, `profile_id`, `min_bleed_mm`, `safe_margin_mm`, `resolution_ppi_recommended`, `prepress_notes`
) VALUES
(1, 3, 100.00, 150.00, 72, 'Reinforced grommet hem at 300mm intervals. High UV ink resistance profile.'),
(2, 3, 50.00, 80.00, 100, 'Four corner metal eyelets. Double stitched perimeter hem.'),
(3, 1, 3.00, 5.00, 300, 'Strict FOGRA39 color profile. Dry-trap print sequence CMYK.'),
(7, 5, 5.00, 8.00, 300, 'CAD-cut die strike line in separate 100% Magenta spot color plate.'),
(8, 4, 10.00, 15.00, 150, 'Bottom 200mm concealed inside roller cassette housing.'),
(9, 3, 50.00, 100.00, 100, 'Perforated one-way vision vinyl for side windows. UV cured outdoor inks.'),
(10, 3, 150.00, 200.00, 72, 'Reinforced 50mm perimeter hemming with internal nylon rope core.'),
(12, 1, 5.00, 8.00, 300, 'Hand screen-print sequence: Spot Black 6 C first, then Spot 805 C Neon Red overlay.'),
(13, 5, 3.00, 5.00, 300, 'Hot foil stamping plate on 300gsm uncoated Kraft stock.');

-- 4. Spot Color Plates & Finishing Channels
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

-- 5. Deliverable Variants (Variants 1 to 17)
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
(11, UUID(), 8, 1, 'Roll-Up Banner Vector Production Package [AI]', 'SKU-ROLLUP-08-AI', 'ai', 115343360, 'c81e728d9d4c2f636f067f89cc14862c1ecd77d84fe45d0891ec355c277fe32a', 'deliverables/prod_8/v1/rollup_85x200_ai.zip', 1, '1.0.0'),
(12, UUID(), 9, 1, 'Bus Wrap Illustrator Vector Master [.ai]', 'SKU-BUS-09-AI', 'ai', 142606336, 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90', 'deliverables/prod_9/v1/bus_wrap_12m.zip', 1, '1.0.0'),
(13, UUID(), 10, 1, 'Semarang 20x8m Unipole Master Vector [.ai]', 'SKU-SMPG-10-AI', 'ai', 198762496, 'b2c3d4e5f6a10718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f91', 'deliverables/prod_10/v1/semarang_unipole_20x8.zip', 1, '1.0.0'),
(14, UUID(), 11, 4, 'Shibuya Anamorphic Blender 4.1 Master Project', 'SKU-SHIB-11-BLEND', 'blend', 681574400, 'c3d4e5f6a1b20718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f92', 'deliverables/prod_11/v1/shibuya_anamorphic.zip', 1, '1.0.0'),
(15, UUID(), 12, 1, 'Berlin Techno Poster InDesign Master [.indd]', 'SKU-TECH-12-INDD', 'indd', 94371840, 'd4e5f6a1b2c30718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f93', 'deliverables/prod_12/v1/berlin_poster_a0.zip', 1, '1.0.0'),
(16, UUID(), 13, 1, 'Specialty Coffee Box CAD Die-Cut Vector [.ai]', 'SKU-COFF-13-AI', 'ai', 73400320, 'e5f6a1b2c3d40718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f94', 'deliverables/prod_13/v1/coffee_box_dieline.zip', 1, '1.0.0'),
(17, UUID(), 14, 3, 'OmniGlyph 1,200 Fintech Icons Figma Kit [.fig]', 'SKU-FIN-14-FIG', 'fig', 115343360, 'f6a1b2c3d4e50718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f95', 'deliverables/prod_14/v1/omniglyph_fintech_figma.fig', 1, '1.0.0');

-- 6. Product Pricing Matrix Across Licenses (Products 1 to 14)
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
(8, 3, 'USD', 219.00, NULL),
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

-- 7. Multi-Party Creator Collaborations & Split Royalties
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

-- 8. Semantic Asset Revisions
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

-- 9. Multi-Language Catalog Localization (i18n)
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

-- 10. Preview Showcase Media
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

-- 11. Product-Tag Relations
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
(8, 4), (8, 5), (8, 15),
-- Products 9 to 14
(9, 1), (9, 4), (9, 6),
(10, 1), (10, 3), (10, 4),
(11, 8), (11, 13),
(12, 4), (12, 5), (12, 11), (12, 12),
(13, 4), (13, 5), (13, 10),
(14, 6), (14, 7);
