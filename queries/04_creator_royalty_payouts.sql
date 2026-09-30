-- ==============================================================================
-- Sanara E-Commerce Query Suite: 04. Creator Wallet & Payout Operations
-- Demonstrates: Pessimistic Row Locking, Double-Entry Ledger Debit
-- ==============================================================================

USE `sanara_ecommerce`;

SET @creator_id = 1; -- Nusantara Graphic Guild
SET @request_payout_amount = 500.00;
SET @payout_method = 'wise';
SET @dest_metadata = '{"wise_id": "WSE-ID-88219", "currency": "USD", "iban": "ID88219482109"}';
SET @out_payout_id = 0;

-- Step 1: Inspect Pre-Payout Wallet Balance
SELECT 
    `id` AS `wallet_id`,
    `creator_id`,
    `available_balance`,
    `pending_escrow_balance`
FROM `creator_wallets`
WHERE `creator_id` = @creator_id;

-- Step 2: Request Payout with Concurrency-Safe Stored Procedure
CALL sp_request_creator_payout(
    @creator_id,
    @request_payout_amount,
    @payout_method,
    @dest_metadata,
    @out_payout_id
);

-- Step 3: Inspect Created Payout Request Record
SELECT 
    `id` AS `payout_id`,
    `uuid`,
    `creator_id`,
    `amount`,
    `payout_method`,
    `status`,
    `created_at`
FROM `payout_requests`
WHERE `id` = @out_payout_id;

-- Step 4: Verify Post-Payout Wallet Balance & Audit Ledger Debit
SELECT 
    `id` AS `wallet_id`,
    `available_balance`,
    `pending_escrow_balance`
FROM `creator_wallets`
WHERE `creator_id` = @creator_id;

SELECT 
    `id` AS `ledger_id`,
    `entry_type`,
    `direction`,
    `amount`,
    `balance_before`,
    `balance_after`,
    `reference_note`
FROM `wallet_ledger_entries`
WHERE `payout_request_id` = @out_payout_id;
