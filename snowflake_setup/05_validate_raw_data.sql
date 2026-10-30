
-- ============================================================
-- 05_VALIDATE_RAW_DATA.SQL
-- ============================================================
--
-- PURPOSE
-- Validate completeness, uniqueness, and referential
-- integrity across the Ethereum RAW datasets.
--
-- EXECUTION
-- Snowflake SQL worksheet, after 04_load_raw_data.sql.
-- Requires SELECT access to the three RAW tables.
--
-- VALIDATION STRATEGY
-- Check source identifiers, duplicate records, and
-- relationships before downstream dbt transformations.
--
-- Validation queries are read-only and do not modify
-- the underlying RAW data.
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE TRANSACTION RECORDS
-- ============================================================

-- Check sample size, identifier completeness, and
-- uniqueness of transaction hashes.

SELECT
    COUNT(*) AS TRANSACTION_COUNT,
    COUNT_IF(
        RAW_RECORD:hash IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:hash)
    ) AS MISSING_HASH_COUNT,
    COUNT(RAW_RECORD:hash::STRING)
        - COUNT(DISTINCT RAW_RECORD:hash::STRING)
        AS DUPLICATE_HASH_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS;


-- ============================================================
-- STEP 2: VALIDATE TOKEN TRANSFER RECORDS
-- ============================================================

-- Check transfer identifiers and duplicate event keys.
-- A transaction may contain multiple transfers, identified
-- by the combination of transaction hash and log index.

SELECT
    COUNT(*) AS TRANSFER_COUNT,
    COUNT_IF(
        RAW_RECORD:transaction_hash IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:transaction_hash)
    ) AS MISSING_TRANSACTION_HASH_COUNT,
    COUNT_IF(
        RAW_RECORD:log_index IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:log_index)
    ) AS MISSING_LOG_INDEX_COUNT,
    COUNT(*) - COUNT(DISTINCT
        CASE
            WHEN RAW_RECORD:transaction_hash IS NOT NULL
                AND NOT IS_NULL_VALUE(RAW_RECORD:transaction_hash)
                AND RAW_RECORD:log_index IS NOT NULL
                AND NOT IS_NULL_VALUE(RAW_RECORD:log_index)
            THEN
                RAW_RECORD:transaction_hash::STRING
                || ':'
                || RAW_RECORD:log_index::STRING
        END
    ) AS NON_UNIQUE_OR_MISSING_EVENT_KEY_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS;


-- ============================================================
-- STEP 3: VALIDATE REFERENTIAL INTEGRITY
-- ============================================================

-- Identify token transfers without a matching transaction.
-- The relationship-aware ingestion strategy should ensure
-- that all transfer hashes exist in RAW.TRANSACTIONS.

SELECT
    COUNT(*) AS ORPHAN_TRANSFER_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS t
WHERE NOT EXISTS (
    SELECT 1
    FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS tx
    WHERE tx.RAW_RECORD:hash::STRING =
          t.RAW_RECORD:transaction_hash::STRING
);


-- ============================================================
-- STEP 4: VALIDATE SMART CONTRACT RECORDS
-- ============================================================

-- Check contract sample size, address completeness,
-- and duplicate contract addresses.

SELECT
    COUNT(*) AS CONTRACT_COUNT,
    COUNT_IF(
        RAW_RECORD:address IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:address)
    ) AS MISSING_ADDRESS_COUNT,
    COUNT(RAW_RECORD:address::STRING)
        - COUNT(DISTINCT RAW_RECORD:address::STRING)
        AS DUPLICATE_ADDRESS_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS;


-- ============================================================
-- STEP 5: VALIDATE DATASET COVERAGE
-- ============================================================

-- Summarise loaded record counts and the number of
-- transactions represented in the token-transfer dataset.

SELECT
    (SELECT COUNT(*)
     FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS)
        AS TRANSACTION_COUNT,

    (SELECT COUNT(*)
     FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS)
        AS TRANSFER_COUNT,

    (SELECT COUNT(DISTINCT RAW_RECORD:transaction_hash::STRING)
     FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS)
        AS TRANSACTIONS_WITH_TRANSFERS,

    (SELECT COUNT(*)
     FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS)
        AS CONTRACT_COUNT;


SELECT
    RAW_RECORD:address::STRING AS CONTRACT_ADDRESS,
    COUNT(*) AS RECORD_COUNT,
    COUNT(DISTINCT TO_JSON(RAW_RECORD)) AS DISTINCT_RECORD_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS
GROUP BY 1
HAVING COUNT(*) > 1;

SELECT
    RAW_RECORD:address::STRING AS CONTRACT_ADDRESS,
    RAW_RECORD:block_timestamp::STRING AS BLOCK_TIMESTAMP,
    RAW_RECORD:block_number::STRING AS BLOCK_NUMBER,
    RAW_RECORD:transaction_hash::STRING AS TRANSACTION_HASH,
    RAW_RECORD
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS
WHERE RAW_RECORD:address::STRING =
    '0x00ddede78cdb1c76d33c8029799aa60d5e566b38';