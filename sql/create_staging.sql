DROP DATABASE IF EXISTS staging;
CREATE DATABASE staging;

CREATE TABLE staging.stg_sales (
    transaction_id String, product_id String, amount Decimal(10, 2), quantity Decimal(10, 3),
    store_id String, datetime DateTime, loyalty_card_id Nullable(Int32), payment_method String,
    load_date Date DEFAULT today()
) ENGINE = MergeTree() ORDER BY (transaction_id, product_id);

CREATE TABLE staging.stg_stores (
    store_id String, chain String, format String, region String, city String, district String,
    address String, phone String, opening_year Int32, area_sqm Int32, load_date Date DEFAULT today()
) ENGINE = ReplacingMergeTree(load_date) ORDER BY store_id;

CREATE TABLE staging.stg_products (
    product_id String, product_name String, category String, brand String, unit_price Decimal(10, 2), status String, load_date Date DEFAULT today()
) ENGINE = ReplacingMergeTree(load_date) ORDER BY product_id;

CREATE TABLE staging.stg_clients (
    client_id Int32, full_name String, gender String, birth_date Date, phone String, email String,
    registration_date Date, city String, income_level String, load_date Date DEFAULT today()
) ENGINE = ReplacingMergeTree(load_date) ORDER BY client_id;

CREATE TABLE staging.stg_cards (
    card_id Int32, client_id Int32, card_number String, card_type String, issue_date Date,
    expiry_date Date, status String, points_balance Int32, load_date Date DEFAULT today()
) ENGINE = ReplacingMergeTree(load_date) ORDER BY card_id;

CREATE TABLE staging.stg_loyalty_transactions (
    loyalty_transaction_id Int32, card_id Int32, points Int32, transaction_date DateTime,
    store_id String, source_transaction_id String, operation_type String, load_date Date DEFAULT today()
) ENGINE = MergeTree() ORDER BY loyalty_transaction_id;

CREATE TABLE staging.stg_employees (
    employee_id Int32, full_name String, position String, store_id String, hire_date Date,
    termination_date Nullable(Date), load_date Date DEFAULT today()
) ENGINE = ReplacingMergeTree(load_date) ORDER BY employee_id;
