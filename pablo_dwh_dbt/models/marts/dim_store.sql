-- DIM_STORE: измерение магазинов (SCD Type 2)
-- 
-- Суррогатный ключ: store_key (UInt64)
-- Бизнес-ключ: store_id
-- 
-- SCD Type 2: отслеживание изменений адреса/региона магазина
-- valid_to = 2099-12-31 для текущей версии (маркер "бессрочно")

{{ config(materialized='table') }}

SELECT
    rowNumberInAllBlocks() + 1 AS store_key,
    hs.store_hk AS store_hk,
    hs.store_id AS store_id,
    ss.address AS address,
    ss.region AS region,
    hs.load_dts AS valid_from,
    toDate('2099-12-31') AS valid_to,
    1 AS is_current
FROM {{ ref('hub_store') }} hs
LEFT JOIN {{ ref('sat_store') }} ss ON hs.store_hk = ss.store_hk
