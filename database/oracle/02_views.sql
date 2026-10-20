PROMPT === Reusable analytical views ===
CREATE VIEW v_latest_prices AS
SELECT price_id,product_id,category_id,category_name,product_name,unit,brand,
       active_status,location,observed_date,price,source
FROM (
  SELECT h.price_id,p.product_id,p.category_id,c.category_name,p.product_name,
         p.unit,p.brand,p.active_status,h.location,h.observed_date,h.price,h.source,
         ROW_NUMBER() OVER (PARTITION BY h.product_id,h.location ORDER BY h.observed_date DESC) rn
  FROM price_history h JOIN product p ON p.product_id=h.product_id
  JOIN category c ON c.category_id=p.category_id
) WHERE rn=1;
CREATE VIEW v_price_changes AS
SELECT product_id,location,previous_date,observed_date,previous_price,price,
       ROUND(100*(price-previous_price)/NULLIF(previous_price,0),4) AS change_pct
FROM (
  SELECT product_id,location,observed_date,price,
         LAG(observed_date) OVER (PARTITION BY product_id,location ORDER BY observed_date) previous_date,
         LAG(price) OVER (PARTITION BY product_id,location ORDER BY observed_date) previous_price
  FROM price_history
);
CREATE VIEW v_category_summary AS
SELECT c.category_id,c.category_name,COUNT(DISTINCT p.product_id) product_count,
       COUNT(h.price_id) observation_count,MIN(h.observed_date) first_observation,
       MAX(h.observed_date) last_observation
FROM category c LEFT JOIN product p ON p.category_id=c.category_id
LEFT JOIN price_history h ON h.product_id=p.product_id
GROUP BY c.category_id,c.category_name;
