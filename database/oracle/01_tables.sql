PROMPT === Five entities, created in dependency order (Oracle 12c+) ===
CREATE TABLE category (
  category_id NUMBER GENERATED ALWAYS AS IDENTITY,
  category_name VARCHAR2(60 CHAR) NOT NULL,
  description VARCHAR2(500 CHAR),
  CONSTRAINT pk_category PRIMARY KEY (category_id),
  CONSTRAINT uq_category_name UNIQUE (category_name),
  CONSTRAINT ck_category_name CHECK (TRIM(category_name) IS NOT NULL AND category_name=TRIM(category_name))
);
CREATE TABLE product (
  product_id NUMBER GENERATED ALWAYS AS IDENTITY,
  category_id NUMBER NOT NULL,
  product_name VARCHAR2(100 CHAR) NOT NULL,
  unit VARCHAR2(40 CHAR) NOT NULL,
  brand VARCHAR2(100 CHAR) DEFAULT 'Generic' NOT NULL,
  active_status CHAR(1) DEFAULT 'Y' NOT NULL,
  CONSTRAINT pk_product PRIMARY KEY (product_id),
  CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES category(category_id),
  CONSTRAINT uq_product_definition UNIQUE (category_id,product_name,unit,brand),
  CONSTRAINT ck_product_active CHECK (active_status IN ('Y','N')),
  CONSTRAINT ck_product_text CHECK (TRIM(product_name) IS NOT NULL AND TRIM(unit) IS NOT NULL AND TRIM(brand) IS NOT NULL)
);
CREATE TABLE price_history (
  price_id NUMBER GENERATED ALWAYS AS IDENTITY,
  product_id NUMBER NOT NULL,
  observed_date DATE NOT NULL,
  price NUMBER(12,2) NOT NULL,
  source VARCHAR2(200 CHAR) NOT NULL,
  location VARCHAR2(100 CHAR) NOT NULL,
  CONSTRAINT pk_price_history PRIMARY KEY (price_id),
  CONSTRAINT fk_price_product FOREIGN KEY (product_id) REFERENCES product(product_id),
  CONSTRAINT uq_price_observation UNIQUE (product_id,location,observed_date),
  CONSTRAINT ck_price_positive CHECK (price > 0),
  CONSTRAINT ck_price_date CHECK (observed_date=TRUNC(observed_date)),
  CONSTRAINT ck_price_text CHECK (TRIM(source) IS NOT NULL AND TRIM(location) IS NOT NULL AND location=TRIM(location))
);
CREATE TABLE inflation_data (
  inflation_id NUMBER GENERATED ALWAYS AS IDENTITY,
  category_id NUMBER NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  inflation_rate NUMBER(12,4) NOT NULL,
  CONSTRAINT pk_inflation_data PRIMARY KEY (inflation_id),
  CONSTRAINT fk_inflation_category FOREIGN KEY (category_id) REFERENCES category(category_id),
  CONSTRAINT uq_inflation_period UNIQUE (category_id,period_start,period_end),
  CONSTRAINT ck_inflation_period CHECK (period_end>period_start AND period_start=TRUNC(period_start) AND period_end=TRUNC(period_end)),
  CONSTRAINT ck_inflation_rate CHECK (inflation_rate > -100)
);
CREATE TABLE report (
  report_id NUMBER GENERATED ALWAYS AS IDENTITY,
  generated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
  report_type VARCHAR2(30 CHAR) NOT NULL,
  period_from DATE NOT NULL,
  period_to DATE NOT NULL,
  summary CLOB NOT NULL,
  CONSTRAINT pk_report PRIMARY KEY (report_id),
  CONSTRAINT ck_report_type CHECK (report_type IN ('PRICE_SUMMARY','CATEGORY_INFLATION')),
  CONSTRAINT ck_report_period CHECK (period_to>=period_from AND period_from=TRUNC(period_from) AND period_to=TRUNC(period_to))
);
CREATE INDEX ix_product_category ON product(category_id);
COMMENT ON TABLE inflation_data IS 'Unweighted mean of exact-endpoint product/location price changes; not official CPI. Refresh after observation corrections.';
COMMENT ON TABLE report IS 'Historical text snapshots; intentionally independent per approved five-entity ER diagram.';
COMMENT ON COLUMN price_history.price IS 'INR per fixed PRODUCT.unit; all demo observations are synthetic.';
