-- DIM_PRODUCT: измерение товаров (SCD Type 2)
-- 
-- Суррогатный ключ: product_key (UInt64, автоинкремент через rowNumber)
-- Бизнес-ключ: product_id
-- 
-- SCD Type 2 реализация:
--   - valid_from: дата начала действия версии
--   - valid_to: 2099-12-31 для текущей версии (маркер "бессрочно")
--   - is_current: 1 для актуальной версии
-- 
-- Используется в fct_sales_daily через product_key

{{ config(materialized='table') }}

SELECT
    rowNumberInAllBlocks() + 1 AS product_key,
    hp.product_hk AS product_hk,
    hp.product_id AS product_id,
    sps.product_name AS product_name,
    sps.category AS category,
    sps.brand AS brand,
    spd.unit_price AS unit_price,
    spd.status AS status,
    hp.load_dts AS valid_from,
    toDate('2099-12-31') AS valid_to,
    1 AS is_current
FROM {{ ref('hub_product') }} hp
LEFT JOIN {{ ref('sat_product_static') }} sps ON hp.product_hk = sps.product_hk
LEFT JOIN {{ ref('sat_product_dynamic') }} spd ON hp.product_hk = spd.product_hk
