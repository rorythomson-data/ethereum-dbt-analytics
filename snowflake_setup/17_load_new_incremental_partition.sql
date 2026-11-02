-- ============================================================
-- 17_LOAD_NEW_INCREMENTAL_PARTITION.SQL
-- ============================================================
--
-- PURPOSE
-- Extend the RAW development sample with a second
-- historical partition while preserving existing records.
--
-- EXECUTION
-- Snowflake SQL worksheet.
--
-- DATA SCOPE
-- January 17, 2024. Transaction hashes are selected from
-- token-transfer events to preserve source relationships.
-- ============================================================

-- ============================================================
-- STEP 1: VERIFY THE JANUARY 17 TRANSACTION SAMPLE
-- ============================================================

-- Select a deterministic sample of transaction hashes.
-- Check whether any selected hashes already exist in RAW.
-- The subsequent MERGE statements prevent duplicate inserts.
-- This is a read-only check; no records are inserted.

WITH selected_hashes AS (
    SELECT DISTINCT
        $1:transaction_hash::STRING AS transaction_hash
    FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-17/
    WHERE $1:transaction_hash IS NOT NULL
    ORDER BY transaction_hash
    LIMIT 1000
)
SELECT
    COUNT(*) AS selected_transaction_hashes,
    COUNT_IF(tx.RAW_RECORD IS NOT NULL) AS already_in_raw
FROM selected_hashes sh
LEFT JOIN ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS tx
    ON sh.transaction_hash = tx.RAW_RECORD:hash::STRING;


-- ============================================================
-- STEP 2: APPEND JANUARY 17 TRANSACTIONS
-- ============================================================

-- Select the same deterministic sample of 1,000 transaction
-- hashes used in the preliminary validation.
--
-- MERGE inserts transactions that are absent from RAW.
-- Matching hashes are left unchanged, making reruns
-- idempotent without truncating existing records.

MERGE INTO ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS AS target
USING (
    WITH selected_hashes AS (
        SELECT DISTINCT
            $1:transaction_hash::STRING AS transaction_hash
        FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-17/
        WHERE $1:transaction_hash IS NOT NULL
        ORDER BY transaction_hash
        LIMIT 1000
    )
    SELECT
        tx.$1 AS raw_record,
        tx.$1:hash::STRING AS transaction_hash
    FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TRANSACTIONS_STAGE/date=2024-01-17/ tx
    INNER JOIN selected_hashes sh
        ON tx.$1:hash::STRING = sh.transaction_hash
) AS source
ON target.RAW_RECORD:hash::STRING = source.transaction_hash

WHEN NOT MATCHED THEN
    INSERT (RAW_RECORD)
    VALUES (source.raw_record);


-- ============================================================
-- STEP 3: VALIDATE TRANSACTION APPEND
-- ============================================================

-- Verify the daily counts and transaction-key uniqueness.

SELECT
    TO_DATE(RAW_RECORD:block_timestamp::TIMESTAMP_NTZ) AS activity_date,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT RAW_RECORD:hash::STRING) AS distinct_transactions
FROM ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- STEP 4: APPEND JANUARY 17 TOKEN TRANSFERS
-- ============================================================

-- Load all transfer events associated with the selected
-- January 17 transactions.
--
-- Match transactions by hash and restrict them to the
-- January 17 partition.
--
-- MERGE uses transaction_hash and log_index as the event
-- key to prevent duplicate transfers on repeated runs.

MERGE INTO ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS AS target
USING (
    SELECT
        t.$1 AS raw_record,
        t.$1:transaction_hash::STRING AS transaction_hash,
        t.$1:log_index::NUMBER AS log_index
    FROM @ETHEREUM_PORTFOLIO.RAW.ETH_TOKEN_TRANSFERS_STAGE/date=2024-01-17/ t
    INNER JOIN ETHEREUM_PORTFOLIO.RAW.TRANSACTIONS tx
        ON t.$1:transaction_hash::STRING =
           tx.RAW_RECORD:hash::STRING
    WHERE TO_DATE(
        tx.RAW_RECORD:block_timestamp::TIMESTAMP_NTZ
    ) = '2024-01-17'
      AND t.$1:log_index IS NOT NULL
) AS source
ON target.RAW_RECORD:transaction_hash::STRING =
   source.transaction_hash
AND target.RAW_RECORD:log_index::NUMBER =
    source.log_index

WHEN NOT MATCHED THEN
    INSERT (RAW_RECORD)
    VALUES (source.raw_record);


-- ============================================================
-- STEP 5: VALIDATE TOKEN TRANSFER APPEND
-- ============================================================

-- Check daily transfer counts, transaction coverage,
-- and uniqueness of the composite transfer-event key.

SELECT
    TO_DATE(RAW_RECORD:block_timestamp::TIMESTAMP_NTZ)
        AS activity_date,
    COUNT(*) AS transfer_count,
    COUNT(DISTINCT RAW_RECORD:transaction_hash::STRING)
        AS distinct_transactions,
    COUNT(DISTINCT
        RAW_RECORD:transaction_hash::STRING
        || ':' ||
        RAW_RECORD:log_index::STRING
    ) AS distinct_transfer_events
FROM ETHEREUM_PORTFOLIO.RAW.TOKEN_TRANSFERS
GROUP BY 1
ORDER BY 1;