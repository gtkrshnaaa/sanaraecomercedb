-- ==============================================================================
-- Sanara E-Commerce Query Suite: 01. Catalog Search & Filter Engine
-- Demonstrates: Full-Text Search, JSON Path Filtering, Generated Column Indexes
-- ==============================================================================

USE `sanara_ecommerce`;

-- Query 1: Full-Text Search for Large Format Outdoor Media
-- Target: "billboard baliho outdoor" matching title, subtitle, and search keywords
SELECT 
    p.`id`,
    p.`title`,
    p.`design_discipline`,
    p.`color_mode`,
    p.`resolution_dpi`,
    p.`base_standard_price`,
    cp.`studio_name` AS `creator_studio`,
    ROUND(MATCH(p.`title`, p.`subtitle`, p.`search_keywords`) AGAINST('billboard baliho outdoor' IN NATURAL LANGUAGE MODE), 4) AS `relevance_score`
FROM `products` p
JOIN `creator_profiles` cp ON cp.`id` = p.`creator_id`
WHERE MATCH(p.`title`, p.`subtitle`, p.`search_keywords`) AGAINST('billboard baliho outdoor' IN NATURAL LANGUAGE MODE)
  AND p.`status` = 'published'
ORDER BY `relevance_score` DESC;

-- Query 2: High-Performance Technical Pre-Press Filter
-- Requirement: Large Format Outdoor Assets printed in CMYK with bleed >= 50mm and vector layers
SELECT 
    p.`id`,
    p.`title`,
    p.`physical_dimensions`,
    p.`color_mode`,
    p.`resolution_dpi`,
    JSON_UNQUOTE(JSON_EXTRACT(p.`design_metadata`, '$.print_specs.bleed_mm')) AS `bleed_mm`,
    JSON_UNQUOTE(JSON_EXTRACT(p.`design_metadata`, '$.print_specs.spot_colors')) AS `spot_colors`,
    p.`base_standard_price`
FROM `products` p
WHERE p.`status` = 'published'
  AND p.`color_mode` = 'CMYK'                      -- Leverages STORED generated column index idx_prod_gen_colormode
  AND p.`is_vector` = 1                            -- Leverages STORED generated column index idx_prod_gen_vector
  AND JSON_EXTRACT(p.`design_metadata`, '$.print_specs.bleed_mm') >= 50
ORDER BY p.`base_standard_price` ASC;

-- Query 3: Software Compatibility & Color Palette JSON Filtering
-- Target: Products compatible with Figma or Blender containing specific hex color
SELECT 
    p.`id`,
    p.`title`,
    p.`design_discipline`,
    p.`design_metadata`->>'$.construction.color_palette' AS `color_palette`,
    pv.`file_format`,
    fn_format_bytes(pv.`file_size_bytes`) AS `formatted_file_size`
FROM `products` p
JOIN `product_variants` pv ON pv.`product_id` = p.`id` AND pv.`is_primary_deliverable` = 1
WHERE JSON_CONTAINS(p.`design_metadata`->'$.construction.color_palette', '"#FF5500"')
   OR JSON_CONTAINS(p.`design_metadata`->'$.construction.color_palette', '"#00FFA3"');
