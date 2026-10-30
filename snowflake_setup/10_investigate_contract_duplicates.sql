
-- ============================================================
-- 10_INVESTIGATE_CONTRACT_DUPLICATES.SQL
-- ============================================================
--
-- PURPOSE
-- Investigate duplicate contract addresses in RAW.CONTRACTS
-- before defining the grain and deduplication strategy
-- for the stg_contracts dbt model.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet.
-- Read-only: does not modify database objects.
--
-- BACKGROUND
-- RAW validation identified one repeated contract address.
-- The records have different block numbers and timestamps.
-- ============================================================


-- ============================================================
-- STEP 1: IDENTIFY DUPLICATE CONTRACT ADDRESSES
-- ============================================================

SELECT
    RAW_RECORD:address::VARCHAR AS contract_address,
    COUNT(*) AS record_count
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- ============================================================
-- STEP 2: COMPARE RECORDS FOR DUPLICATE ADDRESSES
-- ============================================================
--
-- Compare block metadata, transaction identifiers,
-- bytecode and source modification timestamps.
-- ============================================================

WITH contracts AS (

    SELECT
        RAW_RECORD:address::VARCHAR AS contract_address,
        RAW_RECORD:block_number::NUMBER(38, 0) AS block_number,
        RAW_RECORD:block_hash::VARCHAR AS block_hash,
        RAW_RECORD:block_timestamp::VARCHAR AS block_timestamp,
        RAW_RECORD:transaction_hash::VARCHAR AS transaction_hash,
        RAW_RECORD:bytecode::VARCHAR AS bytecode,
        RAW_RECORD:last_modified::VARCHAR AS last_modified
    FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS

)

SELECT *
FROM contracts
WHERE contract_address IN (

    SELECT contract_address
    FROM contracts
    GROUP BY contract_address
    HAVING COUNT(*) > 1

)
ORDER BY contract_address, block_number;


-- ============================================================
-- STEP 3: INSPECT COMPLETE CONTRACT RECORD STRUCTURE
-- ============================================================
--
-- Inspect the original semi-structured record to identify
-- fields required for the staging model.
-- ============================================================

SELECT
    RAW_RECORD
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS
LIMIT 1;