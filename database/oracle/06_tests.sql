SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
PROMPT === Transactional tests: all test DML rolled back, identity gaps are normal ===
DECLARE
  pid NUMBER; cid NUMBER; rid NUMBER; n NUMBER; r NUMBER; bad NUMBER := 0;
  PROCEDURE expect_failure(label VARCHAR2, stmt VARCHAR2, expected NUMBER) IS
  BEGIN
    SAVEPOINT negative_case;
    BEGIN
      EXECUTE IMMEDIATE stmt;
      ROLLBACK TO negative_case;
      DBMS_OUTPUT.PUT_LINE('FAIL '||label||': statement unexpectedly succeeded'); bad:=bad+1;
    EXCEPTION WHEN OTHERS THEN
      IF SQLCODE=expected THEN DBMS_OUTPUT.PUT_LINE('PASS '||label);
      ELSE DBMS_OUTPUT.PUT_LINE('FAIL '||label||': '||SQLERRM); bad:=bad+1; END IF;
      ROLLBACK TO negative_case;
    END;
  END;
  PROCEDURE assert_true(label VARCHAR2, ok BOOLEAN) IS
  BEGIN
    IF ok THEN DBMS_OUTPUT.PUT_LINE('PASS '||label);
    ELSE DBMS_OUTPUT.PUT_LINE('FAIL '||label); bad:=bad+1; END IF;
  END;
BEGIN
  SAVEPOINT all_tests;
  SELECT product_id,category_id INTO pid,cid FROM product WHERE product_name='Rice';
  expect_failure('NOT NULL',q'[INSERT INTO category(category_name) VALUES(NULL)]',-1400);
  expect_failure('blank name CHECK',q'[INSERT INTO category(category_name) VALUES('   ')]',-2290);
  expect_failure('UNIQUE category',q'[INSERT INTO category(category_name) VALUES('Food')]',-1);
  expect_failure('foreign key',q'[INSERT INTO product(category_id,product_name,unit) VALUES(-1,'Test','1 kg')]',-2291);
  expect_failure('positive price CHECK','INSERT INTO price_history(product_id,observed_date,price,source,location) VALUES('||pid||q'[,DATE '2027-01-01',0,'TEST','Bengaluru')]',-2290);
  expect_failure('unique daily observation','INSERT INTO price_history(product_id,observed_date,price,source,location) VALUES('||pid||q'[,DATE '2026-01-01',42,'TEST','Bengaluru')]',-1);
  expect_failure('calendar date CHECK','INSERT INTO price_history(product_id,observed_date,price,source,location) VALUES('||pid||q'[,DATE '2027-01-01'+0.5,42,'TEST','Bengaluru')]',-2290);
  expect_failure('active status CHECK','UPDATE product SET active_status=''X'' WHERE product_id='||pid,-2290);
  expect_failure('historical unit trigger','UPDATE product SET unit=''2 kg'' WHERE product_id='||pid,-20014);
  expect_failure('inflation period CHECK','INSERT INTO inflation_data(category_id,period_start,period_end,inflation_rate) VALUES('||cid||q'[,DATE '2027-02-01',DATE '2027-01-01',1)]',-2290);
  expect_failure('inflation rate CHECK','INSERT INTO inflation_data(category_id,period_start,period_end,inflation_rate) VALUES('||cid||q'[,DATE '2027-01-01',DATE '2027-02-01',-100)]',-2290);
  expect_failure('report type CHECK',q'[INSERT INTO report(report_type,period_from,period_to,summary) VALUES('INVALID',DATE '2027-01-01',DATE '2027-02-01','TEST')]',-2290);
  expect_failure('report range CHECK',q'[INSERT INTO report(report_type,period_from,period_to,summary) VALUES('PRICE_SUMMARY',DATE '2027-02-01',DATE '2027-01-01','TEST')]',-2290);
  expect_failure('referenced parent protected','DELETE FROM category WHERE category_id='||cid,-2292);
  expect_failure('invalid comparison dates',q'[DECLARE r NUMBER; BEGIN r:=fn_price_change(1,'Bengaluru',DATE '2026-09-01',DATE '2026-01-01'); END;]',-20010);
  expect_failure('missing category endpoints','BEGIN pr_refresh_inflation('||cid||q'[,DATE '2025-01-01',DATE '2025-02-01'); END;]',-20012);
  expect_failure('report procedure validation',q'[DECLARE n NUMBER; BEGIN pr_generate_report(NULL,DATE '2026-01-01',n); END;]',-20013);
  r:=fn_price_change(pid,'Bengaluru',DATE '2026-06-01',DATE '2026-09-01');
  assert_true('Rice exact three-month change = 10.2041',ABS(r-10.2041)<0.00001);
  r:=fn_price_change(pid,'Bengaluru',DATE '2025-06-01',DATE '2026-09-01');
  assert_true('missing endpoint returns NULL',r IS NULL);
  SELECT COUNT(*) INTO n FROM v_latest_prices;
  assert_true('12 latest product/location series',n=12);
  SELECT COUNT(*) INTO n FROM v_latest_prices WHERE product_id=pid AND location='Bengaluru'
    AND observed_date=DATE '2026-09-01' AND price=54;
  assert_true('latest Rice price and date',n=1);
  SELECT COUNT(*) INTO n FROM v_price_changes WHERE product_id=pid AND location='Bengaluru'
    AND observed_date=DATE '2026-09-01' AND previous_date=DATE '2026-08-01' AND change_pct=1.8868;
  assert_true('consecutive dated comparison',n=1);
  pr_refresh_inflation(cid,DATE '2026-01-01',DATE '2026-09-01');
  SELECT inflation_rate INTO r FROM inflation_data WHERE category_id=cid
    AND period_start=DATE '2026-01-01' AND period_end=DATE '2026-09-01';
  assert_true('Food unweighted category change = 5.5238',ABS(r-5.5238)<0.00001);
  SELECT COUNT(*) INTO n FROM inflation_data;
  assert_true('refresh updates instead of duplicates',n=4);
  UPDATE product SET active_status='N' WHERE product_id=pid;
  expect_failure('inactive product procedure','BEGIN pr_record_price('||pid||q'[,DATE '2027-01-01',55,'TEST','Bengaluru'); END;]',-20011);
  UPDATE product SET active_status='Y' WHERE product_id=pid;
  pr_record_price(pid,DATE '2027-01-01',55,'TEST rollback fixture','Bengaluru');
  SELECT COUNT(*) INTO n FROM price_history WHERE product_id=pid AND observed_date=DATE '2027-01-01';
  assert_true('record price procedure',n=1);
  pr_generate_report(DATE '2026-01-01',DATE '2026-09-01',rid);
  SELECT COUNT(*) INTO n FROM report WHERE report_id=rid AND DBMS_LOB.INSTR(summary,'Observations=108')>0;
  assert_true('summary snapshot contains 108 observations',n=1);
  ROLLBACK TO all_tests;
  IF bad>0 THEN RAISE_APPLICATION_ERROR(-20090,bad||' test(s) failed'); END IF;
  DBMS_OUTPUT.PUT_LINE('ALL TESTS PASSED; test rows rolled back.');
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
