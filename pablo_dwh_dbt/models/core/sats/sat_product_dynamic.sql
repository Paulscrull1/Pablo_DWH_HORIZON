-- SAT_PRODUCT_DYNAMIC: изменяемые атрибуты товара (SCD Type 2)
-- 
-- Атрибуты: unit_price, status
-- Эти атрибуты меняются часто (цены, статус наличия)
-- 
-- SCD Type 2 реализация:
--   - valid_from: дата начала действия версии
--   - valid_to: дата окончания (2099-12-31 для текущей версии)
--   - is_current: флаг текущей версии (1 = актуальна)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'PRODUCT'", "product_id"]) }} AS product_hk,
    product_id,
    unit_price,
    status,
    load_date AS valid_from,
    toDate('2099-12-31') AS valid_to,
    1 AS is_current,
    'stg_products' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_products') }}
WHERE product_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY load_date DESC) = 1
