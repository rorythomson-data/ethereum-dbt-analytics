-- ============================================================
-- TO_ACTIVITY_DATE.SQL
-- Ethereum Analytics Pipeline | Snowflake + dbt
-- ============================================================
--
-- PURPOSE
-- Generate a consistent SQL expression for deriving an
-- activity date from a timestamp column.
--
-- EXECUTION
-- Rendered by dbt Core during compilation.
-- The generated SQL executes in Snowflake.
-- ============================================================

{% macro to_activity_date(timestamp_expression) -%}
CAST({{ timestamp_expression }} AS DATE)
{%- endmacro %}