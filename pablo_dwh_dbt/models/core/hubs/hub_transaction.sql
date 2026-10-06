-- HUB_TRANSACTION: хаб кассовых транзакций (чеков)
-- 
-- Бизнес-ключ: transaction_id (UUID чека из кассовой системы)
-- Источник: CSV-файлы sales_YYYYMMDD.csv

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'TRANSACTION'", "transaction_id"]) }} AS transaction_hk,
    transaction_id,
    'stg_sales' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_sales') }}
WHERE transaction_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY load_date DESC) = 1
