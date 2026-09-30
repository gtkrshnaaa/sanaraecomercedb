-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 05: Financial Ledgers, Payouts, QA Inspections, Reviews & Audit Logs
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `system_audit_logs`;
TRUNCATE TABLE `review_helpful_votes`;
TRUNCATE TABLE `product_reviews`;
TRUNCATE TABLE `product_quality_reviews`;
TRUNCATE TABLE `wallet_ledger_entries`;
TRUNCATE TABLE `payout_requests`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Payout Requests
INSERT INTO `payout_requests` (
    `id`, `uuid`, `creator_id`, `amount`, `currency`, `payout_method`,
    `destination_account_metadata`, `status`, `payout_fee_amount`, `gateway_batch_id`, `processed_at`
) VALUES
(
    1, UUID(), 1, 2000.00, 'USD', 'wise',
    '{"recipient_email": "finance@nusantaraguild.id", "bank_account_holder": "PT Nusantara Guild Visual", "wise_account_id": "WSE-ID-88219"}',
    'completed', 8.50, 'WISE-BATCH-2025-07-01', '2025-07-02 10:00:00'
),
(
    2, UUID(), 2, 1500.00, 'USD', 'bank_wire',
    '{"swift_code": "BOTKJPJT", "bank_name": "MUFG Bank Tokyo", "account_number": "99281722", "account_holder": "Kyoto Vectors Inc."}',
    'completed', 25.00, 'SWIFT-TX-2025-11-15', '2025-11-16 14:30:00'
),
(
    3, UUID(), 3, 2500.00, 'USD', 'bank_wire',
    '{"iban": "DE89370400440532013000", "bic": "DRESDEFF700", "bank_name": "Commerzbank Berlin", "account_holder": "Bauhaus Grid Lab GmbH"}',
    'approved', 0.00, NULL, NULL
);

-- 2. Immutable Financial Accounting Ledger Entries
INSERT INTO `wallet_ledger_entries` (
    `id`, `wallet_id`, `creator_id`, `entry_type`, `direction`, `amount`,
    `balance_before`, `balance_after`, `order_item_id`, `payout_request_id`, `reference_note`, `created_at`
) VALUES
-- Creator 1 (Nusantara Guild)
(1, 1, 1, 'sale_royalty', 'credit', 72.98, 0.00, 72.98, 1, NULL, 'Royalty earned from Billboard 14x4m (Order 1)', '2025-06-15 14:22:10'),
(2, 1, 1, 'sale_royalty', 'credit', 409.18, 72.98, 482.16, 2, NULL, 'Enterprise Royalty from Ogilvy Campaign (Order 2)', '2025-09-20 09:12:00'),
(3, 1, 1, 'sale_royalty', 'credit', 163.18, 482.16, 645.34, 3, NULL, 'Spanduk Banner Royalty from Ogilvy (Order 2)', '2025-09-20 09:12:00'),
(4, 1, 1, 'escrow_release', 'credit', 645.34, 645.34, 1290.68, NULL, NULL, 'Escrow release after 14-day clearance window', '2025-10-05 00:00:00'),
(5, 1, 1, 'payout_withdrawal', 'debit', 2000.00, 4450.00, 2450.00, NULL, 1, 'Wise Bank Payout Disbursement #1', '2025-07-02 10:00:00'),

-- Creator 2 (Kyoto Vectors)
(6, 2, 2, 'sale_royalty', 'credit', 208.00, 3182.00, 3390.00, 5, NULL, 'Cyber Samurai 3D Extended Royalty from Dentsu', '2026-02-10 16:45:00'),
(7, 2, 2, 'payout_withdrawal', 'debit', 1500.00, 3390.00, 1890.00, NULL, 2, 'SWIFT International Wire Payout #2', '2025-11-16 14:30:00'),

-- Creator 3 (Bauhaus Grid Lab)
(8, 3, 3, 'sale_royalty', 'credit', 84.15, 3035.85, 3120.00, 4, NULL, 'Swiss Poster Royalty from Dentsu', '2026-02-10 16:45:00'),
(9, 3, 3, 'sale_royalty', 'credit', 41.65, 3120.00, 3161.65, 7, NULL, 'Cosmetic Box Dieline Royalty from Reza Studio', '2026-03-05 11:32:00');

