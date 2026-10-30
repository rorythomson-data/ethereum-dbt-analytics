
-- ============================================================
-- 04_LOAD_RAW_DATA.SQL
-- ============================================================
--
-- PURPOSE
-- Create and populate raw landing tables with Ethereum
-- transactions, token transfers, and smart contract records
-- sourced from public AWS S3 Parquet files.
--
-- Source records are preserved as VARIANT values for
-- subsequent transformation using dbt.
--
-- EXECUTION
-- Snowflake SQL worksheet, after 01_create_resources.sql,
-- 02_create_stages.sql, and 03_inspect_data.sql.
-- Requires access to the external stages and privileges
-- to create, insert into, and truncate RAW tables.
--
-- DEVELOPMENT STRATEGY
-- Load reproducible historical samples from 2024-01-15.
-- Transaction selection is based on hashes present in
-- token-transfer events to preserve relationships.
--
-- Smart contracts are sampled independently by address.
-- TRUNCATE replaces existing development data on reruns.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE RAW DATA TABLES
-- ============================================================

-- Preserve source records in VARIANT columns, separating
-- ingestion from schema enforcement and transformation.
-- dbt staging models will extract and standardize fields.

CREATE TABLE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS (
    RAW_RECORD VARIANT
);

CREATE TABLE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS (
    RAW_RECORD VARIANT
);

CREATE TABLE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.CONTRACTS (
    RAW_RECORD VARIANT
);


-- ============================================================
-- STEP 2: VERIFY TABLE CREATION
-- ============================================================

-- Inspect the raw landing tables.

SHOW TABLES IN SCHEMA ETHEREUM_PORTFOLIO.RAW;


-- ============================================================
-- STEP 3: LOAD TRANSACTION SAMPLE
-- ============================================================

-- Select the first 1,000 distinct transaction hashes from
-- token-transfer events, ordered by hash for reproducibility.
-- Load corresponding transaction records from the same
-- historical partition.
--
-- This relationship-aware sample ensures that selected
-- transactions have associated token-transfer events.
-- Determinism assumes unchanged source files and unique
-- transaction hashes.

TRUNCATE TABLE ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS;

INSERT INTO ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS (RAW_RECORD)
WITH selected_hashes AS (
    SELECT DISTINCT
        $1:transaction_hash::STRING AS transaction_hash
    FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-15/
    WHERE $1:transaction_hash IS NOT NULL
    ORDER BY transaction_hash
    LIMIT 1000
)
SELECT tx.$1
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE/date=2024-01-15/ tx
INNER JOIN selected_hashes sh
    ON tx.$1:hash::STRING = sh.transaction_hash;


-- ============================================================
-- STEP 4: VERIFY TRANSACTION LOAD
-- ============================================================

-- Check sample size and transaction hash completeness.

SELECT
    COUNT(*) AS ROW_COUNT,
    COUNT_IF(
        RAW_RECORD:hash IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:hash)
    ) AS MISSING_HASH_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS;


-- ============================================================
-- STEP 5: LOAD MATCHING TOKEN TRANSFERS
-- ============================================================

-- Retain all token-transfer events associated with the
-- selected transactions. A single transaction may produce
-- multiple transfer events.
--
-- Reloading after the transaction sample preserves
-- consistency between the two datasets.

TRUNCATE TABLE ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS;

INSERT INTO ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS (RAW_RECORD)
SELECT t.$1
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-15/ t
INNER JOIN ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS tx
    ON t.$1:transaction_hash::STRING =
       tx.RAW_RECORD:hash::STRING;


-- ============================================================
-- STEP 6: VERIFY TOKEN TRANSFER LOAD
-- ============================================================

-- Verify transfer coverage across the selected transactions.

SELECT
    COUNT(*) AS TRANSFER_COUNT,
    COUNT(DISTINCT RAW_RECORD:transaction_hash::STRING)
        AS DISTINCT_TRANSACTION_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS;


-- ============================================================
-- STEP 7: LOAD SMART CONTRACT SAMPLE
-- ============================================================

-- Select 1,000 contract creation records ordered by
-- contract address for reproducibility.
--
-- Contracts are sampled independently because contracts
-- created on this date may not correspond to token
-- contracts referenced by the selected transfers.

TRUNCATE TABLE ETHEREUM_PORTFOLIO.RAW.CONTRACTS;

INSERT INTO ETHEREUM_PORTFOLIO.RAW.CONTRACTS (RAW_RECORD)
SELECT $1
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_CONTRACTS_STAGE/date=2024-01-15/
ORDER BY $1:address::STRING
LIMIT 1000;


-- ============================================================
-- STEP 8: VERIFY CONTRACT LOAD
-- ============================================================

-- Check contract sample size and address completeness.

SELECT
    COUNT(*) AS CONTRACT_COUNT,
    COUNT_IF(
        RAW_RECORD:address IS NULL
        OR IS_NULL_VALUE(RAW_RECORD:address)
    ) AS MISSING_ADDRESS_COUNT
FROM ETHEREUM_PORTFOLIO.RAW.CONTRACTS;
