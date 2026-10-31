
-- ============================================================
-- ASSERT_TRANSACTION_TRANSFER_RECONCILIATION.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Reconcile transaction-level transfer metrics against
-- the underlying staging token-transfer records.
--
-- A dbt singular data test passes when this query
-- returns zero rows.
-- ============================================================

WITH expected_metrics AS (

    SELECT
        transaction_hash,
        COUNT(*) AS expected_transfer_count,
        COUNT(DISTINCT token_address) AS expected_distinct_token_count

    FROM {{ ref('stg_token_transfers') }}

    GROUP BY transaction_hash

),

actual_metrics AS (

    SELECT
        transaction_hash,
        transfer_count,
        distinct_token_count,
        has_token_transfer

    FROM {{ ref('int_transactions_with_transfers') }}

),

reconciled AS (

    SELECT
        a.transaction_hash,

        a.transfer_count,
        COALESCE(e.expected_transfer_count, 0)
            AS expected_transfer_count,

        a.distinct_token_count,
        COALESCE(e.expected_distinct_token_count, 0)
            AS expected_distinct_token_count,

        a.has_token_transfer,

        CASE
            WHEN COALESCE(e.expected_transfer_count, 0) > 0
                THEN TRUE
            ELSE FALSE
        END AS expected_has_token_transfer

    FROM actual_metrics a

    LEFT JOIN expected_metrics e
        ON a.transaction_hash = e.transaction_hash

)

SELECT *
FROM reconciled

WHERE
    transfer_count <> expected_transfer_count

    OR distinct_token_count <> expected_distinct_token_count

    OR has_token_transfer <> expected_has_token_transfer