-- 3. Art Director Quality Inspections (Passed Pre-Flight QA)
INSERT INTO `product_quality_reviews` (
    `id`, `product_id`, `inspector_user_id`, `review_status`, `technical_checklist`, `curator_feedback`, `reviewed_at`
) VALUES
(
    1, 1, 2, 'passed',
    '{
        "dpi_verified": 72,
        "color_profile": "U.S. Web Coated (SWOP) v2 / CMYK",
        "bleed_margin_mm": 100,
        "fonts_outlined": true,
        "overprint_checked": true,
        "mechanical_specs_adherence": "High-way Large Format Approved"
    }',
    'Exceptional vector precision. Bleed tolerances are flawless for billboard unipole fabrication. Spot colors mapped correctly.',
    '2025-01-11 16:00:00'
),
(
    2, 2, 2, 'passed',
    '{
        "dpi_verified": 150,
        "color_profile": "ISO Coated v2 (ECI) / CMYK",
        "grommet_alignment_margin_mm": 50,
        "tear_resistance_allowance": true
    }',
    'Grommet placement markers tested against 440gsm flex vinyl printer profile. Ready for retail distribution.',
    '2025-01-17 11:00:00'
),
(
    3, 3, 3, 'passed',
    '{
        "dpi_verified": 300,
        "color_profile": "FOGRA39 (ISO 12647-2) / CMYK",
        "grid_baseline_alignment": "12-Column Swiss Modular",
        "spot_uv_plate_separated": true
    }',
    'Impeccable typographic discipline. Kerning and baseline grid adhere to classical Swiss design standards.',
    '2025-02-01 17:30:00'
),
(
    4, 4, 3, 'passed',
    '{
        "blender_version_compatibility": "4.1+",
        "quad_topology_verified": true,
        "shape_keys_count": 48,
        "ik_fk_switching_tested": true
    }',
    'Clean low-poly topology with zero n-gons. Facial shape keys blend seamlessly with ARKit standards.',
    '2025-02-09 15:00:00'
);

-- 4. Customer Verified Reviews & Star Ratings
INSERT INTO `product_reviews` (
    `id`, `product_id`, `order_item_id`, `user_id`, `rating`, `headline`,
    `review_body`, `is_verified_purchase`, `helpful_votes_count`, `creator_reply`, `creator_replied_at`
) VALUES
(
    1, 1, 1, 9, 5,
    'Flawless Highway Baliho Quality - Printed at 14x4m without pixelation!',
    'We sent this file directly to the outdoor digital print house in Jakarta. The mechanical bleed guides and Pantone separations saved our team at least 8 hours of pre-press adjustments. Superb vector structure!',
    1, 14,
    'Terima kasih banyak Reza Studio! Senang sekali bisa membantu efisiensi cetak outdoor Anda.', '2025-06-18 10:00:00'
),
(
    2, 1, 2, 10, 5,
    'Enterprise Grade Unipole Template for Nationwide Campaign',
    'Deployed this template across 20 highway locations in North America. Clean layer architecture made localized agency branding effortless.',
    1, 28,
    'Honored to see our layout across your national campaign! Cheers from Nusantara Guild.', '2025-09-25 14:00:00'
),
(
    3, 3, 4, 11, 5,
    'The Most Authentic Swiss Poster Layout on the Market',
    'The InDesign grid file is set up with architectural precision. FOGRA39 color profiles matched our offset proofing perfectly.',
    1, 9,
    'Vielen Dank! We crafted the grid system based on original Zurich design archives.', '2026-02-12 11:20:00'
),
(
    4, 4, 5, 11, 5,
    'Incredible Rigging & Animation Ready Out of the Box',
    'Imported straight into Unreal Engine 5.4 with minimal retargeting work. The cyberpunk visual aesthetic is top tier.',
    1, 16,
    'Arigato gozaimasu! More modular armor attachments coming in v1.2.', '2026-02-14 09:00:00'
);

-- 5. Review Helpful Votes
INSERT INTO `review_helpful_votes` (`review_id`, `user_id`, `is_helpful`) VALUES
(1, 10, 1), (1, 11, 1),
(2, 9, 1), (2, 11, 1),
(3, 9, 1),
(4, 9, 1), (4, 10, 1);

-- 6. Central System Security Audit Logs
INSERT INTO `system_audit_logs` (
    `actor_user_id`, `action`, `entity_type`, `entity_id`, `old_state`, `new_state`, `ip_address`
) VALUES
(1, 'PRODUCT_QA_APPROVED', 'products', 1, '{"status": "under_review"}', '{"status": "published"}', '127.0.0.1'),
(1, 'PAYOUT_DISBURSED', 'payout_requests', 1, '{"status": "approved"}', '{"status": "completed", "gateway_batch": "WISE-BATCH-2025-07-01"}', '127.0.0.1'),
(2, 'ART_DIRECTOR_INSPECTION', 'product_quality_reviews', 1, NULL, '{"review_status": "passed"}', '103.28.12.1');
