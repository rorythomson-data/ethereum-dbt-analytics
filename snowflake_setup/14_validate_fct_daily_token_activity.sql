
-- ============================================================
-- 14_VALIDATE_FCT_DAILY_TOKEN_ACTIVITY.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Validate the grain, required fields, and transfer-event
-- reconciliation of the daily token activity mart.
--
-- EXECUTION
-- Run manually in a Snowflake SQL Worksheet.
-- ============================================================

-- 1. Inspect the mart's row count and key integrity.
-- Each activity_date/token_address combination must be unique.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT activity_date, token_address) AS distinct_date_token_pairs,
    COUNT_IF(activity_date IS NULL) AS null_dates,
    COUNT_IF(token_address IS NULL) AS null_token_addresses
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY;

-- 2. Reconcile total transfer events with staging.
-- The mart must account for every staged transfer event.
SELECT
    (SELECT COUNT(*)
     FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_TOKEN_TRANSFERS)
        AS staging_transfer_count,
    (SELECT SUM(transfer_count)
     FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY)
        AS mart_transfer_count;

-- 3. Inspect the most active tokens in the sample.
-- Ranking uses transfer-event counts, not token value.
SELECT
    activity_date,
    token_address,
    transfer_count,
    transaction_count,
    unique_senders,
    unique_receivers
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
ORDER BY transfer_count DESC, token_address
LIMIT 10;