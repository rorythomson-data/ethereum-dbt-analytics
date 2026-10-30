# Ethereum Analytics Pipeline — dbt + Snowflake

**Status:** Snowflake infrastructure, source ingestion, and initial RAW data validation completed. dbt transformations, automated tests, and analytics models are planned.

## Project Overview

An analytics engineering portfolio project using Ethereum blockchain data to demonstrate data ingestion, transformation, modelling, testing, and documentation with **Snowflake and dbt Core**.

The project focuses on practical analytics engineering concepts, including:

- Layered data modelling and dependency management
- Data quality testing and source-to-mart reconciliation
- Reusable SQL transformations and Jinja macros
- Incremental processing and idempotent execution
- Model documentation and lineage

The objective is to demonstrate a reproducible analytics engineering workflow rather than build a production-scale blockchain analytics platform.

## Technology Stack

| Technology | Purpose |
|---|---|
| Snowflake | Data storage, ingestion and SQL execution |
| dbt Core + dbt-snowflake | Data transformation, testing and documentation (planned) |
| AWS Public Blockchain Data | Public Ethereum datasets stored as Parquet files in S3 |
| Python | Local dbt environment |
| Git / GitHub | Version control and project documentation |

## Architecture

The project follows an **ELT (Extract, Load, Transform)** approach.

```text
AWS S3 — Public Ethereum Data
             |
             v
Snowflake External Stages
             |
             v
Snowflake RAW Schema
  - TRANSACTIONS
  - TOKEN_TRANSFERS
  - CONTRACTS
             |
             v
dbt Staging Models (planned)
             |
             v
dbt Intermediate Models (planned)
             |
             v
dbt Analytics Marts (planned)
```

Snowflake handles ingestion, storage and query execution. dbt will manage the SQL transformations, model dependencies, automated tests and documentation.

### Snowflake Resources

| Resource | Name |
|---|---|
| Database | `ETHEREUM_PORTFOLIO` |
| RAW schema | `RAW` |
| Analytics schema | `ANALYTICS` |
| Warehouse | `DBT_WH` |
| Warehouse size | XSMALL |
| Auto-suspend | 60 seconds |
| Auto-resume | Enabled |

The development environment uses a small Snowflake warehouse to limit unnecessary compute consumption.

## Data Sources

