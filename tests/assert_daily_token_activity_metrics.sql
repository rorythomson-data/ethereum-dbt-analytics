-- ============================================================
-- ASSERT_DAILY_TOKEN_ACTIVITY_METRICS.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Verify logical consistency of daily token activity metrics.
--
-- EXECUTION
-- Compiled by dbt Core and executed in Snowflake.
-- The test passes when this query returns zero rows.
-- ============================================================

-- 1. Identify date/token combinations with invalid metrics.
-- Each transaction and participant count must be positive
-- and cannot exceed the number of transfer events.
SELECT
    activity_date,
    token_address,
    transfer_count,
    transaction_count,
    unique_senders,
    unique_receivers
FROM {{ ref('fct_daily_token_activity') }}
WHERE
    transfer_count < 1
    OR transaction_count < 1
    OR transaction_count > transfer_count
    OR unique_senders < 1
    OR unique_senders > transfer_count
    OR unique_receivers < 1
    OR unique_receivers > transfer_count