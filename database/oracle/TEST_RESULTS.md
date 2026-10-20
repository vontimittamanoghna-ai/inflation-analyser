# Verified local execution

Date: October 20, 2026 (Asia/Calcutta).

## Environment and preservation

- SQL*Plus/Oracle Database XE 21c; instance OPEN; XEPDB1 READ WRITE.
- Local listener registered xepdb1 on port 1521.
- Initial PDB inventory showed only PDBADMIN as a non-Oracle-maintained user and
  no objects named CATEGORY, PRODUCT, PRICE_HISTORY, INFLATION_DATA or REPORT.
- Created two isolated application schemas: IIA_DEMO_20261020 for the first run,
  and IIA_EVAL_20261020 to verify the corrected runner on a fresh schema.
- Each received only CREATE SESSION/TABLE/VIEW/PROCEDURE/TRIGGER/SEQUENCE and
  a 20 MB USERS quota. Nothing was dropped, truncated or reset. Existing team
  objects and the frontend source were untouched. No Git commit was created.
- Passwords were generated privately for testing and are not in repository files.
  Before an interactive presentation, an authorized local DBA should select a
  private password with SQL*Plus PASSWORD as shown below.

## Historical full-run results

`run_all.sql` executed from start to finish in IIA_EVAL_20261020 and returned exit
code 0. The raw SQL*Plus spool is [test-results.txt](test-results.txt).

| Check | Actual result |
|---|---|
| Tables | 5, all VALID |
| Views | 3, all VALID |
| Function / procedures / trigger | 1 / 3 / 1, all VALID |
| SQL/PLSQL compilation errors | 0 |
| Integrity constraints | 47 including Oracle-generated NOT NULL/identity checks; all ENABLED and VALIDATED |
| Demo rows | CATEGORY 4; PRODUCT 6; PRICE_HISTORY 108; INFLATION_DATA 4; REPORT 1 |
| Automated assertions | 27 PASS; 0 FAIL |
| Latest product/location series | 12 |
| Referential orphan check | 0 orphan observations |
| Repeat-setup guard | Existing schema rejected with expected ORA-20002 |
| Administrator guard | SYS rejected with expected ORA-20001 |
| Frontend | Source unchanged; no frontend installation/build attempted |

The two expected guard errors are captured separately in
[preflight-guard.txt](preflight-guard.txt); they are successful protection tests,
not unresolved installation failures. No Oracle/PLSQL/SP2 errors appeared in the
successful fresh-run spool.

During development, the initial schema provisioning attempt used an overlong
generated password rejected by Oracle; no user was created by that failed
statement. A subsequent seed block also exposed a PL/SQL declaration-order error.
Both were corrected; no objects were deleted to recover. The final fresh-run
spool reflects the corrected scripts. Identity gaps in the first development
schema are expected and have no effect on foreign keys or reports.

## Selected real SQL output (synthetic data)

Latest observations on September 1, 2026:

```text
PRODUCT_NAME   LOCATION     PRICE    UNIT
Rice           Bengaluru     54.00   1 kg
Rice           Chennai       56.70   1 kg
Tomato         Bengaluru     32.00   1 kg
```

Exact June 1 to September 1 change in Bengaluru:

```text
Cooking Oil      5.1852
Electricity      6.2500
Milk             6.8966
Petrol           2.4510
Rice            10.2041
Tomato         -23.8095
```

Category change from January 1 to September 1 (equal weight per exact-endpoint
product/location series; not official CPI):

```text
CATEGORY      RATE_PCT    COMPARABLE_SERIES
Food            5.5238                  6
Fuel            8.8566                  2
Household      18.3333                  2
Utilities      21.4626                  2
```

The rounded Chennai observations cause small differences from Bengaluru-only
rates; category values are calculated from stored prices, not copied labels.

## Historical access instructions (not authorization to reset a password)

Open SQL*Plus /nolog using the installed path in README.md. An authorized local
DBA can set a private application password without placing it in SQL text:

```sql
CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER=XEPDB1;
PASSWORD IIA_EVAL_20261020
```

Enter the chosen password only at the hidden prompts. Then reconnect:

```sql
CONNECT IIA_EVAL_20261020@//localhost:1521/XEPDB1
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
@"D:\Projects\inflation-analyser\database\oracle\05_reports.sql"
@"D:\Projects\inflation-analyser\database\oracle\06_tests.sql"
@"D:\Projects\inflation-analyser\database\oracle\07_verify.sql"
```

Do not run run_all.sql again in this installed schema. For a new machine/schema,
follow the prerequisites and full runner instructions instead.

## Remaining limits

- The React interface still uses its original sample array. No API/backend was
  needed to demonstrate the Oracle component; integration design is documented.
- Data is synthetic, with no verified external price feed or official CPI weights.
- Category summaries must be explicitly refreshed after underlying data changes;
  stored REPORT rows remain historical snapshots.
- The optional interactive provisioning script was reviewed, but its hidden
  PASSWORD prompt was not automated. Equivalent application-user privileges and
  quota were actually used by the tested schemas.

## Finalization recheck

Fresh read-only queries on AARON-HP, instance xe, Oracle 21c, XEPDB1 confirmed
IIA_EVAL_20261020 is OPEN; IIA_PROJECT does not exist. All 13 project objects are
valid, counts remain 4/6/108/4/1, invalid/unvalidated constraints=0 and compilation
errors=0. Exact-endpoint function outputs match the historical examples above.
Actual output: [current-readonly-check.txt](current-readonly-check.txt).

No application credential was available to the automation session. No password
was requested, stored or reset. Scripts 05/06/07 were NOT rerun as the application
user during finalization; the 27 PASS results above are historical evidence.
Follow the existing-installation commands in README.md to capture a fresh run.
The revised 07_verify.sql adds an explicit check for all 13 named objects; that
new check has been source-reviewed but has not been executed as the application
user. No DDL, setup, account provisioning or test DML ran during finalization.
No SQL arithmetic defect was found. Synthetic category measures remain unweighted
means of comparable product/location series, not official CPI.
