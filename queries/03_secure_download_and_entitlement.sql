-- ==============================================================================
-- Sanara E-Commerce Query Suite: 03. Secure Download Token & Delivery
-- Demonstrates: Ephemeral Token Generation, IP Verification, Telemetry Logging
-- ==============================================================================

USE `sanara_ecommerce`;

SET @buyer_id = 9;       -- Reza Studio
SET @variant_id = 4;     -- InDesign Grid Package
SET @client_ip = '103.28.12.44';
SET @ttl_hours = 12;

SET @raw_token = '';
SET @expires_at = NOW();

-- Step 1: Request Ephemeral Token via Stored Procedure
CALL sp_generate_secure_download_token(
    @buyer_id,
    @variant_id,
    @client_ip,
    @ttl_hours,
    @raw_token,
    @expires_at
);

SELECT 
    @raw_token AS `generated_raw_token`,
    @expires_at AS `token_expiration_timestamp`;

-- Step 2: Validate Token and Fetch S3 Asset Storage Key
SELECT 
    sdt.`id` AS `token_id`,
    sdt.`bound_ip_address`,
    sdt.`download_count`,
    sdt.`max_allowed_downloads`,
    sdt.`expires_at`,
    pv.`name` AS `asset_variant_name`,
    pv.`storage_bucket`,
    pv.`storage_s3_key`,
    fn_format_bytes(pv.`file_size_bytes`) AS `file_size`
FROM `secure_download_tokens` sdt
JOIN `product_variants` pv ON pv.`id` = sdt.`variant_id`
WHERE sdt.`token_hash` = SHA2(@raw_token, 256)
  AND sdt.`is_revoked` = 0
  AND sdt.`expires_at` > NOW()
  AND sdt.`download_count` < sdt.`max_allowed_downloads`;

-- Step 3: Record Delivery Telemetry in Partitioned Log
INSERT INTO `download_logs` (
    `download_token_id`, `entitlement_id`, `variant_id`, `user_id`,
    `client_ip`, `country_iso`, `user_agent`, `bytes_delivered`,
    `http_status_code`, `delivery_duration_ms`, `delivery_status`, `requested_at`
) VALUES (
    (SELECT `id` FROM `secure_download_tokens` WHERE `token_hash` = SHA2(@raw_token, 256)),
    (SELECT `entitlement_id` FROM `secure_download_tokens` WHERE `token_hash` = SHA2(@raw_token, 256)),
    @variant_id,
    @buyer_id,
    @client_ip,
    'ID',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    125829120,
    200,
    3850,
    'completed',
    NOW()
);

-- Step 4: Increment Token Download Counter
UPDATE `secure_download_tokens`
SET `download_count` = `download_count` + 1
WHERE `token_hash` = SHA2(@raw_token, 256);
