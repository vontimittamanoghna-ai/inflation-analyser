SET ECHO OFF VERIFY OFF FEEDBACK ON SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 100
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
PROMPT === Preflight: application schema only; existing objects are preserved ===
SELECT USER AS schema_name, SYS_CONTEXT('USERENV','CON_NAME') AS container_name FROM dual;
DECLARE
  n NUMBER;
BEGIN
  IF USER IN ('SYS','SYSTEM','PDBADMIN') THEN
    RAISE_APPLICATION_ERROR(-20001,'Connect as a dedicated application user, not an administrator.');
  END IF;
  SELECT COUNT(*) INTO n FROM user_objects WHERE object_name IN
    ('CATEGORY','PRODUCT','PRICE_HISTORY','INFLATION_DATA','REPORT',
     'V_LATEST_PRICES','V_CATEGORY_SUMMARY','V_PRICE_CHANGES',
     'FN_PRICE_CHANGE','PR_RECORD_PRICE','PR_REFRESH_INFLATION','PR_GENERATE_REPORT',
     'TRG_PRODUCT_UNIT_LOCK');
  IF n > 0 THEN
    RAISE_APPLICATION_ERROR(-20002,'Project object names already exist. Inspect them; do not rerun setup. Use 07_verify.sql.');
  END IF;
  FOR p IN (SELECT 'CREATE TABLE' privilege FROM dual UNION ALL
            SELECT 'CREATE VIEW' FROM dual UNION ALL
            SELECT 'CREATE PROCEDURE' FROM dual UNION ALL
            SELECT 'CREATE TRIGGER' FROM dual UNION ALL
            SELECT 'CREATE SEQUENCE' FROM dual) LOOP
    SELECT COUNT(*) INTO n FROM session_privs WHERE privilege=p.privilege;
    IF n=0 THEN RAISE_APPLICATION_ERROR(-20003,'Missing privilege: '||p.privilege); END IF;
  END LOOP;
END;
/
SELECT tablespace_name, bytes, max_bytes FROM user_ts_quotas;
PROMPT Preflight passed. Ensure the application user has a tablespace quota.
