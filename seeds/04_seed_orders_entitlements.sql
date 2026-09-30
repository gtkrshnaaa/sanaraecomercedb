-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 04: Orders, Entitlements, Ephemeral Tokens & Partitioned Telemetry Logs
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `download_logs`;
TRUNCATE TABLE `secure_download_tokens`;
TRUNCATE TABLE `customer_entitlements`;
TRUNCATE TABLE `payment_transactions`;
TRUNCATE TABLE `order_items`;
TRUNCATE TABLE `orders`;
TRUNCATE TABLE `coupons`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Promotional Coupons
INSERT INTO `coupons` (`id`, `code`, `discount_type`, `discount_value`, `min_order_amount`, `max_discount_amount`, `total_usage_limit`, `current_usage_count`, `starts_at`, `expires_at`, `is_active`) VALUES
(1, 'DESIGNFEST20', 'percentage', 20.00, 50.00, 100.00, 500, 42, '2025-01-01 00:00:00', '2026-12-31 23:59:59', 1),
(2, 'OUTDOOR50OFF', 'fixed_amount', 50.00, 200.00, 50.00, 100, 15, '2025-01-01 00:00:00', '2026-12-31 23:59:59', 1);

-- 2. Orders (Partitioned across 2025 and 2026)
INSERT INTO `orders` (
    `id`, `uuid`, `order_number`, `buyer_id`, `agency_team_id`, `currency`,
    `subtotal_amount`, `discount_amount`, `tax_amount`, `total_amount`,
    `coupon_id`, `status`, `payment_method`, `payment_reference_id`, `paid_at`, `created_at`
) VALUES
-- Order 1: 2025 Purchase by Reza Studio (Standard Billboard)
(1, UUID(), 'ORD-2025-BB01', 9, NULL, 'USD', 89.00, 0.00, 0.00, 89.00, NULL, 'completed', 'stripe', 'ch_3MvY892eZvKYlo2C1', '2025-06-15 14:22:10', '2025-06-15 14:20:00'),

-- Order 2: 2025 Enterprise Purchase by Ogilvy (Enterprise Billboard + Spanduk)
(2, UUID(), 'ORD-2025-OG02', 10, 1, 'USD', 698.00, 50.00, 0.00, 648.00, 2, 'completed', 'stripe', 'ch_3NxZ912eZvKYlo2C2', '2025-09-20 09:12:00', '2025-09-20 09:10:00'),

-- Order 3: 2026 Purchase by Dentsu (Swiss Posters + 3D Cyber Samurai)
(3, UUID(), 'ORD-2026-DT03', 11, 2, 'USD', 359.00, 71.80, 0.00, 287.20, 1, 'completed', 'paypal', 'PAYID-MT76211', '2026-02-10 16:45:00', '2026-02-10 16:40:00'),

-- Order 4: 2026 Purchase by Reza (OmniGlyph Icon Pack + Packaging Box)
(4, UUID(), 'ORD-2026-RZ04', 9, NULL, 'USD', 94.00, 0.00, 0.00, 94.00, NULL, 'completed', 'midtrans', 'MID-TRX-882194', '2026-03-05 11:32:00', '2026-03-05 11:30:00');

-- 3. Order Items & Line-Item Royalties
INSERT INTO `order_items` (
    `id`, `order_id`, `order_created_at`, `product_id`, `variant_id`, `license_id`, `creator_id`,
    `unit_price`, `creator_royalty_percentage`, `creator_royalty_amount`, `platform_fee_amount`,
    `license_grant_key`, `status`, `created_at`
) VALUES
-- From Order 1
(1, 1, '2025-06-15 14:20:00', 1, 1, 1, 1, 89.00, 82.00, 72.98, 16.02, 'SANARA-91AF-4281-B892-001A', 'active', '2025-06-15 14:22:10'),

-- From Order 2 (Ogilvy)
(2, 2, '2025-09-20 09:10:00', 1, 1, 3, 1, 499.00, 82.00, 409.18, 89.82, 'SANARA-78BB-1122-C901-002B', 'active', '2025-09-20 09:12:00'),
(3, 2, '2025-09-20 09:10:00', 2, 3, 3, 1, 199.00, 82.00, 163.18, 35.82, 'SANARA-62AC-5544-D881-003C', 'active', '2025-09-20 09:12:00'),

-- From Order 3 (Dentsu)
(4, 3, '2026-02-10 16:40:00', 3, 4, 2, 3, 99.00, 85.00, 84.15, 14.85, 'SANARA-33DE-9988-A123-004D', 'active', '2026-02-10 16:45:00'),
(5, 3, '2026-02-10 16:40:00', 4, 6, 2, 2, 260.00, 80.00, 208.00, 52.00, 'SANARA-44FE-7711-B564-005E', 'active', '2026-02-10 16:45:00'),

