-- SAT_CLIENT: атрибуты клиента программы лояльности
-- 
-- Атрибуты: full_name, birth_date, phone, email, registration_date
-- Источник: PostgreSQL (таблица clients)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'CLIENT'", "toString(client_id)"]) }} AS client_hk,
    client_id,
    full_name,
    birth_date,
    phone,
    email,
    registration_date,
    'stg_clients' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_clients') }}
WHERE client_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY load_date DESC) = 1
