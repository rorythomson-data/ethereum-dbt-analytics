
-- ============================================================
-- INT_TRANSACTIONS_WITH_TRANSFERS.SQL
-- ============================================================
--
-- PURPOSE
-- Enrich Ethereum transactions with aggregated token-transfer
-- metrics while preserving one row per transaction.
--
-- GRAIN
-- One row per transaction_hash.
--
-- MATERIALIZATION
-- View, configured in dbt_project.yml.
-- ============================================================

WITH transactions AS (

    SELECT *
    FROM {{ ref('stg_transactions') }}

),

transfer_summary AS (

    SELECT
        transaction_hash,
        COUNT(*) AS transfer_count,
        COUNT(DISTINCT token_address) AS distinct_token_count

    FROM {{ ref('stg_token_transfers') }}

    GROUP BY transaction_hash

),

enriched AS (

    SELECT
        t.*,

        COALESCE(ts.transfer_count, 0) AS transfer_count,
        COALESCE(ts.distinct_token_count, 0) AS distinct_token_count,

        CASE
            WHEN ts.transfer_count IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS has_token_transfer

    FROM transactions t

    LEFT JOIN transfer_summary ts
        ON t.transaction_hash = ts.transaction_hash

)

SELECT *
FROM enriched
