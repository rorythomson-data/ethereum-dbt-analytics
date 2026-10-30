
-- ============================================================
-- 11_VALIDATE_STG_CONTRACTS.SQL
-- ============================================================
--
-- PURPOSE
-- Validate staging contract row counts, completeness,
-- timestamp conversion and repeated contract addresses.
--
-- EXECUTION
-- Run manually in a Snowflake SQL worksheet after
-- executing: dbt run --select stg_contracts
--
-- Read-only: does not modify database objects.
--
-- EXPECTED RESULTS FOR CURRENT SAMPLE
-- Total records:                  1,000
-- Distinct contract addresses:      999
-- NULL contract addresses:            0
-- NULL block timestamps:             0
-- Repeated addresses:                1
-- ============================================================


-- ============================================================
-- STEP 1: VALIDATE STAGING CONTRACTS
-- ============================================================

WITH address_counts AS (

    SELECT
        contract_address,
        COUNT(*) AS record_count
    FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_CONTRACTS
    WHERE contract_address IS NOT NULL
    GROUP BY contract_address

)

SELECT
    (SELECT COUNT(*)
     FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_CONTRACTS)
        AS total_records,

    (SELECT COUNT(*)
     FROM address_counts)
        AS distinct_contract_addresses,

    (SELECT COUNT_IF(contract_address IS NULL)
     FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_CONTRACTS)
        AS null_contract_addresses,

    (SELECT COUNT_IF(block_timestamp IS NULL)
     FROM ETHEREUM_PORTFOLIO.ANALYTICS.STG_CONTRACTS)
        AS null_timestamps,

    (SELECT COUNT_IF(record_count > 1)
     FROM address_counts)
        AS repeated_addresses;