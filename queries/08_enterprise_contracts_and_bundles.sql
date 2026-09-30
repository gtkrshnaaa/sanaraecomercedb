-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Query 08: Enterprise Contracts, Campaign Bundles & Multi-Cloud Storage Sync
-- Scenarios: B2B SLA monitoring, bundle financial margins, and CDN storage audit
-- ==============================================================================

USE `sanara_ecommerce`;

-- ------------------------------------------------------------------------------
-- Scenario A: Curated Campaign Design Bundle Price Breakdown & Margin Analysis
-- Objective: Calculate individual asset value vs discounted bundle package price
--            with hero asset flags and creator revenue attribution.
-- ------------------------------------------------------------------------------
SELECT 
    c.`id` AS `bundle_id`,
    c.`title` AS `bundle_title`,
    c.`campaign_theme`,
    c.`bundle_discount_rate` AS `discount_pct`,
    p.`id` AS `asset_id`,
    p.`title` AS `asset_title`,
    ci.`display_order`,
    ci.`is_hero_asset`,
    p.`base_standard_price` AS `individual_retail_usd`,
    ROUND(p.`base_standard_price` * (1.00 - (c.`bundle_discount_rate` / 100.00)), 2) AS `effective_bundle_item_price_usd`
FROM `collections` c
JOIN `collection_items` ci ON ci.`collection_id` = c.`id`
JOIN `products` p ON p.`id` = ci.`product_id`
WHERE c.`id` = 1
ORDER BY ci.`display_order`;

-- ------------------------------------------------------------------------------
-- Scenario B: Enterprise B2B Contract Consumption & SLA Quota Utilization
-- Objective: Monitor active agency contracts, licensed seats, category download
--            quotas, and real-time usage percentages.
-- ------------------------------------------------------------------------------
SELECT 
    ec.`contract_number`,
    at.`team_name` AS `agency_client`,
    ec.`tier` AS `contract_tier`,
    ec.`max_seats_licensed` AS `seat_count`,
    ec.`monthly_flat_fee_usd` AS `retained_monthly_retainer`,
    cat.`name` AS `licensed_category`,
    caa.`is_unlimited_cleared`,
    caa.`monthly_download_quota` AS `quota_limit`,
    caa.`current_cycle_consumed` AS `downloads_used`,
    CASE 
        WHEN caa.`is_unlimited_cleared` = 1 THEN 0.00
        ELSE ROUND((caa.`current_cycle_consumed` / caa.`monthly_download_quota`) * 100.0, 2)
    END AS `quota_consumed_pct`,
    DATEDIFF(ec.`active_until`, CURRENT_DATE) AS `days_until_renewal`
FROM `enterprise_contracts` ec
JOIN `agency_teams` at ON at.`id` = ec.`agency_team_id`
JOIN `contract_asset_allocations` caa ON caa.`contract_id` = ec.`id`
JOIN `categories` cat ON cat.`id` = caa.`category_id`
WHERE ec.`status` = 'active'
ORDER BY ec.`contract_number`, cat.`name`;

-- ------------------------------------------------------------------------------
-- Scenario C: Multi-Cloud Object Storage Replication & Edge Node Health Audit
-- Objective: Verify primary S3 and secondary Cloudflare R2 / Wasabi sync status,
--            latency metrics, and SHA-256 integrity verification flags.
-- ------------------------------------------------------------------------------
SELECT 
    pv.`sku`,
    p.`title` AS `product_title`,
    svn.`node_identifier`,
    svn.`provider` AS `cloud_vendor`,
    svn.`region_code`,
    svn.`health_status` AS `node_health`,
    svn.`latency_ms`,
    vsl.`replication_status`,
    vsl.`checksum_verified`,
    vsl.`last_verified_at`
FROM `product_variants` pv
JOIN `products` p ON p.`id` = pv.`product_id`
JOIN `variant_storage_locations` vsl ON vsl.`variant_id` = pv.`id`
JOIN `storage_vault_nodes` svn ON svn.`id` = vsl.`node_id`
ORDER BY pv.`id`, svn.`id`;
