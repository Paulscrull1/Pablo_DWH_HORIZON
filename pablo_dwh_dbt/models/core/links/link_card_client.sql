-- LINK_CARD_CLIENT: принадлежность карты лояльности клиенту
-- 
-- Составной ключ: card_hk + client_hk
-- Источник: stg_cards (поле client_id — внешний ключ)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'CARD'", "toString(card_id)"]),
        generate_hashkey(["'CLIENT'", "toString(client_id)"])
    ]) }} AS link_card_client_hk,

    {{ generate_hashkey(["'CARD'", "toString(card_id)"]) }} AS card_hk,
    {{ generate_hashkey(["'CLIENT'", "toString(client_id)"]) }} AS client_hk,

    'stg_cards' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_cards') }}
WHERE card_id IS NOT NULL AND client_id IS NOT NULL
