-- SAT_PRODUCT_STATIC: неизменяемые атрибуты товара
-- 
-- Атрибуты: product_name, category, brand
-- Эти атрибуты редко меняются, поэтому хранятся в отдельном сателлите
-- SCD Type 1: перезаписываем при изменении (упрощение)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'PRODUCT'", "product_id"]) }} AS product_hk,
    product_id,
    product_name,
    category,
    brand,
    'stg_products' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_products') }}
WHERE product_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY load_date DESC) = 1
