# Ethereum Analytics Pipeline — dbt + Snowflake

**Status:** Snowflake infrastructure, public-source ingestion, RAW validation, and the dbt staging layer are complete. Intermediate transformations and analytics marts are planned.

## Project Overview

An analytics engineering portfolio project using Ethereum blockchain data to demonstrate ingestion, SQL transformation, data quality testing, and documentation with **Snowflake and dbt Core**.

The project emphasizes layered data modeling, reproducible development samples, source-to-model validation, and a documented approach to source-data anomalies. Planned extensions include reusable intermediate transformations, analytics marts, macros, incremental processing, and lineage documentation.

The objective is to demonstrate a reproducible analytics engineering workflow rather than build a production-scale blockchain analytics platform.

## Technology Stack

| Technology | Purpose |
|---|---|
| Snowflake | Ingestion, storage, views, and SQL execution |
| dbt Core 1.12.6 + dbt-snowflake 1.12.4 | SQL transformations, tests, and project configuration |
| dbt_utils 1.4.1 | Composite-key uniqueness testing |
| AWS Public Blockchain Data | Public Ethereum Parquet datasets in Amazon S3 |
| Python 3.12 | Local virtual environment for dbt |
| Git / GitHub | Version control and documentation |

## Architecture

The project uses an **ELT (Extract, Load, Transform)** workflow:

```text
AWS S3 — Public Ethereum Data
             |
             v
Snowflake External Stages
             |
             v
Snowflake ETHEREUM_PORTFOLIO.RAW
  - TRANSACTIONS
  - TOKEN_TRANSFERS
  - CONTRACTS
             |
             v
 dbt Staging Views (complete)
  - stg_transactions
  - stg_token_transfers
  - stg_contracts
             |
             v
 dbt Intermediate Models (planned)
             |
             v
 dbt Analytics Marts (planned)
```

Snowflake stores the data and executes SQL. **dbt Core runs locally**, compiles model and test SQL, and submits it to Snowflake. The three staging models are configured as views; intermediate models are configured as views and marts as tables when those layers are implemented.

### Snowflake Resources

| Resource | Name / configuration |
|---|---|
| Database | `ETHEREUM_PORTFOLIO` |
| RAW schema | `RAW` |
| Analytics schema | `ANALYTICS` |
| Warehouse | `DBT_WH` |
| Warehouse size | XSMALL |
| Auto-suspend | 60 seconds |
| Auto-resume | Enabled |

The small development warehouse helps limit unnecessary compute usage.

## Data Sources

