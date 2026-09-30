-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 11: Analytical, Catalog & Financial Reporting Views
-- ==============================================================================

USE `sanara_ecommerce`;

DROP VIEW IF EXISTS `vw_daily_platform_revenue`;
DROP VIEW IF EXISTS `vw_license_entitlements_audit`;
DROP VIEW IF EXISTS `vw_creator_monthly_financial_summary`;
DROP VIEW IF EXISTS `vw_bestseller_print_templates`;
DROP VIEW IF EXISTS `vw_product_catalog_searchable`;

-- 1. Unified Searchable Catalog View
CREATE VIEW `vw_product_catalog_searchable` AS
SELECT 
    p.`id` AS `product_id`,
    p.`uuid` AS `product_uuid`,
    p.`title`,
    p.`slug`,
    p.`subtitle`,
    p.`design_discipline`,
    p.`status`,
    p.`base_standard_price`,
    p.`color_mode`,
    p.`resolution_dpi`,
    p.`is_vector`,
    p.`physical_dimensions`,
    p.`total_sales_count`,
    p.`total_downloads_count`,
    p.`average_rating`,
    p.`review_count`,
    p.`published_at`,
    c.`id` AS `category_id`,
    c.`name` AS `category_name`,
    c.`path` AS `category_path`,
    cp.`id` AS `creator_id`,
    cp.`studio_name` AS `creator_studio_name`,
    cp.`slug` AS `creator_slug`,
    cp.`is_verified_creator`,
    pv.`id` AS `primary_variant_id`,
    pv.`file_format` AS `primary_format`,
    pv.`file_size_bytes` AS `primary_size_bytes`,
    ppm.`price` AS `standard_license_price`,
    ppm.`effective_price` AS `effective_license_price`
FROM `products` p
JOIN `categories` c ON c.`id` = p.`category_id`
JOIN `creator_profiles` cp ON cp.`id` = p.`creator_id`
LEFT JOIN `product_variants` pv ON pv.`product_id` = p.`id` AND pv.`is_primary_deliverable` = 1
LEFT JOIN `product_pricing_matrix` ppm ON ppm.`product_id` = p.`id` AND ppm.`license_id` = 1 AND ppm.`is_active` = 1
WHERE p.`status` = 'published';

-- 2. Best-Selling Outdoor & Print Visual Assets
CREATE VIEW `vw_bestseller_print_templates` AS
SELECT 
    p.`id` AS `product_id`,
    p.`title`,
    p.`design_discipline`,
    c.`name` AS `category_name`,
    cp.`studio_name` AS `creator_studio`,
    p.`physical_dimensions`,
    p.`color_mode`,
    p.`resolution_dpi`,
    p.`total_sales_count`,
    p.`average_rating`,
    p.`base_standard_price`,
    (p.`total_sales_count` * p.`base_standard_price`) AS `gross_estimated_sales_usd`
FROM `products` p
JOIN `categories` c ON c.`id` = p.`category_id`
JOIN `creator_profiles` cp ON cp.`id` = p.`creator_id`
WHERE p.`design_discipline` IN ('outdoor_advertising', 'print_editorial')
  AND p.`status` = 'published'
ORDER BY p.`total_sales_count` DESC, p.`average_rating` DESC;

-- 3. Creator Financial & Royalty Performance Summary
CREATE VIEW `vw_creator_monthly_financial_summary` AS
SELECT 
    cp.`id` AS `creator_id`,
    cp.`studio_name`,
    cp.`country_code`,
    cp.`commission_rate`,
    cw.`available_balance`,
    cw.`pending_escrow_balance`,
    cw.`lifetime_withdrawn_total`,
    COUNT(DISTINCT oi.`id`) AS `total_items_sold`,
    COALESCE(SUM(oi.`unit_price`), 0.00) AS `gross_sales_volume_usd`,
    COALESCE(SUM(oi.`creator_royalty_amount`), 0.00) AS `total_royalties_earned_usd`,
    COALESCE(SUM(oi.`platform_fee_amount`), 0.00) AS `total_sanara_fees_generated_usd`
FROM `creator_profiles` cp
JOIN `creator_wallets` cw ON cw.`creator_id` = cp.`id`
LEFT JOIN `order_items` oi ON oi.`creator_id` = cp.`id` AND oi.`status` = 'active'
GROUP BY 
    cp.`id`, cp.`studio_name`, cp.`country_code`, cp.`commission_rate`,
    cw.`available_balance`, cw.`pending_escrow_balance`, cw.`lifetime_withdrawn_total`;

-- 4. Customer Entitlements and License Compliance Audit
CREATE VIEW `vw_license_entitlements_audit` AS
SELECT 
    ce.`id` AS `entitlement_id`,
    ce.`license_grant_key`,
    u.`email` AS `buyer_email`,
    u.`full_name` AS `buyer_name`,
    at.`team_name` AS `agency_team_name`,
    p.`title` AS `product_title`,
    p.`design_discipline`,
    pv.`name` AS `variant_name`,
    pv.`file_format`,
    l.`name` AS `license_tier`,
    l.`max_seats`,
    l.`max_print_impressions`,
    l.`merchandise_allowed`,
    ce.`entitlement_status`,
    ce.`granted_at`,
    COUNT(dl.`id`) AS `total_downloads_executed`
FROM `customer_entitlements` ce
JOIN `users` u ON u.`id` = ce.`buyer_id`
LEFT JOIN `agency_teams` at ON at.`id` = ce.`agency_team_id`
JOIN `products` p ON p.`id` = ce.`product_id`
JOIN `product_variants` pv ON pv.`id` = ce.`variant_id`
JOIN `licenses` l ON l.`id` = ce.`license_id`
LEFT JOIN `download_logs` dl ON dl.`entitlement_id` = ce.`id` AND dl.`delivery_status` = 'completed'
GROUP BY 
    ce.`id`, ce.`license_grant_key`, u.`email`, u.`full_name`, at.`team_name`,
    p.`title`, p.`design_discipline`, pv.`name`, pv.`file_format`,
    l.`name`, l.`max_seats`, l.`max_print_impressions`, l.`merchandise_allowed`,
    ce.`entitlement_status`, ce.`granted_at`;

-- 5. Daily Platform Financial Performance
CREATE VIEW `vw_daily_platform_revenue` AS
SELECT 
    DATE(o.`created_at`) AS `report_date`,
    o.`currency`,
    COUNT(DISTINCT o.`id`) AS `total_orders_count`,
    COUNT(oi.`id`) AS `total_units_sold`,
    SUM(o.`subtotal_amount`) AS `gross_merchandise_value`,
    SUM(o.`discount_amount`) AS `total_discounts_granted`,
    SUM(o.`tax_amount`) AS `total_taxes_collected`,
    SUM(o.`total_amount`) AS `net_captured_volume`,
    COALESCE(SUM(oi.`creator_royalty_amount`), 0.00) AS `creator_escrow_liability`,
    COALESCE(SUM(oi.`platform_fee_amount`), 0.00) AS `sanara_net_revenue`
FROM `orders` o
LEFT JOIN `order_items` oi ON oi.`order_id` = o.`id` AND oi.`status` = 'active'
WHERE o.`status` = 'completed'
GROUP BY DATE(o.`created_at`), o.`currency`
ORDER BY `report_date` DESC;
