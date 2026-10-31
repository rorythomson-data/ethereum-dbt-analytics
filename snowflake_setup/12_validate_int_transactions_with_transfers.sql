
-- ============================================================
-- 12_VALIDATE_INT_TRANSACTIONS_WITH_TRANSFERS.SQL
-- ============================================================
--
-- PURPOSE
-- Validate the grain, completeness and aggregated transfer
-- metrics of the intermediate transactions model.
--
-- EXECUTION
-- Run in a Snowflake SQL worksheet after executing:
-- dbt run --select int_transactions_with_transfers
--
-- Read-only: does not modify database objects.
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE TRANSACTION GRAIN
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_hash) AS unique_transactions,
    COUNT_IF(transaction_hash IS NULL) AS null_transaction_hashes
FROM ETHEREUM_PORTFOLIO.ANALYTICS.INT_TRANSACTIONS_WITH_TRANSFERS;


-- ============================================================
-- STEP 2: VALIDATE AGGREGATED TRANSFER METRICS
-- ============================================================

SELECT
    SUM(transfer_count) AS total_transfer_events,
    COUNT_IF(has_token_transfer = TRUE) AS transactions_with_transfers,
    COUNT_IF(has_token_transfer = FALSE) AS transactions_without_transfers,
    MIN(transfer_count) AS min_transfers_per_transaction,
    MAX(transfer_count) AS max_transfers_per_transaction
FROM ETHEREUM_PORTFOLIO.ANALYTICS.INT_TRANSACTIONS_WITH_TRANSFERS;


-- ============================================================
-- STEP 3: INSPECT SAMPLE RESULTS
-- ============================================================

SELECT
    transaction_hash,
    gas_used,
    transfer_count,
    distinct_token_count,
    has_token_transfer
FROM ETHEREUM_PORTFOLIO.ANALYTICS.INT_TRANSACTIONS_WITH_TRANSFERS
ORDER BY transfer_count DESC, transaction_hash
LIMIT 10;
