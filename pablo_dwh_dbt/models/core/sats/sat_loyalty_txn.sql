-- SAT_LOYALTY_TXN: атрибуты балльной операции
-- 
-- Атрибуты: points (начисление/списание), transaction_date, operation_type
-- operation_type: 'accrual' (начисление) или 'writeoff' (списание)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'LOYALTY_TXN'", "toString(loyalty_transaction_id)"]) }} AS loyalty_transaction_hk,
    loyalty_transaction_id,
    points,
    transaction_date,
    operation_type,
    'stg_loyalty_transactions' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_loyalty_transactions') }}
WHERE loyalty_transaction_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY loyalty_transaction_id ORDER BY load_date DESC) = 1
