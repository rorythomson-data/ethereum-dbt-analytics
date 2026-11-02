-- ============================================================
-- 18_VALIDATE_NEW_INCREMENTAL_PARTITION.SQL
-- ============================================================
--
-- PURPOSE
-- Validate incremental processing of January 17 data
-- in the daily token activity mart.
--
-- EXECUTION
-- Snowflake SQL worksheet, after running the dbt
-- incremental model without --full-refresh.
-- ============================================================

-- ============================================================
-- STEP 1: VALIDATE DAILY TOKEN ACTIVITY
-- ============================================================

-- Confirm that January 17 was added and that the
-- previously processed dates retain their totals.

SELECT
    activity_date,
    COUNT(*) AS token_rows,
    SUM(transfer_count) AS total_transfers
FROM ETHEREUM_PORTFOLIO.ANALYTICS.FCT_DAILY_TOKEN_ACTIVITY
GROUP BY activity_date
ORDER BY activity_date;


-- ============================================================
-- STEP 2: VALIDATE INCREMENTAL MERGE-KEY UNIQUENESS
-- ============================================================

-- Verify that each activity_date and token_address
-- combination appears only once in the incremental mart.

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
-- STEP 3: RECONCILE INCREMENTAL MART WITH STAGING
-- ============================================================

-- Compare transfer counts by date across staging and mart.
-- Flag missing dates or discrepancies in either direction.

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