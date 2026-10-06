-- SAT_SALE: атрибуты позиции чека (связаны с LINK_SALE)
-- 
-- Атрибуты: amount (сумма по позиции), quantity (количество)
-- Источник: stg_sales

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'TRANSACTION'", "transaction_id"]),
        generate_hashkey(["'PRODUCT'", "product_id"])
    ]) }} AS link_sale_hk,
    transaction_id,
    product_id,
    amount AS total_amount,
    quantity,
    'stg_sales' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_sales') }}
WHERE transaction_id IS NOT NULL AND product_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY transaction_id, product_id 
    ORDER BY load_date DESC
) = 1
