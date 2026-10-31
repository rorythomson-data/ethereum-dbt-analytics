
-- ============================================================
-- 13_VALIDATE_FCT_DAILY_TRANSACTION_ACTIVITY.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Validate the daily transaction activity mart and reconcile
-- its aggregated metrics against the intermediate model.
--
-- EXECUTION
-- Snowflake SQL Worksheet | DBT_WH
--
-- ============================================================


-- 1. Inspect the daily activity mart.
-- Confirm its date grain and calculated metrics.

SELECT *
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TRANSACTION_ACTIVITY
ORDER BY activity_date;


-- 2. Validate daily grain and required fields.
-- Each activity_date should appear exactly once.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT activity_date) AS distinct_dates,
    COUNT_IF(activity_date IS NULL) AS null_dates,
    COUNT_IF(transaction_count IS NULL) AS null_transaction_counts
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TRANSACTION_ACTIVITY;


-- 3. Reconcile daily metrics against intermediate transactions.
-- Both datasets should produce matching aggregate totals.

WITH intermediate_totals AS (
    SELECT
        COUNT(*) AS expected_transactions,
        SUM(transfer_count) AS expected_transfers,
        COUNT_IF(has_token_transfer) AS expected_transactions_with_transfers,
        SUM(gas_used) AS expected_gas_used
    FROM ETHEREUM_PORTFOLIO.ANALYTICS.INT_TRANSACTIONS_WITH_TRANSFERS
),
mart_totals AS (
    SELECT
        SUM(transaction_count) AS actual_transactions,
        SUM(token_transfer_count) AS actual_transfers,
        SUM(transactions_with_transfers) AS actual_transactions_with_transfers,
        SUM(total_gas_used) AS actual_gas_used
    FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TRANSACTION_ACTIVITY
)
SELECT
    m.actual_transactions,
    i.expected_transactions,
    m.actual_transfers,
    i.expected_transfers,
    m.actual_transactions_with_transfers,
    i.expected_transactions_with_transfers,
    m.actual_gas_used,
    i.expected_gas_used
FROM mart_totals m
CROSS JOIN intermediate_totals i;
