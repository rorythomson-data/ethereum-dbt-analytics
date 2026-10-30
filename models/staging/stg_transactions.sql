
-- ============================================================
-- STG_TRANSACTIONS.SQL
-- ============================================================
--
-- PURPOSE
-- Extract and standardize Ethereum transaction fields
-- from the RAW VARIANT records.
--
-- GRAIN
-- One row per Ethereum transaction hash.
--
-- MATERIALIZATION
-- View, configured in dbt_project.yml.
-- ============================================================

WITH source AS (

    SELECT RAW_RECORD
    FROM {{ source('ethereum_raw', 'transactions') }}

),

renamed AS (

    SELECT
        RAW_RECORD:hash::VARCHAR AS transaction_hash,
        RAW_RECORD:block_hash::VARCHAR AS block_hash,
        RAW_RECORD:block_number::NUMBER(38, 0) AS block_number,
        TRY_TO_TIMESTAMP_NTZ(
            RAW_RECORD:block_timestamp::VARCHAR
        ) AS block_timestamp,

        RAW_RECORD:from_address::VARCHAR AS from_address,
        NULLIF(
            RAW_RECORD:to_address::VARCHAR, ''
        ) AS to_address,

        RAW_RECORD:value::NUMBER(38, 0) AS value_wei,
        RAW_RECORD:gas::NUMBER(38, 0) AS gas_limit,
        RAW_RECORD:gas_price::NUMBER(38, 0) AS gas_price_wei,
        RAW_RECORD:receipt_gas_used::NUMBER(38, 0) AS gas_used,
        RAW_RECORD:receipt_status::INTEGER AS receipt_status,

        RAW_RECORD:transaction_index::INTEGER AS transaction_index,
        RAW_RECORD:transaction_type::INTEGER AS transaction_type,
        RAW_RECORD:nonce::NUMBER(38, 0) AS nonce

    FROM source

)

SELECT *
FROM renamed
