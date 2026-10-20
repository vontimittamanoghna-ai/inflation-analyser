# inflation analyser
A DBMS project for analysing product price trends, inflation impact, and future costs.

## Oracle SQL/PLSQL component

The five-entity Oracle implementation, SQL*Plus execution guide, data dictionary,
synthetic data assumptions and evaluation checklist are in
[database/oracle/README.md](database/oracle/README.md).

Run `database/oracle/run_all.sql` once in an empty dedicated Oracle application
schema. For an installed demo, run only the reports, tests and verification scripts
as documented there. No teardown or database reset is required.

The React dashboard uses the FastAPI integration described below. No Oracle
credentials belong in frontend code.

## FastAPI / React integration

See [backend/README.md](backend/README.md) for private environment configuration,
API contracts, startup and verification. The dashboard now loads Oracle-backed
API responses and explicitly shows failures when the database is unavailable.
The SQL*Plus component remains independently runnable; do not rerun its setup on
the populated evaluation schema. Live browser-to-Oracle execution still requires
valid application credentials; see backend test evidence for what was verified.

The dashboard now includes dated Trends graphs, Oracle-backed Insights, an
assumed-rate cost Calculator, and browser-local Profile preferences. See
[frontend/FEATURES.md](frontend/FEATURES.md) and
[frontend/TEST_RESULTS.md](frontend/TEST_RESULTS.md) for scope and verification.
