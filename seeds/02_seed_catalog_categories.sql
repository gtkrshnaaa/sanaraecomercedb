-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Seed 02: Software Ecosystems, Licenses, Hierarchical Categories & Tags
-- ==============================================================================

USE `sanara_ecommerce`;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `tags`;
TRUNCATE TABLE `software_ecosystems`;
TRUNCATE TABLE `licenses`;
TRUNCATE TABLE `categories`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Licenses Master Data
INSERT INTO `licenses` (`id`, `code`, `name`, `description`, `default_price_multiplier`, `max_seats`, `max_print_impressions`, `merchandise_allowed`, `broadcast_tv_allowed`, `display_order`) VALUES
(1, 'standard', 'Standard Commercial License', 'Permitted for 1 user, up to 5,000 physical print impressions or digital end products. No merchandise resale.', 1.00, 1, 5000, 0, 0, 1),
(2, 'extended', 'Extended Commercial License', 'Permitted for 1 user, unlimited physical print runs, commercial advertising campaigns, and client work.', 2.50, 1, 0, 1, 0, 2),
(3, 'enterprise', 'Enterprise Multi-Seat & Broadcast', 'Unlimited seats across organization, nationwide billboard campaigns, broadcast television, and unlimited merchandise.', 6.00, 0, 0, 1, 1, 3),
(4, 'editorial', 'Editorial & Personal Non-Profit', 'Restricted to personal, educational, non-commercial, and editorial news publishing only.', 0.60, 1, 1000, 0, 0, 4);

-- 2. Software Compatibility Registry
INSERT INTO `software_ecosystems` (`id`, `name`, `slug`, `vendor`, `primary_extension`, `icon_url`) VALUES
(1, 'Adobe Illustrator', 'adobe-illustrator', 'Adobe', 'ai', 'https://cdn.sanara.design/icons/software/ai.svg'),
(2, 'Adobe Photoshop', 'adobe-photoshop', 'Adobe', 'psd', 'https://cdn.sanara.design/icons/software/psd.svg'),
(3, 'Figma', 'figma', 'Figma Inc.', 'fig', 'https://cdn.sanara.design/icons/software/figma.svg'),
(4, 'Blender 3D', 'blender', 'Blender Foundation', 'blend', 'https://cdn.sanara.design/icons/software/blender.svg'),
(5, 'Adobe InDesign', 'adobe-indesign', 'Adobe', 'indd', 'https://cdn.sanara.design/icons/software/indd.svg'),
(6, 'Adobe After Effects', 'adobe-after-effects', 'Adobe', 'aep', 'https://cdn.sanara.design/icons/software/ae.svg'),
(7, 'CorelDRAW', 'coreldraw', 'Alludo', 'cdr', 'https://cdn.sanara.design/icons/software/cdr.svg');

-- 3. Categories (Hierarchical Taxonomy)
INSERT INTO `categories` (`id`, `parent_id`, `name`, `slug`, `category_code`, `description`, `path`, `depth`, `display_order`) VALUES
-- Level 1: Outdoor Advertising
(1, NULL, 'Outdoor Advertising & Large Format Signage', 'outdoor-advertising', 'CAT-OUTDOOR', 'High-impact outdoor promotional media, large format billboards, and street graphics.', '/1/', 1, 1),
-- Level 2: Outdoor Subcategories
(2, 1, 'Mega Billboards & Baliho', 'billboards-baliho', 'CAT-BALIHO', 'Monumental highway billboards, outdoor unipoles, and architectural building wraps.', '/1/2/', 2, 1),
(3, 1, 'Vinyl Banners & Spanduk', 'vinyl-banners-spanduk', 'CAT-SPANDUK', 'Horizontal vinyl banners, road cross banners, and street fencing displays.', '/1/3/', 2, 2),
(4, 1, 'Roll-Up Banners & Exhibition Displays', 'rollup-exhibition', 'CAT-ROLLUP', 'Retractable roll-up banners, X-banners, and trade show modular booth backdrops.', '/1/4/', 2, 3),
(5, 1, 'Transit & Vehicle Fleet Wraps', 'vehicle-fleet-wraps', 'CAT-TRANSIT', 'Vector templates for bus wraps, commercial delivery vans, and fleet graphics.', '/1/5/', 2, 4),

