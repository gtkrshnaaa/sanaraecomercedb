-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 01: IAM Users, Design Studios, Creators, and Agency Teams
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `creator_kyc_compliance`;
TRUNCATE TABLE `agency_members`;
TRUNCATE TABLE `agency_teams`;
TRUNCATE TABLE `creator_social_links`;
TRUNCATE TABLE `creator_wallets`;
TRUNCATE TABLE `creator_profiles`;
TRUNCATE TABLE `user_activity_sessions`;
TRUNCATE TABLE `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Insert Core Users
INSERT INTO `users` (`id`, `uuid`, `email`, `password_hash`, `full_name`, `display_name`, `role`, `status`, `preferred_locale`, `preferred_currency`) VALUES
-- Admins & Art Directors
(1, UUID(), 'admin@sanara.design', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'System Administrator', 'Sanara Admin', 'super_admin', 'active', 'en_US', 'USD'),
(2, UUID(), 'curator.dewi@sanara.design', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Dewi Lestari', 'Dewi Art Director', 'art_director', 'active', 'id_ID', 'USD'),
(3, UUID(), 'curator.marcus@sanara.design', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Marcus Vance', 'Marcus Print QA', 'art_director', 'active', 'de_DE', 'USD'),

-- Design Studios & Creators
(4, UUID(), 'bambang@nusantaraguild.id', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Bambang Sudiro', 'Nusantara Guild', 'creator', 'active', 'id_ID', 'USD'),
(5, UUID(), 'kenji@kyotovectors.jp', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Kenji Takahashi', 'Kyoto Vectors', 'creator', 'active', 'ja_JP', 'USD'),
(6, UUID(), 'greta@bauhausgrid.de', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Greta von Schmidt', 'Bauhaus Lab', 'creator', 'active', 'de_DE', 'USD'),
(7, UUID(), 'oliver@apexmotion.co.uk', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Oliver Thorne', 'Apex Brand Studio', 'creator', 'active', 'en_GB', 'USD'),
(8, UUID(), 'sarah@pixelforge.io', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Sarah Jenkins', 'PixelForge 3D', 'creator', 'active', 'en_US', 'USD'),

-- Buyers & Agency Creative Directors
(9, UUID(), 'reza.buyer@gmail.com', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Reza Pratama', 'Reza Studio', 'customer', 'active', 'id_ID', 'USD'),
(10, UUID(), 'claire@ogilvy-campaign.com', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Claire Montgomery', 'Claire Ogilvy', 'customer', 'active', 'en_US', 'USD'),
(11, UUID(), 'hiroshi@dentsu-media.co.jp', '$2y$12$e8x/U9FwGf3fG7kH8Y3v2eQG8R0wM8vA3eT9.N4oZ8wV7eQ9wR1mK', 'Hiroshi Tanaka', 'Hiroshi Dentsu', 'customer', 'active', 'ja_JP', 'USD');

-- 2. Creator Profiles
INSERT INTO `creator_profiles` (`id`, `user_id`, `studio_name`, `slug`, `bio`, `headline`, `country_code`, `commission_rate`, `is_verified_creator`, `verified_at`, `total_products_count`, `average_rating`) VALUES
(1, 4, 'Nusantara Graphic Guild', 'nusantara-guild', 'Premier Indonesian visual communications studio specializing in outdoor billboards, vinyl banners (spanduk), and large format print production.', 'Master of Large-Scale Outdoor Billboard & Banner Engineering', 'ID', 82.00, 1, '2025-01-10 10:00:00', 8, 4.95),
(2, 5, 'Kyoto Vectors', 'kyoto-vectors', 'Contemporary Tokyo/Kyoto digital asset foundry engineering 3D character rigs, cyber-anime vector kits, and dynamic isometric assets.', 'Next-Gen 3D Character Models & Japanese Cyber Vector Kits', 'JP', 80.00, 1, '2025-01-15 11:30:00', 6, 4.90),
(3, 6, 'Bauhaus Grid Lab', 'bauhaus-grid-lab', 'Strict modernist typography, Swiss grid layouts, print-ready A1 exhibition posters, and CMYK packaging die-cuts.', 'Precision Swiss Typography & Minimalist Exhibition Poster Design', 'DE', 85.00, 1, '2025-02-01 09:00:00', 5, 4.88),
(4, 7, 'Apex Brand Motion', 'apex-brand-motion', 'London creative practice delivering corporate identity systems, kinetic typography kits, and multi-format social media toolkits.', 'Enterprise Brand Guidelines & Kinetic Social Visual Systems', 'GB', 80.00, 1, '2025-02-12 14:00:00', 5, 4.82),
(5, 8, 'PixelForge 3D', 'pixelforge-3d', 'San Francisco asset lab crafting 2,500+ vector icon sets, low-poly 3D UI assets, and Blender procedural materials.', 'Comprehensive Iconographic Systems & Low-Poly 3D Assets', 'US', 80.00, 1, '2025-02-20 16:00:00', 6, 4.92);

-- 3. Social Links
INSERT INTO `creator_social_links` (`creator_id`, `platform`, `url`) VALUES
(1, 'behance', 'https://behance.net/nusantaraguild'),
(1, 'instagram', 'https://instagram.com/nusantaraguild'),
(2, 'artstation', 'https://artstation.com/kyotovectors'),
(2, 'dribbble', 'https://dribbble.com/kyotovectors'),
(3, 'website', 'https://bauhausgridlab.design'),
(4, 'behance', 'https://behance.net/apexmotion'),
(5, 'figma', 'https://figma.com/@pixelforge');

-- 4. Initial Creator Wallets
INSERT INTO `creator_wallets` (`id`, `creator_id`, `currency`, `available_balance`, `pending_escrow_balance`, `lifetime_withdrawn_total`) VALUES
(1, 1, 'USD', 2450.00, 850.00, 12400.00),
(2, 2, 'USD', 1890.00, 620.00, 8950.00),
(3, 3, 'USD', 3120.00, 450.00, 15600.00),
(4, 4, 'USD', 1250.00, 310.00, 5400.00),
(5, 5, 'USD', 4200.00, 980.00, 22100.00);

-- 5. Agency Teams
INSERT INTO `agency_teams` (`id`, `owner_user_id`, `team_name`, `slug`, `billing_email`, `seat_limit`, `enterprise_plan`) VALUES
(1, 10, 'Ogilvy APAC Creative Lab', 'ogilvy-apac', 'finance@ogilvy-campaign.com', 25, 'enterprise_unlimited'),
(2, 11, 'Dentsu Brand Experience Unit', 'dentsu-bx', 'invoicing@dentsu-media.co.jp', 15, 'growth');

-- 6. Agency Members
INSERT INTO `agency_members` (`team_id`, `user_id`, `team_role`, `joined_at`) VALUES
(1, 10, 'owner', '2025-01-05 08:00:00'),
(2, 11, 'owner', '2025-01-08 09:30:00');

-- 7. Creator AML / KYC Financial Compliance & Vetting Records
INSERT INTO `creator_kyc_compliance` (
    `creator_id`, `tax_id_hash`, `vat_number`, `legal_entity_name`,
    `residence_country_iso`, `compliance_status`, `aml_risk_score`,
    `payout_currency_code`, `reviewed_by_admin_id`, `verified_at`
) VALUES
(1, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'ID00982189421', 'PT Nusantara Desain Visual', 'ID', 'verified_approved', 5, 'USD', 1, '2025-01-10 10:00:00'),
(2, 'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb', 'JP81290312901', 'Kyoto Digital Arts GK', 'JP', 'verified_approved', 8, 'USD', 1, '2025-01-15 11:30:00'),
(3, '4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce', 'DE319028401', 'Bauhaus Raster Medien GmbH', 'DE', 'verified_approved', 4, 'USD', 1, '2025-02-01 09:00:00'),
(4, '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08', 'GB921048120', 'Apex Visual Motion Ltd', 'GB', 'verified_approved', 12, 'USD', 1, '2025-02-12 14:00:00'),
(5, '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b', NULL, 'PixelForge Asset Foundry LLC', 'US', 'w8_ben_submitted', 15, 'USD', 1, '2025-02-20 16:00:00');

