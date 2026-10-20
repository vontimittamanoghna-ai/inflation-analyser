# inflation analyser
A DBMS project for analysing product price trends, inflation impact, and future costs.

## Oracle SQL/PLSQL component

The five-entity Oracle implementation, SQL*Plus execution guide, data dictionary,
synthetic data assumptions and evaluation checklist are in
[database/oracle/README.md](database/oracle/README.md).

Run `database/oracle/run_all.sql` once in an empty dedicated Oracle application
schema. For an installed demo, run only the reports, tests and verification scripts
as documented there. No teardown or database reset is required.

The React frontend is preserved and still uses sample data; it is not connected
to Oracle. Run it from `frontend` with `npm ci` then `npm run dev` after ensuring
Node.js/npm are available. No Oracle credentials belong in frontend code.
