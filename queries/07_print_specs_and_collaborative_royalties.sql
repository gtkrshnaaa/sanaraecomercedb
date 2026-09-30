-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Query 07: Pre-Press Technical Proofing & Multi-Creator Royalty Calculations
-- Scenarios: Pre-flight print validation and multi-artist collaboration payouts
-- ==============================================================================

USE `sanara_ecommerce`;

-- ------------------------------------------------------------------------------
-- Scenario A: Complete Industrial Pre-Press & Print Specification Dossier
-- Objective: Retrieve full print production specs, substrate TAC, bleed zones,
--            and spot color separation channels for billboard & packaging products.
-- ------------------------------------------------------------------------------
SELECT 
    p.`id` AS `product_id`,
    p.`title` AS `product_name`,
    p.`design_discipline`,
    ppp.`profile_name` AS `print_standard_profile`,
    ppp.`icc_profile_tag`,
    ppp.`substrate_type`,
    ppp.`max_ink_density_tac` AS `tac_limit_pct`,
    ppp.`screen_ruling_lpi`,
    prod_pp.`min_bleed_mm`,
    prod_pp.`safe_margin_mm`,
    prod_pp.`resolution_ppi_recommended`,
    prod_pp.`prepress_notes`,
    scp.`plate_name` AS `spot_plate`,
    scp.`pantone_code`,
    scp.`color_role`,
    CONCAT('C:', scp.`cmyk_fallback_c`, ' M:', scp.`cmyk_fallback_m`, ' Y:', scp.`cmyk_fallback_y`, ' K:', scp.`cmyk_fallback_k`) AS `cmyk_process_fallback`
FROM `products` p
JOIN `product_print_profiles` prod_pp ON prod_pp.`product_id` = p.`id`
JOIN `print_production_profiles` ppp ON ppp.`id` = prod_pp.`profile_id`
LEFT JOIN `spot_color_plates` scp ON scp.`product_id` = p.`id`
WHERE p.`design_discipline` IN ('outdoor_advertising', 'print_editorial')
ORDER BY p.`id`, scp.`id`;

-- ------------------------------------------------------------------------------
-- Scenario B: Multi-Creator Royalty Distribution for Collaborative Master Assets
-- Objective: Simulate an enterprise license sale ($499.00) on a collaborative
--            asset and calculate exact revenue shares across all creative contributors.
-- ------------------------------------------------------------------------------
SELECT 
    p.`id` AS `product_id`,
    p.`title` AS `master_asset_title`,
    499.00 AS `simulated_gross_sale_usd`,
    lead_cp.`studio_name` AS `lead_studio`,
    lead_cp.`commission_rate` AS `studio_contract_rate_pct`,
    ROUND(499.00 * (lead_cp.`commission_rate` / 100.00), 2) AS `total_creator_pool_usd`,
    ROUND(499.00 * ((100.00 - lead_cp.`commission_rate`) / 100.00), 2) AS `sanara_platform_fee_usd`,
    collab_cp.`studio_name` AS `contributing_artist`,
    collab.`role_in_production`,
    collab.`royalty_split_percentage`,
    collab.`is_primary_lead`,
    ROUND((499.00 * (lead_cp.`commission_rate` / 100.00)) * (collab.`royalty_split_percentage` / 100.00), 2) AS `collaborator_net_payout_usd`
FROM `products` p
JOIN `creator_profiles` lead_cp ON lead_cp.`id` = p.`creator_id`
JOIN `product_collaborators` collab ON collab.`product_id` = p.`id`
JOIN `creator_profiles` collab_cp ON collab_cp.`id` = collab.`creator_id`
WHERE p.`id` = 1
ORDER BY collab.`is_primary_lead` DESC, collab.`royalty_split_percentage` DESC;
