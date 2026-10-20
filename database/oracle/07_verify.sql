WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET SERVEROUTPUT ON
SET LINESIZE 180 PAGESIZE 100
COLUMN object_name FORMAT A30
COLUMN object_type FORMAT A15
COLUMN table_name FORMAT A18
COLUMN constraint_name FORMAT A28
COLUMN index_name FORMAT A30
COLUMN status FORMAT A9
COLUMN validated FORMAT A13
COLUMN text FORMAT A80
PROMPT === Object inventory, constraints, indexes, row counts and compilation ===
SELECT object_type,object_name,status FROM user_objects
WHERE object_type IN ('TABLE','VIEW','FUNCTION','PROCEDURE','TRIGGER') ORDER BY object_type,object_name;
SELECT table_name,constraint_name,constraint_type,status,validated FROM user_constraints ORDER BY table_name,constraint_type;
SELECT table_name,index_name,uniqueness FROM user_indexes ORDER BY table_name,index_name;
SELECT 'CATEGORY' entity,COUNT(*) row_count FROM category UNION ALL
SELECT 'PRODUCT',COUNT(*) FROM product UNION ALL
SELECT 'PRICE_HISTORY',COUNT(*) FROM price_history UNION ALL
SELECT 'INFLATION_DATA',COUNT(*) FROM inflation_data UNION ALL
SELECT 'REPORT',COUNT(*) FROM report;
SELECT name,type,line,position,text FROM user_errors ORDER BY name,sequence;
DECLARE
  n NUMBER;
  PROCEDURE expected_rows(t VARCHAR2, expected NUMBER) IS actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||t INTO actual;
    IF actual<>expected THEN RAISE_APPLICATION_ERROR(-20091,t||': expected '||expected||', got '||actual); END IF;
  END;
BEGIN
  SELECT COUNT(*) INTO n FROM user_objects WHERE status='INVALID';
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20092,'Invalid schema objects'); END IF;
  SELECT COUNT(*) INTO n FROM user_errors WHERE attribute='ERROR';
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20093,'Compilation errors'); END IF;
  SELECT COUNT(*) INTO n FROM user_constraints WHERE status<>'ENABLED' OR validated<>'VALIDATED';
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20094,'Disabled or unvalidated constraints'); END IF;
  expected_rows('CATEGORY',4); expected_rows('PRODUCT',6); expected_rows('PRICE_HISTORY',108);
  expected_rows('INFLATION_DATA',4); expected_rows('REPORT',1);
  SELECT COUNT(*) INTO n FROM price_history h LEFT JOIN product p ON p.product_id=h.product_id WHERE p.product_id IS NULL;
  IF n<>0 THEN RAISE_APPLICATION_ERROR(-20095,'Orphan observations'); END IF;
  DBMS_OUTPUT.PUT_LINE('VERIFIED: 5 tables; demo counts 4/6/108/4/1; constraints enabled; no compilation errors.');
END;
/
