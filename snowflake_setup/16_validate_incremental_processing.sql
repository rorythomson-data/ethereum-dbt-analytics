
-- ============================================================
-- 16_VALIDATE_INCREMENTAL_PROCESSING.SQL
-- ============================================================
--
-- PURPOSE
-- Validate the daily token activity incremental model,
-- including date coverage, source reconciliation, and
-- uniqueness of the model's merge key.
--
-- EXECUTION
-- Snowflake SQL worksheet, after running the dbt model.
-- All statements are read-only.
--
-- DATA SCOPE
-- Results describe sampled Ethereum token-transfer activity,
-- not total network activity.
--
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE DAILY ACTIVITY COVERAGE
-- ============================================================
-- Confirm that both January 15 and January 16 are present.
-- Compare aggregated transfer counts with the expected
-- sample sizes loaded into RAW.TOKEN_TRANSFERS.
--
-- Expected:
-- 2024-01-15: 1,779 transfers
-- 2024-01-16: 1,793 transfers
-- These totals assume all source events have valid token
-- addresses and pass the staging model's filters.

SELECT
    activity_date,
    COUNT(*) AS token_rows,
    SUM(transfer_count) AS total_transfers
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
GROUP BY activity_date
ORDER BY activity_date;


-- ============================================================
-- STEP 2: VALIDATE INCREMENTAL MERGE KEY UNIQUENESS
-- ============================================================
-- Each activity_date and token_address combination must
-- appear only once in the incremental model.
--
-- Expected: 0 rows returned.

SELECT
    activity_date,
    token_address,
    COUNT(*) AS duplicate_count
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
GROUP BY
    activity_date,
    token_address
HAVING COUNT(*) > 1;


-- ============================================================
-- STEP 3: RECONCILE MODEL COUNTS WITH STAGING
-- ============================================================
-- Compare daily transfer totals in the incremental mart
-- against the standardized staging model.
--
-- Expected: MATCH for both dates.

WITH staging_counts AS (
    SELECT
        CAST(block_timestamp AS DATE) AS activity_date,
        COUNT(*) AS staging_transfers
    FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_TOKEN_TRANSFERS
    GROUP BY 1
),

mart_counts AS (
    SELECT
        activity_date,
        SUM(transfer_count) AS mart_transfers
    FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
    GROUP BY 1
)

SELECT
    COALESCE(s.activity_date, m.activity_date) AS activity_date,
    s.staging_transfers,
    m.mart_transfers,
    CASE
        WHEN s.staging_transfers = m.mart_transfers
            THEN 'MATCH'
        ELSE 'MISMATCH'
    END AS validation_status
FROM staging_counts s
FULL OUTER JOIN mart_counts m
    ON s.activity_date = m.activity_date
ORDER BY activity_date;


-- ============================================================
-- STEP 4: VALIDATE NULL MERGE KEYS
-- ============================================================
-- Null values in either component of the composite key
-- can prevent Snowflake MERGE from matching existing rows.
--
-- Expected: 0 rows with null keys.

SELECT
    COUNT(*) AS null_key_rows
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
WHERE activity_date IS NULL
   OR token_address IS NULL;


-- ============================================================
-- STEP 5: CAPTURE INCREMENTAL MODEL BASELINE
-- ============================================================
-- Record the current number of mart rows and total events.
-- Run this query before and after an incremental dbt run.
--
-- With unchanged source data, both values should remain
-- identical after rerunning the model.

SELECT
    COUNT(*) AS total_token_rows,
    COUNT(DISTINCT activity_date) AS activity_dates,
    SUM(transfer_count) AS total_transfers
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY;
