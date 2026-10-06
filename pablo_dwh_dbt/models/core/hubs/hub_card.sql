-- HUB_CARD: хаб карт лояльности
-- 
-- Бизнес-ключ: card_id (уникальный ID карты)
-- Связь с клиентом: через LINK_CARD_CLIENT

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'CARD'", "toString(card_id)"]) }} AS card_hk,
    card_id,
    'stg_cards' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_cards') }}
WHERE card_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY load_date DESC) = 1
