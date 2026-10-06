-- HUB_STORE: хаб магазинов розничной сети «Горизонт»
-- 
-- Бизнес-ключ: store_id (код магазина)
-- Хэш-ключ: MD5 от 'STORE' + store_id
-- 
-- Дедупликация: QUALIFY ROW_NUMBER() — идемпотентность при перезапуске

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'STORE'", "store_id"]) }} AS store_hk,
    store_id,
    'stg_stores' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_stores') }}
WHERE store_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY load_date DESC) = 1
