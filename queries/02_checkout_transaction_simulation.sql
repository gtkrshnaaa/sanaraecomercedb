-- ==============================================================================
-- Sanara E-Commerce Query Suite: 02. ACID Checkout Transaction Simulation
-- Demonstrates: Stored Procedure Invocations, Transaction Atomic Boundaries
-- ==============================================================================

USE `sanara_ecommerce`;

-- Prepare User Session Variables
SET @buyer_user_id = 9; -- Reza Studio
SET @currency = 'USD';
SET @payment_method = 'stripe';
SET @payment_ref = 'ch_live_simulated_test_trx_9901';

-- Multi-item Cart Payload:
-- Item 1: Product 3 (Swiss Poster) Variant 4 with Extended License (License ID 2)
-- Item 2: Product 8 (Rollup Banner) Variant 11 with Standard License (License ID 1)
SET @cart_json = '[
    {"variant_id": 4, "license_id": 2},
    {"variant_id": 11, "license_id": 1}
]';

SET @out_order_id = 0;
SET @out_order_number = '';

-- Execute Atomic Stored Procedure
CALL sp_checkout_order(
    @buyer_user_id,
    @currency,
    @payment_method,
    @payment_ref,
    @cart_json,
    @out_order_id,
    @out_order_number
);

-- Inspect Generated Order
SELECT 
    `id` AS `order_id`,
    `order_number`,
    `buyer_id`,
    `subtotal_amount`,
    `total_amount`,
    `status`,
    `paid_at`
FROM `orders`
WHERE `id` = @out_order_id;

-- Inspect Generated Line Items, License Keys & Royalties
SELECT 
    oi.`id` AS `item_id`,
    oi.`order_id`,
    p.`title` AS `product_title`,
    l.`name` AS `license_tier`,
    oi.`unit_price`,
    oi.`creator_royalty_percentage`,
    oi.`creator_royalty_amount`,
    oi.`platform_fee_amount`,
    oi.`license_grant_key`
FROM `order_items` oi
JOIN `products` p ON p.`id` = oi.`product_id`
JOIN `licenses` l ON l.`id` = oi.`license_id`
WHERE oi.`order_id` = @out_order_id;

-- Verify Customer Entitlements Created
SELECT 
    ce.`id` AS `entitlement_id`,
    ce.`buyer_id`,
    p.`title` AS `product_title`,
    ce.`license_grant_key`,
    ce.`entitlement_status`
FROM `customer_entitlements` ce
JOIN `products` p ON p.`id` = ce.`product_id`
WHERE ce.`order_item_id` IN (
    SELECT `id` FROM `order_items` WHERE `order_id` = @out_order_id
);
