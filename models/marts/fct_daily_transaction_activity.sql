
-- ============================================================
-- FCT_DAILY_TRANSACTION_ACTIVITY.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Aggregate transaction-level data into daily activity metrics
-- for downstream analytics and reporting.
--
-- GRAIN
-- One row per activity_date.
--
-- MATERIALIZATION
-- Table, configured in dbt_project.yml.
--
-- EXECUTION
-- Compiled by dbt Core and executed in Snowflake.
--
-- DATA SCOPE
-- Metrics describe the sampled Ethereum transactions, not
-- total Ethereum network activity.
-- ============================================================


-- 1. Reference the validated intermediate transaction model.
-- Each source row represents one unique Ethereum transaction.

WITH transactions AS (

    SELECT
        transaction_hash,
        block_timestamp,
        transfer_count,
        has_token_transfer,
        gas_used

    FROM {{ ref('int_transactions_with_transfers') }}

),


-- 2. Aggregate transaction metrics by calendar date.
-- Casting the timestamp to DATE determines the daily grain.

daily_activity AS (

    SELECT
        CAST(block_timestamp AS DATE) AS activity_date,

        COUNT(*) AS transaction_count,

        SUM(transfer_count) AS token_transfer_count,

        COUNT_IF(has_token_transfer) AS transactions_with_transfers,

        AVG(transfer_count) AS avg_transfers_per_transaction,

        SUM(gas_used) AS total_gas_used,

        AVG(gas_used) AS avg_gas_used

    FROM transactions

    GROUP BY
        CAST(block_timestamp AS DATE)

)


-- 3. Return the final daily activity dataset.

SELECT
    activity_date,
    transaction_count,
    token_transfer_count,
    transactions_with_transfers,
    avg_transfers_per_transaction,
    total_gas_used,
    avg_gas_used

FROM daily_activity
