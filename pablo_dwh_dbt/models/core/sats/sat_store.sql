-- SAT_STORE: атрибуты магазина
-- 
-- Атрибуты: address, region, phone, format
-- Источник: stores.csv

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'STORE'", "store_id"]) }} AS store_hk,
    store_id,
    address,
    region,
    phone,
    format,
    'stg_stores' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_stores') }}
WHERE store_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY load_date DESC) = 1