-- Level 1: Print Media & Editorial
(6, NULL, 'Print Media & Editorial Design', 'print-editorial', 'CAT-PRINT', 'Press-ready print collateral, exhibition posters, and publication layouts.', '/6/', 1, 2),
-- Level 2: Print Subcategories
(7, 6, 'Exhibition Posters & Wall Art (A1-A3)', 'exhibition-posters', 'CAT-POSTER', 'Modernist, typographic, and illustrative posters formatted for ISO A-Series printing.', '/6/7/', 2, 1),
(8, 6, 'Packaging Die-Lines & Box Mockups', 'packaging-dielines', 'CAT-PACKAGE', 'Structural vector packaging die-lines, cosmetic boxes, and product containers.', '/6/8/', 2, 2),
(9, 6, 'Editorial Magazines & Lookbooks', 'editorial-lookbooks', 'CAT-LOOKBOOK', 'Multi-page InDesign and Figma editorial brochures, brand lookbooks, and annual reports.', '/6/9/', 2, 3),

-- Level 1: Brand Identity Systems
(10, NULL, 'Brand Identity Systems', 'brand-identity', 'CAT-BRAND', 'Comprehensive brand guideline templates, logo suites, and corporate stationery.', '/10/', 1, 3),
(11, 10, 'Corporate Stationery & Letterhead Kits', 'stationery-kits', 'CAT-STATIONERY', 'Cohesive business cards, invoices, envelopes, and letterheads.', '/10/11/', 2, 1),
(12, 10, 'Brand Guidelines & Manuals', 'brand-manuals', 'CAT-MANUAL', 'Complete multi-page brand strategy, typography rules, and color system manuals.', '/10/12/', 2, 2),

-- Level 1: Illustrations & 3D Assets
(13, NULL, 'Illustrations & 3D Assets', 'illustrations-3d', 'CAT-ILLUST-3D', 'Render-ready 3D models, character rigs, and scalable 2D illustration libraries.', '/13/', 1, 4),
(14, 13, '3D Character Rigs & Mascots', '3d-character-rigs', 'CAT-3D-CHAR', 'Fully rigged 3D character avatars with facial blends and animations in Blender.', '/13/14/', 2, 1),
(15, 13, '3D UI Elements & Scene Builders', '3d-ui-elements', 'CAT-3D-UI', 'Isometric shapes, clay-style icons, and dynamic 3D abstract compositions.', '/13/15/', 2, 2),
(16, 13, '2D Vector Character Libraries', 'vector-characters', 'CAT-2D-CHAR', 'Modular vector character kits with interchangeable poses, hair, and clothing.', '/13/16/', 2, 3),

-- Level 1: Iconography & UI Components
(17, NULL, 'Iconography & Design Systems', 'iconography-design-systems', 'CAT-ICONS-UI', 'Production icon libraries and cross-platform UI component kits.', '/17/', 1, 5),
(18, 17, 'Vector Icon Packs (1,000+ Items)', 'vector-icon-packs', 'CAT-ICON-PACKS', 'Pixel-perfect SVG and IconJar sets with consistent stroke, solid, and duotone styles.', '/17/18/', 2, 1),
(19, 17, 'Figma Design System UI Toolkits', 'figma-ui-toolkits', 'CAT-FIGMA-UI', 'Atomic design tokens, mobile app UI kits, and responsive component libraries.', '/17/19/', 2, 2);

-- 4. Tags
INSERT INTO `tags` (`id`, `name`, `slug`, `usage_count`) VALUES
(1, 'baliho-outdoor', 'baliho-outdoor', 45),
(2, 'spanduk-vinyl', 'spanduk-vinyl', 38),
(3, 'billboard-horizontal', 'billboard-horizontal', 52),
(4, 'cmyk-print-ready', 'cmyk-print-ready', 89),
(5, '300dpi-high-res', '300dpi-high-res', 95),
(6, 'vector-eps', 'vector-eps', 74),
(7, 'figma-tokens', 'figma-tokens', 41),
(8, 'blender-rigged', 'blender-rigged', 29),
(9, 'character-mascot', 'character-mascot', 34),
(10, 'packaging-dieline', 'packaging-dieline', 22),
(11, 'bauhaus-grid', 'bauhaus-grid', 18),
(12, 'swiss-typography', 'swiss-typography', 26),
(13, 'cyberpunk-neon', 'cyberpunk-neon', 31),
(14, 'corporate-stationery', 'corporate-stationery', 20),
(15, 'rollup-banner', 'rollup-banner', 19);
