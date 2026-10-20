SET LINESIZE 220 PAGESIZE 100
SET NUMWIDTH 14
COLUMN product_name FORMAT A15
COLUMN category_name FORMAT A12
COLUMN location FORMAT A12
COLUMN unit FORMAT A10
COLUMN observed_on FORMAT A12
COLUMN previous_on FORMAT A12
COLUMN summary FORMAT A110 WORD_WRAPPED
PROMPT === 1. Join and filter: Rice history in Bengaluru, inclusive date range ===
SELECT p.product_name,h.location,TO_CHAR(h.observed_date,'YYYY-MM-DD') observed_on,h.price,p.unit
FROM product p JOIN price_history h ON h.product_id=p.product_id
WHERE p.product_name='Rice' AND h.location='Bengaluru'
AND h.observed_date BETWEEN DATE '2026-01-01' AND DATE '2026-09-01'
ORDER BY h.observed_date;
PROMPT === 2. Latest observation per product/location (dates may differ in real data) ===
SELECT product_name,location,TO_CHAR(observed_date,'YYYY-MM-DD') observed_on,price,unit
FROM v_latest_prices ORDER BY product_name,location;
PROMPT === 3. Consecutive available observations; row gaps are NOT calendar months ===
SELECT p.product_name,v.location,TO_CHAR(v.previous_date,'YYYY-MM-DD') previous_on,
       TO_CHAR(v.observed_date,'YYYY-MM-DD') observed_on,v.previous_price,v.price,v.change_pct
FROM v_price_changes v JOIN product p ON p.product_id=v.product_id
WHERE p.product_name='Rice' AND v.location='Bengaluru' AND v.previous_date IS NOT NULL
ORDER BY v.observed_date;
PROMPT === 4. Exact calendar endpoint comparison; NULL if either price is missing ===
SELECT product_name,fn_price_change(product_id,'Bengaluru',DATE '2026-06-01',DATE '2026-09-01') change_pct
FROM product ORDER BY product_name;
PROMPT === 5. GROUP BY, aggregates and HAVING: like-for-like series only ===
SELECT p.product_name,h.location,COUNT(*) observations,MIN(h.price) min_price,
       MAX(h.price) max_price,ROUND(AVG(h.price),2) mean_price
FROM product p JOIN price_history h ON h.product_id=p.product_id
WHERE h.observed_date BETWEEN DATE '2026-01-01' AND DATE '2026-09-01'
GROUP BY p.product_id,p.product_name,h.location HAVING COUNT(*)>=2
ORDER BY p.product_name,h.location;
PROMPT === 6. Correlated subquery: latest price exceeds its own location-series mean ===
SELECT l.product_name,l.location,l.price
FROM v_latest_prices l WHERE l.price > (
  SELECT AVG(h.price) FROM price_history h
  WHERE h.product_id=l.product_id AND h.location=l.location
  AND h.observed_date BETWEEN DATE '2026-01-01' AND DATE '2026-09-01'
) ORDER BY l.product_name,l.location;
PROMPT === 7. Category measures: unweighted comparable series, NOT official CPI ===
SELECT c.category_name,TO_CHAR(d.period_start,'YYYY-MM-DD') period_start,
       TO_CHAR(d.period_end,'YYYY-MM-DD') period_end,d.inflation_rate,
       (SELECT COUNT(*) FROM price_history a JOIN price_history b
        ON a.product_id=b.product_id AND a.location=b.location
        JOIN product p ON p.product_id=a.product_id
        WHERE p.category_id=c.category_id AND a.observed_date=d.period_start
        AND b.observed_date=d.period_end) comparable_series
FROM inflation_data d JOIN category c ON c.category_id=d.category_id ORDER BY c.category_name;
PROMPT === 8. Category coverage and stored summary ===
SELECT * FROM v_category_summary ORDER BY category_name;
SELECT report_id,report_type,TO_CHAR(period_from,'YYYY-MM-DD') period_from,
       TO_CHAR(period_to,'YYYY-MM-DD') period_to,DBMS_LOB.SUBSTR(summary,500,1) summary
FROM report ORDER BY report_id;
