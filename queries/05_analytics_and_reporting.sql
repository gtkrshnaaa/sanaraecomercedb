-- ==============================================================================
-- Sanara E-Commerce Query Suite: 05. Advanced Platform Analytics & Insights
-- Demonstrates: Hierarchy Traversal, Cohort Aggregation, Multi-Table Analytics
-- ==============================================================================

USE `sanara_ecommerce`;

-- Report 1: Revenue Breakdown Across Hierarchical Taxonomy Branches
SELECT 
    parent_cat.`name` AS `root_category`,
    child_cat.`name` AS `sub_category`,
    COUNT(DISTINCT p.`id`) AS `total_catalog_products`,
    COUNT(oi.`id`) AS `units_sold`,
    COALESCE(SUM(oi.`unit_price`), 0.00) AS `gross_category_revenue_usd`,
    COALESCE(SUM(oi.`creator_royalty_amount`), 0.00) AS `creator_earnings_usd`,
    COALESCE(SUM(oi.`platform_fee_amount`), 0.00) AS `sanara_margin_usd`
FROM `categories` child_cat
LEFT JOIN `categories` parent_cat ON parent_cat.`id` = child_cat.`parent_id`
LEFT JOIN `products` p ON p.`category_id` = child_cat.`id`
LEFT JOIN `order_items` oi ON oi.`product_id` = p.`id` AND oi.`status` = 'active'
WHERE child_cat.`depth` = 2
GROUP BY parent_cat.`name`, child_cat.`name`
ORDER BY `gross_category_revenue_usd` DESC;

-- Report 2: Outdoor Advertising Market Dominance (Billboards vs Banners)
SELECT 
    p.`title` AS `outdoor_asset`,
    p.`physical_dimensions`,
    p.`color_mode`,
    p.`resolution_dpi`,
    p.`total_sales_count`,
    cp.`studio_name` AS `design_studio`,
    SUM(oi.`unit_price`) AS `total_gross_revenue_usd`
FROM `products` p
JOIN `creator_profiles` cp ON cp.`id` = p.`creator_id`
JOIN `order_items` oi ON oi.`product_id` = p.`id`
WHERE p.`design_discipline` = 'outdoor_advertising'
GROUP BY p.`id`, p.`title`, p.`physical_dimensions`, p.`color_mode`, p.`resolution_dpi`, p.`total_sales_count`, cp.`studio_name`
ORDER BY `total_gross_revenue_usd` DESC;

-- Report 3: License Tier Adoption & Average Revenue per Seat
SELECT 
    l.`name` AS `license_tier`,
    l.`code`,
    COUNT(oi.`id`) AS `licenses_sold_count`,
    SUM(oi.`unit_price`) AS `total_license_revenue_usd`,
    ROUND(AVG(oi.`unit_price`), 2) AS `average_selling_price_usd`
FROM `licenses` l
LEFT JOIN `order_items` oi ON oi.`license_id` = l.`id`
GROUP BY l.`id`, l.`name`, l.`code`
ORDER BY `total_license_revenue_usd` DESC;
