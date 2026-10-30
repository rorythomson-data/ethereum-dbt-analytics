
-- ============================================================
-- 08_INSPECT_TOKEN_TRANSFERS.SQL
-- ============================================================
--
-- PURPOSE
-- Inspect raw token transfer records to identify source
-- fields and appropriate data types for the dbt staging model.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet.
-- Read-only: does not modify database objects.
-- ============================================================

-- STEP 1: INSPECT A RAW TOKEN TRANSFER RECORD

SELECT
    RAW_RECORD
FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS
LIMIT 1;
