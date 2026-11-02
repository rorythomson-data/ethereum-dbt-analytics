
-- ============================================================
-- FCT_DAILY_TOKEN_ACTIVITY.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Aggregate token-transfer events into daily, token-level
-- activity metrics for downstream analytics and reporting.
--
-- GRAIN
-- One row per activity_date and token_address.
--
-- MATERIALIZATION
-- Table, configured in dbt_project.yml.
--
-- EXECUTION
-- Compiled by dbt Core and executed in Snowflake.
--
-- DATA SCOPE
-- Metrics describe sampled token-transfer activity, not
-- total Ethereum network activity.
-- ============================================================

-- 1. Reference standardized token-transfer events.
-- Each source row represents one transfer event.
WITH transfers AS (
    SELECT
        {{ to_activity_date('block_timestamp') }} AS activity_date,
        token_address,
        transaction_hash,
        from_address,
        to_address
    FROM {{ ref('stg_token_transfers') }}
),

-- 2. Aggregate activity by date and token contract.
-- Distinct counts prevent repeated events from inflating
-- transaction and participant metrics.
daily_token_activity AS (
    SELECT
        activity_date,
        token_address,
        COUNT(*) AS transfer_count,
        COUNT(DISTINCT transaction_hash) AS transaction_count,
        COUNT(DISTINCT from_address) AS unique_senders,
        COUNT(DISTINCT to_address) AS unique_receivers
    FROM transfers
    GROUP BY
        activity_date,
        token_address
)

-- 3. Return the final daily token activity dataset.
SELECT
    activity_date,
    token_address,
    transfer_count,
    transaction_count,
    unique_senders,
    unique_receivers
FROM daily_token_activity
