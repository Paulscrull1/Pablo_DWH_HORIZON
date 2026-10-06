-- HUB_PRODUCT: хаб товаров розничной сети
-- 
-- Бизнес-ключ: product_id (SKU товара)
-- Хэш-ключ: вычисляется как MD5 от константы 'PRODUCT' + product_id
-- 
-- Дедупликация: используется QUALIFY ROW_NUMBER() для выбора
-- последней версии записи по load_date (идемпотентность пайплайна)
-- Это гарантирует отсутствие дубликатов при повторных запусках DAG

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'PRODUCT'", "product_id"]) }} AS product_hk,
    product_id,
    'stg_products' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_products') }}
WHERE product_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY load_date DESC) = 1
