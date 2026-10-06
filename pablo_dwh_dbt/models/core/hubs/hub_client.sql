-- HUB_CLIENT: хаб клиентов программы лояльности
-- 
-- Бизнес-ключ: client_id (уникальный ID клиента из loyalty_db)
-- Источник: PostgreSQL (таблица clients)

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'CLIENT'", "toString(client_id)"]) }} AS client_hk,
    client_id,
    'stg_clients' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_clients') }}
WHERE client_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY load_date DESC) = 1
