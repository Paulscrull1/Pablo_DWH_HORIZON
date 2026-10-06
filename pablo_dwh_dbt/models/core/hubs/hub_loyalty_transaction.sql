-- HUB_LOYALTY_TRANSACTION: хаб балльных операций программы лояльности
-- 
-- Бизнес-ключ: loyalty_transaction_id
-- Связи: LINK_LOYALTY_TXN_STORE (к магазину), LINK_LOYALTY_TXN_SOURCE (к чеку)

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]) }} AS loyalty_transaction_hk,
    loyalty_transaction_id,
    'stg_loyalty_transactions' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_loyalty_transactions') }}
WHERE loyalty_transaction_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY loyalty_transaction_id ORDER BY load_date DESC) = 1
