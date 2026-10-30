
-- ============================================================
-- 06_INSPECT_STAGING_SOURCE.SQL
-- ============================================================
--
-- PURPOSE
-- Inspect the structure and values of a raw Ethereum
-- transaction record before developing the dbt staging model.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet.
-- Read-only: does not modify any database objects.
--
-- ============================================================


-- ============================================================
-- STEP 1: INSPECT A RAW TRANSACTION RECORD
-- ============================================================
--
-- The RAW_RECORD column contains semi-structured data
-- stored as a Snowflake VARIANT.
--
-- Inspect the available fields and their representations
-- to determine appropriate transformations and data types
-- for the stg_transactions dbt model.
--
-- LIMIT 1 returns a sample record, not necessarily the
-- same record on every execution.
-- ============================================================

SELECT
    RAW_RECORD
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS
LIMIT 1;
