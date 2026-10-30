
-- ============================================================
-- 03_INSPECT_DATA.SQL
-- ============================================================
--
-- PURPOSE
-- Inspect the structure and availability of Ethereum
-- blockchain data stored in external S3 Parquet files.
--
-- Verify source fields, data types, and file availability
-- before defining the raw ingestion strategy.
--
-- EXECUTION
-- Snowflake SQL worksheet, after 01_create_resources.sql
-- and 02_create_stages.sql.
-- Requires SELECT access to the external stages and
-- USAGE privileges on the compute warehouse.
--
-- Inspection queries do not modify source or target data.
-- The selected development partition is 2024-01-15.
-- ============================================================


-- ============================================================
-- STEP 1: SELECT COMPUTE WAREHOUSE
-- ============================================================

-- Use the dedicated project warehouse for source inspection.

USE WAREHOUSE DBT_WH;


-- ============================================================
-- STEP 2: INSPECT TRANSACTION RECORDS
-- ============================================================

-- Examine transaction fields and source file metadata.
-- Parquet records are exposed as semi-structured values.

SELECT
    METADATA$FILENAME AS source_file,
    $1 AS record
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE/date=2024-01-15/
LIMIT 5;


-- ============================================================
-- STEP 3: INSPECT TOKEN TRANSFER RECORDS
-- ============================================================

-- Examine token-transfer events and their identifiers,
-- including transaction hashes and token addresses.

SELECT
    METADATA$FILENAME AS source_file,
    $1 AS record
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-15/
LIMIT 5;


-- ============================================================
-- STEP 4: INSPECT SMART CONTRACT RECORDS
-- ============================================================

-- Examine contract creation records, including contract
-- addresses, block information, and deployed bytecode.

SELECT
    METADATA$FILENAME AS source_file,
    $1 AS record
FROM @ETHEREUM_PORTFOLIO.RAW.ETH_CONTRACTS_STAGE/date=2024-01-15/
LIMIT 5;


-- ============================================================
-- STEP 5: VERIFY HISTORICAL PARTITION AVAILABILITY
-- ============================================================

-- Confirm that all three datasets contain files for the
-- selected development date. PATTERN filters file listings
-- but does not guarantee partition-pruned S3 listing.

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE
    PATTERN = '.*date=2024-01-15/.*';

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE
    PATTERN = '.*date=2024-01-15/.*';

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_CONTRACTS_STAGE
    PATTERN = '.*date=2024-01-15/.*';
