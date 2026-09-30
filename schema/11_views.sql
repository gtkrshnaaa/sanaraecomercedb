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

-- 6. Print Production & Pre-Flight Specifications
DROP VIEW IF EXISTS `vw_print_production_preflight`;
CREATE VIEW `vw_print_production_preflight` AS
SELECT 
    p.`id` AS `product_id`,
    p.`title` AS `product_title`,
    p.`design_discipline`,
    ppp.`profile_name`,
    ppp.`icc_profile_tag`,
    ppp.`substrate_type`,
    ppp.`max_ink_density_tac`,
    ppp.`screen_ruling_lpi`,
    ppp.`recommended_viewing_distance_meters`,
    prod_pp.`min_bleed_mm`,
    prod_pp.`safe_margin_mm`,
    prod_pp.`resolution_ppi_recommended`,
    prod_pp.`prepress_notes`,
    COUNT(scp.`id`) AS `total_spot_color_plates`,
    COALESCE(GROUP_CONCAT(CONCAT(scp.`plate_name`, ' (', scp.`pantone_code`, ')') SEPARATOR '; '), 'None (Process CMYK Only)') AS `spot_color_channels`
FROM `products` p
JOIN `product_print_profiles` prod_pp ON prod_pp.`product_id` = p.`id`
JOIN `print_production_profiles` ppp ON ppp.`id` = prod_pp.`profile_id`
LEFT JOIN `spot_color_plates` scp ON scp.`product_id` = p.`id`
GROUP BY 
    p.`id`, p.`title`, p.`design_discipline`, ppp.`profile_name`, ppp.`icc_profile_tag`,
    ppp.`substrate_type`, ppp.`max_ink_density_tac`, ppp.`screen_ruling_lpi`,
    ppp.`recommended_viewing_distance_meters`, prod_pp.`min_bleed_mm`,
    prod_pp.`safe_margin_mm`, prod_pp.`resolution_ppi_recommended`, prod_pp.`prepress_notes`;

-- 7. Curated Campaign Bundle & Package Pricing Summary
DROP VIEW IF EXISTS `vw_campaign_bundle_summary`;
CREATE VIEW `vw_campaign_bundle_summary` AS
SELECT 
    c.`id` AS `collection_id`,
    c.`title` AS `bundle_title`,
    c.`slug` AS `bundle_slug`,
    c.`campaign_theme`,
    c.`bundle_discount_rate`,
    cp.`studio_name` AS `curator_studio`,
    COUNT(ci.`product_id`) AS `total_assets_included`,
    SUM(p.`base_standard_price`) AS `individual_items_total_usd`,
    ROUND(SUM(p.`base_standard_price`) * (1.00 - (c.`bundle_discount_rate` / 100.00)), 2) AS `discounted_bundle_price_usd`,
    ROUND(SUM(p.`base_standard_price`) * (c.`bundle_discount_rate` / 100.00), 2) AS `buyer_total_savings_usd`
FROM `collections` c
LEFT JOIN `creator_profiles` cp ON cp.`id` = c.`curator_creator_id`
JOIN `collection_items` ci ON ci.`collection_id` = c.`id`
JOIN `products` p ON p.`id` = ci.`product_id`
WHERE c.`is_active` = 1
GROUP BY 
    c.`id`, c.`title`, c.`slug`, c.`campaign_theme`, c.`bundle_discount_rate`, cp.`studio_name`;

-- 8. Multi-Party Creator Collaborative Royalties
DROP VIEW IF EXISTS `vw_collaborative_royalty_breakdown`;
CREATE VIEW `vw_collaborative_royalty_breakdown` AS
SELECT 
    p.`id` AS `product_id`,
    p.`title` AS `product_title`,
    lead_cp.`studio_name` AS `primary_studio`,
    collab_cp.`studio_name` AS `collaborator_studio`,
    collab.`role_in_production`,
    collab.`royalty_split_percentage`,
    collab.`is_primary_lead`,
    ROUND((p.`base_standard_price` * (lead_cp.`commission_rate` / 100.00)) * (collab.`royalty_split_percentage` / 100.00), 2) AS `standard_sale_royalty_usd`
FROM `products` p
JOIN `creator_profiles` lead_cp ON lead_cp.`id` = p.`creator_id`
JOIN `product_collaborators` collab ON collab.`product_id` = p.`id`
JOIN `creator_profiles` collab_cp ON collab_cp.`id` = collab.`creator_id`
ORDER BY p.`id`, collab.`is_primary_lead` DESC, collab.`royalty_split_percentage` DESC;

-- 9. Enterprise B2B Agency Contract Utilization & Quotas
DROP VIEW IF EXISTS `vw_enterprise_contract_utilization`;
CREATE VIEW `vw_enterprise_contract_utilization` AS
SELECT 
    ec.`id` AS `contract_id`,
    ec.`contract_number`,
    ec.`tier`,
    at.`team_name` AS `agency_client_name`,
    ec.`max_seats_licensed`,
    ec.`monthly_flat_fee_usd`,
    ec.`active_from`,
    ec.`active_until`,
    ec.`status` AS `contract_status`,
    cat.`name` AS `allocated_category`,
    caa.`is_unlimited_cleared`,
    caa.`monthly_download_quota`,
    caa.`current_cycle_consumed`,
    CASE 
        WHEN caa.`is_unlimited_cleared` = 1 THEN 'Unlimited (Enterprise SLA)'
        ELSE CONCAT(ROUND((caa.`current_cycle_consumed` / caa.`monthly_download_quota`) * 100.0, 1), '%')
    END AS `quota_utilization_pct`
FROM `enterprise_contracts` ec
JOIN `agency_teams` at ON at.`id` = ec.`agency_team_id`
JOIN `contract_asset_allocations` caa ON caa.`contract_id` = ec.`id`
JOIN `categories` cat ON cat.`id` = caa.`category_id`;
