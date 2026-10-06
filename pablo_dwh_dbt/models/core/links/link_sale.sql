-- LINK_SALE: связывает транзакцию (чек) и товар (позиция чека)
-- 
-- Составной ключ: transaction_hk + product_hk
-- Каждая строка = одна товарная позиция в одном чеке
-- 
-- Примечание: магазин привязывается через отдельный линк LINK_TRANSACTION_STORE,
-- так как по Data Vault 2.0 линк должен связывать только два хаба

{{ config(materialized='table') }}

WITH source AS (
    SELECT
        transaction_id,
        product_id,
        MIN(load_date) AS load_date
    FROM {{ source('staging', 'stg_sales') }}
    WHERE transaction_id IS NOT NULL
      AND product_id IS NOT NULL
    GROUP BY transaction_id, product_id
)

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'TRANSACTION'", "transaction_id"]),
        generate_hashkey(["'PRODUCT'", "product_id"])
    ]) }} AS link_sale_hk,

    {{ generate_hashkey(["'TRANSACTION'", "transaction_id"]) }} AS transaction_hk,
    {{ generate_hashkey(["'PRODUCT'", "product_id"]) }} AS product_hk,

    'stg_sales' AS record_source,
    load_date AS load_dts
FROM source
