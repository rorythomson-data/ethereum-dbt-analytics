# Design decisions

- **2026-10-29:** Use Snowflake as the execution platform for a dbt-focused portfolio project.
- AWS Ethereum public S3 data is a candidate source, pending validation.
- Favor a compact, testable transformation pipeline over production-scale blockchain analysis.

## Open questions
- Exact S3 object layout and access
- Source schemas and bounded extraction strategy
- Incremental grain and unique key
- Final mart definitions and acceptance tests
