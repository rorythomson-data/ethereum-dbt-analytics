
-- ============================================================
-- STG_TOKEN_TRANSFERS.SQL
-- ============================================================
--
-- PURPOSE
-- Extract and standardize Ethereum token transfer events
-- from semi-structured RAW records.
--
-- GRAIN
-- One row per transaction hash and log index.
--
-- MATERIALIZATION
-- View, configured in dbt_project.yml.
-- ============================================================

WITH source AS (

    SELECT RAW_RECORD
    FROM {{ source('ethereum_raw', 'token_transfers') }}

),

renamed AS (

    SELECT
        RAW_RECORD:transaction_hash::VARCHAR AS transaction_hash,
        RAW_RECORD:log_index::INTEGER AS log_index,

        RAW_RECORD:block_hash::VARCHAR AS block_hash,
        RAW_RECORD:block_number::NUMBER(38, 0) AS block_number,
        TRY_TO_TIMESTAMP_NTZ(
            RAW_RECORD:block_timestamp::VARCHAR
        ) AS block_timestamp,

        RAW_RECORD:token_address::VARCHAR AS token_address,
        RAW_RECORD:from_address::VARCHAR AS from_address,
        RAW_RECORD:to_address::VARCHAR AS to_address,

        RAW_RECORD:value::NUMBER(38, 0) AS value_raw

    FROM source

)

SELECT *
FROM renamed
