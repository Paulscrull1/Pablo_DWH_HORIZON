-- LINK_LOYALTY_TXN_SOURCE: связывает балльную операцию с исходным чеком
-- 
-- Составной ключ: loyalty_transaction_hk + transaction_hk
-- source_transaction_id может быть NULL (если операция не привязана к чеку)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]),
        generate_hashkey(["'TRANSACTION'", "source_transaction_id"])
    ]) }} AS link_loyalty_txn_source_hk,

    {{ generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]) }} AS loyalty_transaction_hk,
    {{ generate_hashkey(["'TRANSACTION'", "source_transaction_id"]) }} AS transaction_hk,

    'stg_loyalty_transactions' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_loyalty_transactions') }}
WHERE loyalty_transaction_id IS NOT NULL 
  AND source_transaction_id IS NOT NULL
