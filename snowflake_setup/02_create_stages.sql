
-- ============================================================
-- 02_CREATE_STAGES.SQL
-- ============================================================
--
-- PURPOSE
-- Configure external stages for accessing public Ethereum
-- blockchain data stored in Amazon S3.
--
-- DATA SOURCE
-- AWS Public Blockchain Data:
-- https://registry.opendata.aws/aws-public-blockchain/
--
-- Datasets: transactions, token transfers, smart contracts.
--
-- EXECUTION
-- Snowflake SQL worksheet, after 01_create_resources.sql.
-- Requires privileges to create stages in the RAW schema.
--
-- External stages reference S3 data without copying it
-- into Snowflake. IF NOT EXISTS preserves existing stages
-- on subsequent executions.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE TRANSACTIONS EXTERNAL STAGE
-- ============================================================

-- Reference Ethereum transaction records, including hashes,
-- addresses, timestamps, transferred values, and gas usage.

CREATE STAGE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE
    URL = 's3://aws-public-blockchain/v1.0/eth/transactions/'
    FILE_FORMAT = (TYPE = PARQUET);


-- ============================================================
-- STEP 2: CREATE TOKEN TRANSFERS EXTERNAL STAGE
-- ============================================================

-- Reference token-transfer events emitted by smart contracts.
-- Multiple transfers may share a transaction hash, allowing
-- transfers to be associated with their parent transaction.

CREATE STAGE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE
    URL = 's3://aws-public-blockchain/v1.0/eth/token_transfers/'
    FILE_FORMAT = (TYPE = PARQUET);


-- ============================================================
-- STEP 3: CREATE CONTRACTS EXTERNAL STAGE
-- ============================================================

-- Reference smart contract creation records, including
-- contract addresses, deployment blocks, and bytecode.
-- Contract addresses support enrichment where matching
-- contract records are available.

CREATE STAGE IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW.ETH_CONTRACTS_STAGE
    URL = 's3://aws-public-blockchain/v1.0/eth/contracts/'
    FILE_FORMAT = (TYPE = PARQUET);


-- ============================================================
-- STEP 4: VERIFY EXTERNAL STAGE ACCESS
-- ============================================================

-- Check S3 file visibility for the selected development
-- partition (2024-01-15). PATTERN filters the file listing
-- but does not guarantee partition-pruned S3 listing.

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE
    PATTERN = '.*date=2024-01-15/.*';

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE
    PATTERN = '.*date=2024-01-15/.*';

LIST @ETHEREUM_PORTFOLIO.RAW.ETH_CONTRACTS_STAGE
    PATTERN = '.*date=2024-01-15/.*';
