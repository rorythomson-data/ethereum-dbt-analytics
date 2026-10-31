
-- ============================================================
-- ASSERT_TRANSACTION_TRANSFER_METRICS.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Ensure aggregated token-transfer metrics are logically
-- consistent for every transaction.
--
-- A dbt singular data test passes when this query returns
-- zero rows.
-- ============================================================

SELECT
    transaction_hash,
    transfer_count,
    distinct_token_count,
    has_token_transfer

FROM {{ ref('int_transactions_with_transfers') }}

WHERE
    transfer_count < 0

    OR distinct_token_count < 0

    OR distinct_token_count > transfer_count

    OR (
        transfer_count = 0
        AND has_token_transfer = TRUE
    )

    OR (
        transfer_count > 0
        AND has_token_transfer = FALSE
    )