-- From Order 4 (Reza)
(6, 4, '2026-03-05 11:30:00', 6, 8, 1, 5, 45.00, 80.00, 36.00, 9.00, 'SANARA-55AA-3322-C777-006F', 'active', '2026-03-05 11:32:00'),
(7, 4, '2026-03-05 11:30:00', 7, 10, 1, 3, 49.00, 85.00, 41.65, 7.35, 'SANARA-88EE-2211-D999-007G', 'active', '2026-03-05 11:32:00');

-- 4. Customer Digital Asset Entitlements
INSERT INTO `customer_entitlements` (
    `id`, `uuid`, `buyer_id`, `agency_team_id`, `product_id`, `variant_id`, `license_id`, `order_item_id`,
    `license_grant_key`, `entitlement_status`, `granted_at`
) VALUES
(1, UUID(), 9, NULL, 1, 1, 1, 1, 'SANARA-91AF-4281-B892-001A', 'active', '2025-06-15 14:22:10'),
(2, UUID(), 10, 1, 1, 1, 3, 2, 'SANARA-78BB-1122-C901-002B', 'active', '2025-09-20 09:12:00'),
(3, UUID(), 10, 1, 2, 3, 3, 3, 'SANARA-62AC-5544-D881-003C', 'active', '2025-09-20 09:12:00'),
(4, UUID(), 11, 2, 3, 4, 2, 4, 'SANARA-33DE-9988-A123-004D', 'active', '2026-02-10 16:45:00'),
(5, UUID(), 11, 2, 4, 6, 2, 5, 'SANARA-44FE-7711-B564-005E', 'active', '2026-02-10 16:45:00'),
(6, UUID(), 9, NULL, 6, 8, 1, 6, 'SANARA-55AA-3322-C777-006F', 'active', '2026-03-05 11:32:00'),
(7, UUID(), 9, NULL, 7, 10, 1, 7, 'SANARA-88EE-2211-D999-007G', 'active', '2026-03-05 11:32:00');

-- 5. Secure Ephemeral Download Tokens
INSERT INTO `secure_download_tokens` (
    `id`, `token_hash`, `entitlement_id`, `variant_id`, `requested_by_user_id`,
    `bound_ip_address`, `max_allowed_downloads`, `download_count`, `is_revoked`, `expires_at`, `created_at`
) VALUES
(1, SHA2('token_raw_alpha_2025_01', 256), 1, 1, 9, '103.28.12.44', 5, 2, 0, '2025-06-16 14:22:10', '2025-06-15 14:22:10'),
(2, SHA2('token_raw_ogilvy_2025_02', 256), 2, 1, 10, '198.51.100.25', 10, 3, 0, '2025-09-21 09:12:00', '2025-09-20 09:12:00'),
(3, SHA2('token_raw_dentsu_2026_03', 256), 4, 4, 11, '203.0.113.88', 5, 1, 0, '2026-02-11 16:45:00', '2026-02-10 16:45:00'),
(4, SHA2('token_raw_reza_2026_04', 256), 6, 8, 9, '103.28.12.44', 5, 1, 0, '2026-12-31 23:59:59', '2026-03-05 11:35:00');

-- 6. Partitioned Download Telemetry Logs
INSERT INTO `download_logs` (
    `id`, `download_token_id`, `entitlement_id`, `variant_id`, `user_id`,
    `client_ip`, `country_iso`, `user_agent`, `bytes_delivered`, `http_status_code`,
    `delivery_duration_ms`, `delivery_status`, `requested_at`
) VALUES
-- 2025 Downloads (Stored into Partition p2025)
(1, 1, 1, 1, 9, '103.28.12.44', 'ID', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 398458880, 200, 14200, 'completed', '2025-06-15 14:30:00'),
(2, 2, 2, 1, 10, '198.51.100.25', 'US', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 398458880, 200, 8900, 'completed', '2025-09-20 09:30:00'),

-- 2026 Downloads (Stored into Partition p2026)
(3, 3, 4, 4, 11, '203.0.113.88', 'JP', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2)', 125829120, 200, 4200, 'completed', '2026-02-10 17:00:00'),
(4, 4, 6, 8, 9, '103.28.12.44', 'ID', 'Mozilla/5.0 (X11; Linux x86_64)', 146800640, 200, 5100, 'completed', '2026-03-05 11:40:00'),
(5, NULL, 6, 8, 9, '103.28.12.44', 'ID', 'curl/8.5.0', 0, 403, 50, 'expired_token', '2026-03-06 08:00:00');
