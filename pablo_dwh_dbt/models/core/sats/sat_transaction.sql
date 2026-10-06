-- SAT_TRANSACTION: атрибуты кассового чека
-- 
-- Атрибуты: transaction_datetime, total_amount (сумма чека)
-- 
-- total_amount вычисляется как сумма amount по всем позициям чека
-- Это необходимо для расчёта avg_transaction_amount в витрине

{{ config(materialized='table') }}

WITH txn_totals AS (
    SELECT
        transaction_id,
        datetime AS transaction_datetime,
        SUM(amount) AS total_amount,
        MIN(load_date) AS load_date
    FROM {{ source('staging', 'stg_sales') }}
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id, datetime
)

SELECT
    {{ generate_hashkey(["'TRANSACTION'", "transaction_id"]) }} AS transaction_hk,
    transaction_id,
    transaction_datetime,
    total_amount,
    'stg_sales' AS record_source,
    load_date AS load_dts
FROM txn_totals
