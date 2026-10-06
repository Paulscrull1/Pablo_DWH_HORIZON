-- LINK_LOYALTY_TXN_STORE: привязывает балльную операцию к магазину
-- 
-- Составной ключ: loyalty_transaction_hk + store_hk
-- store_id может быть NULL для онлайн-операций — такие записи исключаются

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]),
        generate_hashkey(["'STORE'", "store_id"])
    ]) }} AS link_loyalty_txn_store_hk,

    {{ generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]) }} AS loyalty_transaction_hk,
    {{ generate_hashkey(["'STORE'", "store_id"]) }} AS store_hk,

    'stg_loyalty_transactions' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_loyalty_transactions') }}
WHERE loyalty_transaction_id IS NOT NULL 
  AND store_id IS NOT NULL
