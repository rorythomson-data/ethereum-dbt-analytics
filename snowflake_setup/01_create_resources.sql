
-- ============================================================
-- 01_CREATE_RESOURCES.SQL
-- ============================================================
--
-- PURPOSE
-- Provision the Snowflake database, schemas, and compute
-- resources required for Ethereum data ingestion and
-- dbt transformations.
--
-- EXECUTION
-- Snowflake SQL worksheet, using a role with privileges
-- to create databases, schemas, and warehouses.
--
-- Run before configuring external stages or loading data.
-- CREATE statements use IF NOT EXISTS to preserve
-- existing resources on subsequent executions.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE PROJECT DATABASE
-- ============================================================

-- Isolate project data and transformations from other workloads.

CREATE DATABASE IF NOT EXISTS ETHEREUM_PORTFOLIO;


-- ============================================================
-- STEP 2: CREATE SCHEMAS
-- ============================================================

-- Separate source ingestion from analytical transformations.
-- RAW retains source records; ANALYTICS provides the base
-- schema for dbt models. Final schema names depend on dbt
-- schema-generation configuration.

CREATE SCHEMA IF NOT EXISTS ETHEREUM_PORTFOLIO.RAW;

CREATE SCHEMA IF NOT EXISTS ETHEREUM_PORTFOLIO.ANALYTICS;


-- ============================================================
-- STEP 3: CREATE COMPUTE WAREHOUSE
-- ============================================================

-- Use a small, independently managed compute resource for
-- ingestion queries and dbt transformations.
--
-- XSMALL limits compute consumption during development.
-- Auto-suspend reduces idle costs, while auto-resume enables
-- on-demand execution without manual warehouse management.

CREATE WAREHOUSE IF NOT EXISTS DBT_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;


-- ============================================================
-- STEP 4: VERIFY RESOURCE CREATION
-- ============================================================

-- Inspect database, schema, and warehouse metadata.

SHOW DATABASES LIKE 'ETHEREUM_PORTFOLIO';

SHOW SCHEMAS IN DATABASE ETHEREUM_PORTFOLIO;

SHOW WAREHOUSES LIKE 'DBT_WH';
