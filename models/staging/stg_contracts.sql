
-- ============================================================
-- STG_CONTRACTS.SQL
-- ============================================================
--
-- PURPOSE
-- Extract and standardize Ethereum contract records
-- from semi-structured RAW data.
--
-- GRAIN
-- One row per source contract record.
-- Contract addresses are not guaranteed to be unique.
--
-- MATERIALIZATION
-- View, configured in dbt_project.yml.
--
-- DATA QUALITY NOTE
-- The sampled source contains two records with the same
-- contract address but different block metadata.
-- Both records are preserved for downstream analysis.
-- ============================================================

WITH source AS (

    SELECT RAW_RECORD
    FROM {{ source('ethereum_raw', 'contracts') }}

),

renamed AS (

    SELECT
        RAW_RECORD:address::VARCHAR AS contract_address,
        RAW_RECORD:block_hash::VARCHAR AS block_hash,
        RAW_RECORD:block_number::NUMBER(38, 0) AS block_number,

        TRY_TO_TIMESTAMP_NTZ(
            RAW_RECORD:block_timestamp::VARCHAR
        ) AS block_timestamp,

        RAW_RECORD:bytecode::VARCHAR AS bytecode,

        TRY_TO_DATE(
            RAW_RECORD:date::VARCHAR
        ) AS record_date,

        TRY_TO_TIMESTAMP_NTZ(
            RAW_RECORD:last_modified::VARCHAR
        ) AS last_modified

    FROM source

)

SELECT *
FROM renamed