Data is sourced from the [AWS Public Blockchain Data](https://registry.opendata.aws/aws-public-blockchain/) project.

Three Ethereum datasets are used:

| Dataset | Description |
|---|---|
| Transactions | Blockchain transaction records, including hashes, addresses, timestamps and execution metadata |
| Token transfers | Token-transfer events associated with Ethereum transactions |
| Contracts | Smart contract records, including contract addresses, bytecode and block metadata |

The current development sample uses the historical partition **2024-01-15**.

Data is accessed directly from public S3 locations through Snowflake external stages. The repository does not need to distribute the underlying blockchain files.

## Raw Data Ingestion

### External Stages

Three Snowflake external stages provide access to the public Parquet files:

- `ETH_TRANSACTIONS_STAGE`
- `ETH_TOKEN_TRANSFERS_STAGE`
- `ETH_CONTRACTS_STAGE`

The stages reference the corresponding Ethereum dataset paths in the public AWS S3 bucket.

### RAW Table Design

Each RAW table contains a single `RAW_RECORD` column of type `VARIANT`.

This design preserves the original semi-structured source records and separates ingestion from transformation. Field extraction, type casting and standardisation will be handled by downstream dbt models.

### Development Sampling Strategy

The project uses bounded, reproducible samples rather than ingesting the complete Ethereum datasets.

**Transactions and token transfers**

The ingestion process:

1. Selects 1,000 distinct transaction hashes from token-transfer events, ordered by hash.
2. Loads the corresponding transaction records from the same historical partition.
3. Loads all token-transfer events associated with those transactions.

This relationship-aware sampling strategy ensures that the development dataset contains transactions with corresponding token-transfer events.

An earlier approach selected transactions independently by hash. Although deterministic, it produced no matching transfers in the sample. The ingestion logic was revised to preserve useful relationships for downstream modelling.

**Smart contracts**

A separate sample of 1,000 contract records is selected by contract address.

Contracts are sampled independently. Contract records created on the selected date are not guaranteed to correspond to token contracts referenced by the sampled transfers.

**Repeatability**

The ingestion script truncates the RAW tables before reloading them, preventing records from accumulating across development runs.

Sample selection is reproducible provided the underlying source files remain unchanged.

## Initial Data Validation

After ingestion, SQL validation queries check record counts, identifier completeness, uniqueness and referential integrity.

### Validation Results

| Validation | Result |
|---|---|
| Transactions loaded | 1,000 |
| Missing transaction hashes | 0 |
| Duplicate transaction hashes | 0 |
| Token-transfer events loaded | 1,779 |
| Missing transfer transaction hashes | 0 |
| Missing transfer log indexes | 0 |
| Non-unique or missing transfer event keys | 0 |
| Token transfers without a matching transaction | 0 |
| Distinct transactions represented in transfers | 1,000 |
| Contract records loaded | 1,000 |
| Missing contract addresses | 0 |
| Duplicate contract addresses | 1 |

All sampled transactions have at least one associated token-transfer event.

### Known Data Quality Finding: Repeated Contract Address

One contract address appears twice in the sampled contracts dataset:

`0x00ddede78cdb1c76d33c8029799aa60d5e566b38`

The two records are not identical. They have different block numbers, block hashes, timestamps and last-modified values, while both contain empty bytecode (`0x`).

The cause of this repetition has not been established.

Both records are retained in the RAW layer to preserve source fidelity. Downstream modelling will determine whether address-level uniqueness is required and, if so, how records should be selected.

This finding will inform the design of dbt data quality tests and contract models.

## Repository Structure

```text
ethereum-dbt-analytics/
├── snowflake_setup/
│   ├── 01_create_resources.sql
│   ├── 02_create_stages.sql
│   ├── 03_inspect_data.sql
│   ├── 04_load_raw_data.sql
│   └── 05_validate_raw_data.sql
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── macros/
├── tests/
│   └── manual/
│       └── test_s3_ingestion.sql
├── seeds/
├── analyses/
├── docs/
├── requirements.txt
├── profiles.example.yml
└── README.md
```

The `snowflake_setup/` directory contains manually executed Snowflake scripts.

The `tests/manual/` directory preserves the isolated S3 ingestion test, which uses a temporary table without modifying permanent RAW data.

The dbt model directories and supporting assets will be populated during subsequent development.

## Getting Started

### 1. Snowflake Environment

Create a Snowflake account with access to the required features and sufficient compute credits.

Execute the following scripts in order using a Snowflake SQL worksheet:

```text
01_create_resources.sql
02_create_stages.sql
03_inspect_data.sql
04_load_raw_data.sql
05_validate_raw_data.sql
```

The scripts create the required infrastructure, inspect the source data, load development samples and report validation results.

**Note:** Running `04_load_raw_data.sql` replaces existing contents of the three RAW tables.

### 2. Local dbt Environment

Install Python and the dependencies specified in `requirements.txt`:

```bash
python -m pip install -r requirements.txt
```

Configure a local `~/.dbt/profiles.yml` using `profiles.example.yml` as a reference. The dbt profile must point to your own Snowflake account and use the project’s configured profile name and target.

Never commit credentials or the real `profiles.yml`.

Verify the connection from the project directory:

```bash
dbt debug
```

The dbt setup and execution instructions will be expanded once the transformation models are implemented and tested.

## Planned dbt Implementation

The next phase will implement:

- **Staging models:** Extract, cast and standardise fields from RAW `VARIANT` records.
- **Intermediate models:** Define reusable relationships and transformations.
- **Analytics marts:** Produce analysis-ready datasets.
- **Data tests:** Validate uniqueness, non-null constraints, relationships and business rules.
- **Unit tests:** Verify selected transformation logic using controlled inputs.
- **Macros:** Encapsulate reusable SQL or Jinja logic.
- **Incremental models:** Demonstrate incremental processing and rerun behaviour.
- **Documentation:** Describe models, columns, dependencies and lineage.

The final model structure and materialisation strategies will be determined during implementation.

## Data Provenance and Limitations

Source: [AWS Public Blockchain Data](https://registry.opendata.aws/aws-public-blockchain/).

The current dataset is a bounded sample from a single historical date and is not representative of all Ethereum activity.

The relationship-aware sampling method intentionally selects transactions associated with token transfers. It should not be used to estimate the proportion of all Ethereum transactions that generate token-transfer events.

Contracts are sampled independently and may not provide complete coverage of token addresses in the transfer dataset.

Blockchain addresses should not automatically be interpreted as distinct people or customers, and token transfers should not automatically be classified as commercial payments.

Source usage terms and any redistribution permissions should be reviewed before distributing source-derived data.

## Reproducibility and Security

The repository contains the SQL needed to recreate the Snowflake environment and development samples.

Reproduction requires an independent Snowflake account and access to the public AWS datasets; it does not depend on the author's trial account remaining active.

Do not commit passwords, access tokens, private keys, `.env` files or a real `profiles.yml`.

## Project Origin

This is an independent portfolio implementation building on dbt concepts previously studied in an Ethereum-focused course.

The ingestion workflow, models, tests and documentation are being developed and validated for this repository. Any reused course material should be attributed appropriately.
