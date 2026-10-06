-- HUB_EMPLOYEE: хаб сотрудников розничной сети
-- 
-- Бизнес-ключ: employee_id
-- Связь с магазином: через LINK_EMPLOYEE_STORE

{{ config(materialized='table') }}

SELECT 
    {{ generate_hashkey(["'EMPLOYEE'", "toString(employee_id)"]) }} AS employee_hk,
    employee_id,
    'stg_employees' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_employees') }}
WHERE employee_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY load_date DESC) = 1
