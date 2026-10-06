-- Витрина ежедневных продаж: агрегация по дню, магазину и товару
-- 
-- Метрики:
--   sum_sales: сумма продаж товара за день в магазине
--   num_transactions: количество уникальных чеков с этим товаром
--   avg_transaction_amount: средний чек (сумма всех чеков / количество чеков)
--
-- Источники:
--   link_sale: позиция чека (transaction + product)
--   link_transaction_store: привязка чека к магазину (transaction + store)
--   sat_sale: сумма и количество по позиции
--   sat_transaction: дата чека и общая сумма чека
--   dim_store, dim_product: справочники для суррогатных ключей

{{ config(materialized='table') }}

WITH sales_with_store AS (
    -- Соединяем позицию чека с привязкой чека к магазину
    -- link_sale содержит только transaction + product, поэтому нужен link_transaction_store
    SELECT
        ls.transaction_hk,
        ls.product_hk,
        lts.store_hk,
        ls.link_sale_hk
    FROM {{ ref('link_sale') }} ls
    INNER JOIN {{ ref('link_transaction_store') }} lts 
        ON ls.transaction_hk = lts.transaction_hk
)

SELECT
    -- Суррогатный ключ даты в формате YYYYMMDD
    toInt32(toYYYYMMDD(toDate(sat_txn.transaction_datetime))) AS date_key,
    -- Используем store_key и product_key из измерений (тип UInt64)
    ds.store_key,
    dp.product_key,
    
    -- Сумма продаж товара за день в магазине
    SUM(sat_sale.total_amount) AS sum_sales,
    
    -- Количество уникальных чеков, содержащих этот товар
    uniqExact(sws.transaction_hk) AS num_transactions,
    
    -- Средний чек: сумма всех чеков / количество уникальных чеков
    round(
        SUM(sat_txn.total_amount) / uniqExact(sws.transaction_hk), 
        2
    ) AS avg_transaction_amount

FROM sales_with_store sws
INNER JOIN {{ ref('sat_sale') }} sat_sale 
    ON sws.link_sale_hk = sat_sale.link_sale_hk
INNER JOIN {{ ref('sat_transaction') }} sat_txn 
    ON sws.transaction_hk = sat_txn.transaction_hk
-- JOIN с измерениями по хэш-ключам (тип String)
INNER JOIN {{ ref('dim_store') }} ds 
    ON sws.store_hk = ds.store_hk
INNER JOIN {{ ref('dim_product') }} dp 
    ON sws.product_hk = dp.product_hk

GROUP BY 
    date_key, 
    ds.store_key, 
    dp.product_key
