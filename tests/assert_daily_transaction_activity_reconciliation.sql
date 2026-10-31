
-- ============================================================
-- ASSERT_DAILY_TRANSACTION_ACTIVITY_RECONCILIATION.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Reconcile daily transaction activity metrics against
-- independently aggregated intermediate transaction records.
--
-- EXECUTION
-- Compiled by dbt Core and executed in Snowflake.
-- A singular dbt test passes when this query returns zero rows.
--
-- ============================================================


-- 1. Calculate expected daily metrics from intermediate data.
-- Each intermediate record represents one transaction.

WITH expected_daily AS (

    SELECT
        CAST(block_timestamp AS DATE) AS activity_date,
        COUNT(*) AS expected_transaction_count,
        SUM(transfer_count) AS expected_token_transfer_count,
        COUNT_IF(has_token_transfer) AS expected_transactions_with_transfers,
        AVG(transfer_count) AS expected_avg_transfers_per_transaction,
        SUM(gas_used) AS expected_total_gas_used,
        AVG(gas_used) AS expected_avg_gas_used

    FROM {{ ref('int_transactions_with_transfers') }}

    GROUP BY CAST(block_timestamp AS DATE)

),


-- 2. Reference the actual daily activity mart.

actual_daily AS (

    SELECT
        activity_date,
        transaction_count,
        token_transfer_count,
        transactions_with_transfers,
        avg_transfers_per_transaction,
        total_gas_used,
        avg_gas_used

    FROM {{ ref('fct_daily_transaction_activity') }}

),


-- 3. Compare expected and actual metrics by date.
-- A FULL OUTER JOIN detects missing dates on either side.
-- Null-safe comparisons also detect mismatches involving NULLs.

reconciled AS (

    SELECT
        COALESCE(a.activity_date, e.activity_date) AS activity_date,

        a.transaction_count,
        e.expected_transaction_count,

        a.token_transfer_count,
        e.expected_token_transfer_count,

        a.transactions_with_transfers,
        e.expected_transactions_with_transfers,

        a.avg_transfers_per_transaction,
        e.expected_avg_transfers_per_transaction,

        a.total_gas_used,
        e.expected_total_gas_used,

        a.avg_gas_used,
        e.expected_avg_gas_used,

        a.activity_date IS NULL AS missing_from_mart,
        e.activity_date IS NULL AS missing_from_source

    FROM actual_daily a
    FULL OUTER JOIN expected_daily e
        ON a.activity_date = e.activity_date

)


-- 4. Return only missing dates or mismatched metrics.
-- Zero returned rows indicate successful reconciliation.

SELECT *
FROM reconciled

WHERE
    missing_from_mart
    OR missing_from_source

    OR transaction_count IS DISTINCT FROM expected_transaction_count
    OR token_transfer_count IS DISTINCT FROM expected_token_transfer_count
    OR transactions_with_transfers IS DISTINCT FROM expected_transactions_with_transfers

    OR ABS(avg_transfers_per_transaction - expected_avg_transfers_per_transaction) > 0.000001
    OR total_gas_used IS DISTINCT FROM expected_total_gas_used
    OR ABS(avg_gas_used - expected_avg_gas_used) > 0.000001

    OR (avg_transfers_per_transaction IS NULL) <> (expected_avg_transfers_per_transaction IS NULL)
    OR (avg_gas_used IS NULL) <> (expected_avg_gas_used IS NULL)
