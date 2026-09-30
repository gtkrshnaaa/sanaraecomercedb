-- ==============================================================================
-- Sanara E-Commerce Query Suite: 06. EXPLAIN & EXPLAIN ANALYZE Benchmarks
-- Demonstrates: Partition Pruning, Covering Indexes, Index Condition Pushdown (ICP)
-- ==============================================================================

USE `sanara_ecommerce`;

-- 1. Partition Pruning Proof on Orders Table
-- Target: Orders created in 2026.
-- Verification: Query optimizer evaluates ONLY partition `p2026`, pruning p2024, p2025, p2027, p_future.
EXPLAIN 
SELECT `id`, `order_number`, `buyer_id`, `total_amount`, `created_at`
FROM `orders`
WHERE `created_at` >= '2026-01-01 00:00:00' 
  AND `created_at` < '2027-01-01 00:00:00';

EXPLAIN ANALYZE
SELECT `id`, `order_number`, `buyer_id`, `total_amount`, `created_at`
FROM `orders`
WHERE `created_at` >= '2026-01-01 00:00:00' 
  AND `created_at` < '2027-01-01 00:00:00';

-- 2. Full-Text Search Plan with MATCH AGAINST
EXPLAIN 
SELECT `id`, `title`, `base_standard_price`
FROM `products`
WHERE MATCH(`title`, `subtitle`, `search_keywords`) AGAINST('billboard outdoor' IN NATURAL LANGUAGE MODE);

EXPLAIN ANALYZE
SELECT `id`, `title`, `base_standard_price`
FROM `products`
WHERE MATCH(`title`, `subtitle`, `search_keywords`) AGAINST('billboard outdoor' IN NATURAL LANGUAGE MODE);

-- 3. Stored Generated Column Index Scan vs Table Scan
-- Target: Find all 300 DPI CMYK assets ready for offset printing
EXPLAIN
SELECT `id`, `title`, `color_mode`, `resolution_dpi`
FROM `products`
WHERE `color_mode` = 'CMYK' AND `resolution_dpi` = 300;

EXPLAIN ANALYZE
SELECT `id`, `title`, `color_mode`, `resolution_dpi`
FROM `products`
WHERE `color_mode` = 'CMYK' AND `resolution_dpi` = 300;
