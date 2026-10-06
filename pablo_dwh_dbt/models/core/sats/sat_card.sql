-- SAT_CARD: атрибуты карты лояльности
-- 
-- Атрибуты: card_number, issue_date, status
-- Тест accepted_values применяется к полю status (active/blocked/expired)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'CARD'", "toString(card_id)"]) }} AS card_hk,
    card_id,
    card_number,
    issue_date,
    status,
    'stg_cards' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_cards') }}
WHERE card_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY load_date DESC) = 1
