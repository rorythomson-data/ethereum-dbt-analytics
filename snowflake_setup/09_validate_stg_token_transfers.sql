
-- ============================================================
-- 09_VALIDATE_STG_TOKEN_TRANSFERS.SQL
-- ============================================================
--
-- PURPOSE
-- Validate row counts, event uniqueness, and completeness
-- of key fields in the stg_token_transfers view.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet after
-- executing: dbt run --select stg_token_transfers
--
-- Read-only: does not modify database objects.
--
-- EXPECTED RESULTS
-- Total transfers:              1,779
-- Unique transfer keys:         1,779
-- NULL transaction hashes:          0
-- NULL log indexes:                 0
-- NULL block timestamps:           0
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE STAGING TOKEN TRANSFERS
-- ============================================================

SELECT
    COUNT(*) AS total_transfers,
    COUNT(DISTINCT
        CASE
            WHEN transaction_hash IS NOT NULL
             AND log_index IS NOT NULL
            THEN transaction_hash || ':' || log_index::VARCHAR
        END
    ) AS unique_transfer_keys,
    COUNT_IF(transaction_hash IS NULL) AS null_transaction_hashes,
    COUNT_IF(log_index IS NULL) AS null_log_indexes,
    COUNT_IF(block_timestamp IS NULL) AS null_timestamps
FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_TOKEN_TRANSFERS;
