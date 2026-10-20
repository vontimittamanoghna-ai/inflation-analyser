PROMPT === Business operations; callers control COMMIT and ROLLBACK ===
CREATE OR REPLACE FUNCTION fn_price_change (
  p_product_id NUMBER, p_location VARCHAR2, p_from DATE, p_to DATE
) RETURN NUMBER IS
  a NUMBER; b NUMBER;
BEGIN
  IF p_from IS NULL OR p_to IS NULL OR p_to<=p_from OR
     p_from<>TRUNC(p_from) OR p_to<>TRUNC(p_to) THEN
    RAISE_APPLICATION_ERROR(-20010,'Use two increasing calendar dates.');
  END IF;
  SELECT MAX(CASE WHEN observed_date=p_from THEN price END),
         MAX(CASE WHEN observed_date=p_to THEN price END)
    INTO a,b FROM price_history
   WHERE product_id=p_product_id AND location=p_location AND observed_date IN (p_from,p_to);
  IF a IS NULL OR b IS NULL THEN RETURN NULL; END IF;
  RETURN ROUND(100*(b-a)/a,4);
END;
/
SHOW ERRORS FUNCTION fn_price_change

CREATE OR REPLACE PROCEDURE pr_record_price (
  p_product_id NUMBER, p_date DATE, p_price NUMBER, p_source VARCHAR2, p_location VARCHAR2
) IS
  s product.active_status%TYPE;
BEGIN
  SELECT active_status INTO s FROM product WHERE product_id=p_product_id FOR UPDATE;
  IF s<>'Y' THEN RAISE_APPLICATION_ERROR(-20011,'Cannot record new prices for an inactive product.'); END IF;
  INSERT INTO price_history(product_id,observed_date,price,source,location)
  VALUES(p_product_id,p_date,p_price,p_source,p_location);
END;
/
SHOW ERRORS PROCEDURE pr_record_price

CREATE OR REPLACE PROCEDURE pr_refresh_inflation (
  p_category_id NUMBER, p_from DATE, p_to DATE
) IS
  r NUMBER;
BEGIN
  IF p_from IS NULL OR p_to IS NULL OR p_to<=p_from OR
     p_from<>TRUNC(p_from) OR p_to<>TRUNC(p_to) THEN
    RAISE_APPLICATION_ERROR(-20010,'Use two increasing calendar dates.');
  END IF;
  SELECT ROUND(AVG(100*(b.price-a.price)/a.price),4) INTO r
  FROM price_history a JOIN price_history b
    ON b.product_id=a.product_id AND b.location=a.location
  JOIN product p ON p.product_id=a.product_id
  WHERE p.category_id=p_category_id AND a.observed_date=p_from AND b.observed_date=p_to;
  IF r IS NULL THEN RAISE_APPLICATION_ERROR(-20012,'No comparable series at both exact endpoint dates.'); END IF;
  MERGE INTO inflation_data d
  USING (SELECT p_category_id cid,p_from df,p_to dt,r rate FROM dual) s
  ON (d.category_id=s.cid AND d.period_start=s.df AND d.period_end=s.dt)
  WHEN MATCHED THEN UPDATE SET d.inflation_rate=s.rate
  WHEN NOT MATCHED THEN INSERT(category_id,period_start,period_end,inflation_rate)
       VALUES(s.cid,s.df,s.dt,s.rate);
END;
/
SHOW ERRORS PROCEDURE pr_refresh_inflation

CREATE OR REPLACE PROCEDURE pr_generate_report (
  p_from DATE, p_to DATE, p_report_id OUT NUMBER
) IS
  n NUMBER; products NUMBER; locations NUMBER;
BEGIN
  IF p_from IS NULL OR p_to IS NULL OR p_to<p_from OR
     p_from<>TRUNC(p_from) OR p_to<>TRUNC(p_to) THEN
    RAISE_APPLICATION_ERROR(-20013,'Use an inclusive calendar date range.');
  END IF;
  SELECT COUNT(*),COUNT(DISTINCT product_id),COUNT(DISTINCT location)
    INTO n,products,locations FROM price_history WHERE observed_date BETWEEN p_from AND p_to;
  INSERT INTO report(report_type,period_from,period_to,summary)
  VALUES('PRICE_SUMMARY',p_from,p_to,
    'Demonstration dataset; not official CPI. Observations='||n||
    '; products='||products||'; locations='||locations||
    '. Range='||TO_CHAR(p_from,'YYYY-MM-DD')||' to '||TO_CHAR(p_to,'YYYY-MM-DD')||
    '. Category measures use exact endpoint pairs and equal product/location weights.')
  RETURNING report_id INTO p_report_id;
END;
/
SHOW ERRORS PROCEDURE pr_generate_report

CREATE OR REPLACE TRIGGER trg_product_unit_lock
BEFORE UPDATE OF unit ON product FOR EACH ROW
DECLARE n NUMBER;
BEGIN
  IF :NEW.unit<>:OLD.unit THEN
    SELECT COUNT(*) INTO n FROM price_history WHERE product_id=:OLD.product_id;
    IF n>0 THEN RAISE_APPLICATION_ERROR(-20014,'Unit has price history. Create a distinct product definition instead.'); END IF;
  END IF;
END;
/
SHOW ERRORS TRIGGER trg_product_unit_lock