Source: [AWS Public Blockchain Data](https://registry.opendata.aws/aws-public-blockchain/).

| Dataset | Description |
|---|---|
| Transactions | Transaction hashes, addresses, timestamps, value, gas, and execution metadata |
| Token transfers | Token-transfer events associated with Ethereum transactions |
| Contracts | Contract addresses, bytecode, and block metadata |

The current development sample comes from the historical partition **2024-01-15**. Snowflake external stages read public S3 Parquet files; the repository does not distribute those source files.

## RAW Data Ingestion

### External Stages

- `ETH_TRANSACTIONS_STAGE`
- `ETH_TOKEN_TRANSFERS_STAGE`
- `ETH_CONTRACTS_STAGE`

Each RAW table has one `RAW_RECORD VARIANT` column. This preserves source fields and separates ingestion from type casting and normalization in dbt.

### Development Sampling Strategy

**Transactions and token transfers:**

1. Select 1,000 distinct transaction hashes from token-transfer events, ordered by hash.
2. Load the corresponding transactions from the same historical partition.
3. Load every token-transfer event associated with those transactions.

This relationship-aware approach provides transaction-to-transfer matches for downstream modeling. An earlier independent transaction sample produced no matching token transfers, so the ingestion strategy was revised.

**Contracts:** Select 1,000 records independently, ordered by contract address. These records are **not guaranteed to correspond** to token contracts in the sampled transfers.

**Repeatability:** The ingestion script truncates the three RAW tables before reloading them, avoiding accumulation across runs. Sample selection is reproducible provided the underlying source files remain unchanged.

## RAW Data Validation

| Validation | Result |
|---|---:|
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
| Repeated contract addresses | 1 |

Every sampled transaction has at least one associated token-transfer event.

### Known Data Quality Finding: Repeated Contract Address

Address `0x00ddede78cdb1c76d33c8029799aa60d5e566b38` occurs in two records with different block numbers, block hashes, block timestamps, and last-modified values. Both have `0x` bytecode; the investigation did not establish the cause of repetition.

Both records are **retained in RAW and staging**. The staging model therefore does not guarantee uniqueness of `contract_address`. Any downstream one-row-per-address model must explicitly define and document a selection rule rather than silently discarding a record.

## dbt Staging Layer — Complete

The staging layer extracts typed columns from RAW `VARIANT` records using `source()` references declared in `models/staging/_sources.yml`.

| Model | Materialization | Grain / key | Validated rows |
|---|---|---|---:|
| `stg_transactions` | View | One row per `transaction_hash` | 1,000 |
| `stg_token_transfers` | View | One row per (`transaction_hash`, `log_index`) | 1,779 |
| `stg_contracts` | View | One row per source contract record; addresses may repeat | 1,000 |

`stg_transactions` standardizes transaction hashes, block metadata, addresses, value in wei, gas fields, and receipt metadata. `stg_token_transfers` retains token amounts in their raw smallest-unit representation because token decimal precision has not been established. `stg_contracts` standardizes contract metadata and bytecode without deduplicating addresses.

### Automated Tests

| Model | Automated checks | Passing tests |
|---|---|---:|
| `stg_transactions` | Non-null transaction hash; unique transaction hash; non-null block timestamp | 3 |
| `stg_token_transfers` | Non-null transaction hash, log index, and block timestamp; `dbt_utils` composite-key uniqueness | 4 |
| `stg_contracts` | Non-null contract address, block number, and block timestamp | 3 |
| **Total** | | **10** |

The contracts model intentionally has **no unique-address test**, reflecting the documented source anomaly. Manual Snowflake SQL checks additionally verified record counts and the single repeated address.

**Integrated build:** `dbt build --select staging` completed successfully with **3 views created, 10 tests passed, 0 errors (13/13 operations)**.

## Repository Structure

```text
ethereum-dbt-analytics/
├── snowflake_setup/
│   ├── 01_create_resources.sql
│   ├── 02_create_stages.sql
│   ├── 03_inspect_data.sql
│   ├── 04_load_raw_data.sql
│   ├── 05_validate_raw_data.sql
│   ├── 06_inspect_staging_source.sql
│   ├── 07_validate_stg_transactions.sql
│   ├── 08_inspect_token_transfers.sql
│   ├── 09_validate_stg_token_transfers.sql
│   ├── 10_investigate_contract_duplicates.sql
│   └── 11_validate_stg_contracts.sql
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── stg_transactions.sql
│   │   ├── _stg_transactions.yml
│   │   ├── stg_token_transfers.sql
│   │   ├── _stg_token_transfers.yml
│   │   ├── stg_contracts.sql
│   │   └── _stg_contracts.yml
│   ├── intermediate/             # planned
│   └── marts/                    # planned
├── macros/
├── tests/
│   └── manual/
│       └── test_s3_ingestion.sql
├── seeds/
├── analyses/
├── docs/
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
├── requirements.txt
├── profiles.example.yml
└── README.md
```

The numbered `snowflake_setup/` scripts preserve the manual Snowflake development and validation workflow. The dbt SQL and YAML files are the version-controlled source for transformation and automated testing. The `tests/manual/` script preserves an isolated temporary-table S3 ingestion test.

## Getting Started

### 1. Snowflake Environment

Create a Snowflake account with suitable access and compute credits. Execute `01_create_resources.sql` through `05_validate_raw_data.sql` in numerical order in Snowflake worksheets. Scripts `06`–`11` document subsequent manual source inspection, anomaly investigation, and staging validation; run them at the appropriate point after creating the referenced staging views.

**Caution:** `04_load_raw_data.sql` truncates and reloads the three RAW tables. It replaces their existing contents.

### 2. Local dbt Environment

From the repository root, create and activate a virtual environment (PowerShell example):

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
dbt deps
```

Copy `profiles.example.yml` to your local `~/.dbt/profiles.yml`, supply your own Snowflake connection settings, and keep the real profile **outside the repository**. The project uses the `ethereum_portfolio` profile and the `dev` target, configured for `ETHEREUM_PORTFOLIO.ANALYTICS`.

```powershell
dbt debug
dbt ls --resource-type source
dbt build --select staging
```

`dbt deps` installs the versioned `dbt_utils` dependency. The `package-lock.yml` file records resolved dependencies and should be committed; the generated `dbt_packages/` directory should not.

**Environment note:** During development, an optional `dbt-state` integration prompted browser authentication. The local session used `DBT_ENGINE_MANAGE_STATE=0` to disable it, which produced a reserved-environment-variable deprecation warning. A clean, reproducible long-term configuration for that optional component remains to be resolved; the staging build itself passed.

## Planned dbt Implementation

- **Intermediate models:** Reusable transaction-to-transfer relationships, transformations, and documented treatment of duplicate contract addresses where required.
- **Analytics marts:** Analysis-ready datasets and reconciliation checks.
- **Additional tests:** Relationship and business-rule checks, plus selected unit tests.
- **Macros:** Reusable SQL/Jinja logic where beneficial.
- **Incremental processing:** Demonstrate incremental models and rerun behavior.
- **Documentation and lineage:** Expand column descriptions and generated dbt documentation.

These features are **not yet implemented**. Model grain and materialization choices will be finalized during development.

## Data Provenance and Limitations

Source: [AWS Public Blockchain Data](https://registry.opendata.aws/aws-public-blockchain/).

The sample covers a single historical date and is not representative of all Ethereum activity. The sampling intentionally favors transactions with token transfers; it cannot estimate the share of all transactions that emit transfers. Contract sampling is independent and does not ensure coverage of token addresses in the transfer sample.

Blockchain addresses do not necessarily represent distinct people, and token transfers should not automatically be interpreted as commercial payments. Token `value` fields are not normalized to display units without token-specific decimal metadata. Review source terms and redistribution permissions before distributing source-derived data.

## Reproducibility and Security

The repository contains SQL and dbt definitions needed to recreate the demonstrated development workflow. Reproduction requires a separate Snowflake account and access to the public AWS datasets, not the author's trial account.

Never commit passwords, access tokens, private keys, `.env` files, a real `profiles.yml`, or other secrets. Review exported Snowflake worksheets before committing them.

## Project Origin

This is an independent portfolio implementation building on dbt concepts previously studied in an Ethereum-focused course. The ingestion workflow, models, tests, and documentation are being developed and validated for this repository. Any reused course material should be attributed appropriately.
