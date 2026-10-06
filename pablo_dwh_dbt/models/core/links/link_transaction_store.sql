-- LINK_TRANSACTION_STORE: привязывает чек к магазину
-- 
-- Составной ключ: transaction_hk + store_hk
-- Каждый чек совершается в одном магазине
-- Источник: stg_sales (поле store_id)

{{ config(materialized='table') }}

WITH source AS (
    SELECT
        transaction_id,
        store_id,
        MIN(load_date) AS load_date
    FROM {{ source('staging', 'stg_sales') }}
    WHERE transaction_id IS NOT NULL
      AND store_id IS NOT NULL
    GROUP BY transaction_id, store_id
)

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'TRANSACTION'", "transaction_id"]),
        generate_hashkey(["'STORE'", "store_id"])
    ]) }} AS link_transaction_store_hk,

    {{ generate_hashkey(["'TRANSACTION'", "transaction_id"]) }} AS transaction_hk,
    {{ generate_hashkey(["'STORE'", "store_id"]) }} AS store_hk,

    'stg_sales' AS record_source,
    load_date AS load_dts
FROM source
