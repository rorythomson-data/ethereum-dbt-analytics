-- ============================================================
-- TEST_S3_INGESTION.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Verify Parquet-to-VARIANT ingestion using an isolated
-- temporary table without modifying permanent RAW data.
--
-- EXECUTION
-- Snowflake SQL worksheet, after external stage setup.
-- All statements run within the same Snowflake session.
--
-- This is a manual ingestion test, separate from dbt tests.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE TEMPORARY TEST TABLE
-- ============================================================

-- Isolate ingestion testing from permanent RAW tables.
-- Temporary tables are scoped to the current session.

CREATE OR REPLACE TEMPORARY TABLE
    ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST (
        RAW_RECORD VARIANT
    );


-- ============================================================
-- STEP 2: TEST TRANSACTION INGESTION
-- ============================================================

-- Load a 100-record sample from the selected historical
-- partition to validate Parquet-to-VARIANT ingestion.

INSERT INTO ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST
    (RAW_RECORD)
SELECT $1
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE/date=2024-01-15/
LIMIT 100;


-- ============================================================
-- STEP 3: VALIDATE ROW COUNT AND RECORD STRUCTURE
-- ============================================================

-- Check sample completeness and detect NULL records.

SELECT
    COUNT(*) AS ROW_COUNT,
    COUNT_IF(RAW_RECORD IS NULL OR IS_NULL_VALUE(RAW_RECORD))
        AS NULL_RECORD_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST;


-- Inspect key fields to verify source structure and
-- compatibility with subsequent dbt staging models.

SELECT
    RAW_RECORD:hash::STRING AS TRANSACTION_HASH,
    RAW_RECORD:from_address::STRING AS FROM_ADDRESS,
    RAW_RECORD:to_address::STRING AS TO_ADDRESS,
    RAW_RECORD:block_timestamp::STRING AS BLOCK_TIMESTAMP
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST
LIMIT 5;


-- ============================================================
-- STEP 4: VALIDATE TRANSACTION IDENTIFIERS
-- ============================================================

-- Check transaction hash completeness and uniqueness.
-- Duplicate counts exclude NULL identifiers.

SELECT
    COUNT_IF(RAW_RECORD:hash IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:hash))
        AS MISSING_HASH_COUNT,

    COUNT(RAW_RECORD:hash::STRING)
        - COUNT(DISTINCT RAW_RECORD:hash::STRING)
        AS DUPLICATE_HASH_COUNT

FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST;


-- ============================================================
-- STEP 5: CLEAN UP TEMPORARY RESOURCES
-- ============================================================

-- Remove the test table without affecting permanent data.

DROP TABLE IF EXISTS
    ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS_INGESTION_TEST;
