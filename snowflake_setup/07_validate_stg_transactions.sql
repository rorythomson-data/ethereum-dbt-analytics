
-- ============================================================
-- 07_VALIDATE_STG_TRANSACTIONS.SQL
-- ============================================================
--
-- PURPOSE
-- Validate the row count, transaction uniqueness, and
-- completeness of key fields in the stg_transactions view.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet after
-- executing: dbt run --select stg_transactions
--
-- Read-only: does not modify any database objects.
--
-- EXPECTED RESULTS
-- Total transactions:       1,000
-- Unique transactions:      1,000
-- NULL transaction hashes:      0
-- NULL block timestamps:        0
--
-- These expectations apply to the current sampled dataset
-- and should be reviewed if the ingestion scope changes.
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE STAGING TRANSACTIONS
-- ============================================================
--
-- Check that:
-- 1. The staging view preserves the expected row count.
-- 2. Each transaction hash uniquely identifies a record.
-- 3. No transaction hashes are NULL.
-- 4. Block timestamps have been successfully populated.
--
-- ============================================================

SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT transaction_hash) AS unique_transactions,
    COUNT_IF(transaction_hash IS NULL) AS null_transaction_hashes,
    COUNT_IF(block_timestamp IS NULL) AS null_timestamps
FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_TRANSACTIONS;
