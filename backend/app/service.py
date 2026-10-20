LATEST_SQL = """
SELECT l.product_id,l.category_id,l.category_name,l.product_name,l.unit,l.brand,
       l.active_status,l.location,TO_CHAR(l.observed_date,'YYYY-MM-DD') observed_date,
       l.price,l.source,TO_CHAR(ADD_MONTHS(l.observed_date,-3),'YYYY-MM-DD') comparison_date,
       fn_price_change(l.product_id,l.location,ADD_MONTHS(l.observed_date,-3),l.observed_date) change_pct
FROM v_latest_prices l
WHERE l.location=:location AND l.active_status='Y'
AND (:category_id IS NULL OR l.category_id=:category_id)
AND (:product_id IS NULL OR l.product_id=:product_id)
AND (:search IS NULL OR INSTR(LOWER(l.product_name),LOWER(:search))>0)
ORDER BY l.product_name,l.product_id OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
"""
HISTORY_SQL = """
SELECT observed_date,price,source FROM (
 SELECT TO_CHAR(observed_date,'YYYY-MM-DD') observed_date,price,source
 FROM price_history WHERE product_id=:product_id AND location=:location
 AND (:date_from IS NULL OR observed_date>=:date_from)
 AND (:date_to IS NULL OR observed_date<=:date_to)
 ORDER BY observed_date DESC FETCH FIRST :limit ROWS ONLY
) ORDER BY observed_date
"""

class Service:
    def __init__(self, db):
        self.db = db

    def history(self, **params):
        return self.db.query(HISTORY_SQL, params)

    def latest(self, **params):
        rows = self.db.query(LATEST_SQL, params)
        for row in rows:
            row['history'] = self.history(product_id=row['product_id'],location=row['location'],
                                          date_from=None,date_to=None,limit=9)
        return rows
