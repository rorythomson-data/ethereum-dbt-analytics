# Ethereum Analytics Pipeline — dbt + Snowflake

**Status:** Initial project scaffold. Data access, transformations, and tests have **not yet been implemented or validated**.

## Purpose
A compact analytics engineering portfolio project demonstrating dbt proficiency on Ethereum transaction, token-transfer, and contract data. The emphasis is on **model architecture, lineage, testing, documentation, macros, and incremental processing**, rather than production blockchain analytics.

## Planned stack
- Snowflake: raw data storage and SQL execution
- dbt Core + dbt-snowflake: transformations, testing, and documentation
- Git/GitHub: version control
- AWS Public Blockchain Data: **candidate** source; availability and compatibility still need verification

## Planned architecture
`AWS S3 (candidate) → Snowflake RAW → dbt staging → dbt intermediate → dbt marts`

## Repository structure
- `snowflake_setup/`: manually executed Snowflake environment and ingestion scripts
- `models/staging/`: cleaned source-aligned models
- `models/intermediate/`: reusable transformations
- `models/marts/`: analytics-ready models
- `macros/`, `tests/`, `seeds/`, `analyses/`: dbt project assets
- `docs/`: design decisions and execution evidence (later)

## Getting started (initial setup)
1. Create an eligible Snowflake account. Monitor trial credits and warehouse usage.
2. In Snowflake, open a SQL worksheet and run `snowflake_setup/01_create_resources.sql`.
3. Install Python and dbt Snowflake adapter locally: `python -m pip install -r requirements.txt`.
4. Configure your **local** `~/.dbt/profiles.yml` with a target named `ethereum_portfolio` (see `profiles.example.yml` for a non-secret template). Do **not** commit your actual profile or credentials.
5. Run `dbt debug` from the project directory to check the connection.

**Not yet ready:** `dbt build` cannot produce analytics models until source ingestion and models are implemented. The S3 source, raw table schemas, and loading scripts must be verified before use.

## Planned dbt demonstrations
- `source()` and `ref()` with staging/intermediate/mart layers
- View, table, and incremental materializations
- Generic and custom data tests, plus a unit test
- Reusable Jinja macros and YAML documentation
- Validation of incremental reruns and source-to-mart reconciliation

## Reproducibility
The repository will contain the SQL used to create Snowflake resources and load data. Running the project requires **your own Snowflake account**; it does not depend on the author's trial account remaining active. Data loading and reproducibility instructions will be completed after verifying the public source.

## Data provenance and limitations
Source candidate: [AWS Public Blockchain Data](https://registry.opendata.aws/aws-public-blockchain/). Access, schema, usage terms, and any redistribution permissions must be checked before extraction or inclusion of sample data. On-chain token transfers should **not** automatically be interpreted as commercial payments or distinct customers.

## Security
Never commit passwords, tokens, private keys, `.env`, or your real `profiles.yml`. Snowflake account details should be configured locally.

## Project origin
This is a new portfolio implementation building on dbt concepts previously studied in an Ethereum-focused course. The models, tests, and documentation will be designed and validated for this repository; any reused course material should be attributed appropriately.
