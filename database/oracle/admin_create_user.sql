-- OPTIONAL administrator-only provisioning. Not called by run_all.sql.
-- Connect to the intended PDB before running. Oracle 18c+ schema-only account syntax.
SET ECHO OFF VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SELECT USER, SYS_CONTEXT('USERENV','CON_NAME') AS container_name FROM dual;
DECLARE
BEGIN
  IF SYS_CONTEXT('USERENV','CON_NAME')='CDB$ROOT' THEN
    RAISE_APPLICATION_ERROR(-20004,'Connect to the project PDB before creating a local user.');
  END IF;
END;
/
-- Fails safely if this user already exists. Never drop/recreate an existing user.
CREATE USER iia_project NO AUTHENTICATION DEFAULT TABLESPACE users QUOTA 20M ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE,
      CREATE TRIGGER, CREATE SEQUENCE TO iia_project;
PROMPT Choose a private password at the hidden SQL*Plus prompts. Never spool passwords.
PASSWORD iia_project
PROMPT Reconnect as IIA_PROJECT before running run_all.sql.
