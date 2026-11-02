
-- ============================================================
-- ASSERT_DAILY_TOKEN_ACTIVITY_RECONCILIATION.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Reconcile daily token activity metrics against independently
-- aggregated staging transfer events.
--
-- EXECUTION
-- Compiled by dbt Core and executed in Snowflake.
-- A singular dbt test passes when this query returns zero rows.
-- ============================================================

-- 1. Independently calculate expected token activity metrics.
-- Each staging record represents one token-transfer event.
WITH expected_daily AS (
    SELECT
        CAST(block_timestamp AS DATE) AS activity_date,
        token_address,
        COUNT(*) AS expected_transfer_count,
        COUNT(DISTINCT transaction_hash) AS expected_transaction_count,
        COUNT(DISTINCT from_address) AS expected_unique_senders,
        COUNT(DISTINCT to_address) AS expected_unique_receivers
    FROM {{ ref('stg_token_transfers') }}
    GROUP BY
        CAST(block_timestamp AS DATE),
        token_address
),

-- 2. Reference the materialized analytics mart.
actual_daily AS (
    SELECT
        activity_date,
        token_address,
        transfer_count,
        transaction_count,
        unique_senders,
        unique_receivers
    FROM {{ ref('fct_daily_token_activity') }}
),

-- 3. Match expected and actual records using the mart grain.
-- A FULL OUTER JOIN also detects missing or unexpected rows.
reconciled AS (
    SELECT
        COALESCE(a.activity_date, e.activity_date) AS activity_date,
        COALESCE(a.token_address, e.token_address) AS token_address,
        a.activity_date IS NULL AS missing_from_mart,
        e.activity_date IS NULL AS missing_from_source,
        a.transfer_count,
        e.expected_transfer_count,
        a.transaction_count,
        e.expected_transaction_count,
        a.unique_senders,
        e.expected_unique_senders,
        a.unique_receivers,
        e.expected_unique_receivers
    FROM actual_daily a
    FULL OUTER JOIN expected_daily e
        ON a.activity_date = e.activity_date
        AND a.token_address = e.token_address
)

-- 4. Return only missing records or mismatched metrics.
-- Zero returned rows indicate successful reconciliation.
SELECT *
FROM reconciled
WHERE
    missing_from_mart
    OR missing_from_source
    OR transfer_count IS DISTINCT FROM expected_transfer_count
    OR transaction_count IS DISTINCT FROM expected_transaction_count
    OR unique_senders IS DISTINCT FROM expected_unique_senders
    OR unique_receivers IS DISTINCT FROM expected_unique_receivers
