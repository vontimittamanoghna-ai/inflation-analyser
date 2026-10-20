PROMPT === SYNTHETIC teaching fixtures, not real market data ===
-- Six frontend products; dates/locations below are invented demonstration fixtures.
INSERT INTO category(category_name,description) VALUES('Food','Synthetic food price examples');
INSERT INTO category(category_name,description) VALUES('Fuel','Synthetic transport fuel example');
INSERT INTO category(category_name,description) VALUES('Household','Synthetic cooking oil example');
INSERT INTO category(category_name,description) VALUES('Utilities','Synthetic electricity example');
DECLARE
  rid NUMBER;
  PROCEDURE add_product(n VARCHAR2,c VARCHAR2,u VARCHAR2,prices SYS.ODCINUMBERLIST) IS
    cid NUMBER; pid NUMBER;
  BEGIN
    SELECT category_id INTO cid FROM category WHERE category_name=c;
    INSERT INTO product(category_id,product_name,unit,brand,active_status)
    VALUES(cid,n,u,'Generic','Y') RETURNING product_id INTO pid;
    FOR i IN 1..prices.COUNT LOOP
      pr_record_price(pid,ADD_MONTHS(DATE '2026-01-01',i-1),prices(i),
        'SYNTHETIC frontend-derived teaching fixture','Bengaluru');
      pr_record_price(pid,ADD_MONTHS(DATE '2026-01-01',i-1),ROUND(prices(i)*1.05,2),
        'SYNTHETIC teaching fixture: Bengaluru price x 1.05','Chennai');
    END LOOP;
  END;
BEGIN
  add_product('Rice','Food','1 kg',SYS.ODCINUMBERLIST(42,45,44,47,50,49,52,53,54));
  add_product('Milk','Food','1 litre',SYS.ODCINUMBERLIST(50,52,51,55,54,58,57,60,62));
  add_product('Tomato','Food','1 kg',SYS.ODCINUMBERLIST(50,47,45,48,40,42,37,35,32));
  add_product('Petrol','Fuel','1 litre',SYS.ODCINUMBERLIST(96,98,97,100,99,102,101,103,104.5));
  add_product('Cooking Oil','Household','1 litre',SYS.ODCINUMBERLIST(120,125,123,130,127,135,131,138,142));
  add_product('Electricity','Utilities','1 kWh',SYS.ODCINUMBERLIST(7,7.3,7.2,7.7,7.5,8,7.9,8.2,8.5));
  FOR c IN (SELECT category_id FROM category) LOOP
    pr_refresh_inflation(c.category_id,DATE '2026-01-01',DATE '2026-09-01');
  END LOOP;
  pr_generate_report(DATE '2026-01-01',DATE '2026-09-01',rid);
  DBMS_OUTPUT.PUT_LINE('Created demonstration report id='||rid);
END;
/
COMMIT;
