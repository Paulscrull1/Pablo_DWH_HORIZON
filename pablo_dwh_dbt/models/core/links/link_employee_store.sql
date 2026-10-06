-- LINK_EMPLOYEE_STORE: трудоустройство сотрудника в магазине
-- 
-- Составной ключ: employee_hk + store_hk
-- Источник: hr.json (эмуляция API ERP-системы)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey([
        generate_hashkey(["'EMPLOYEE'", "toString(employee_id)"]),
        generate_hashkey(["'STORE'", "store_id"])
    ]) }} AS link_employee_store_hk,

    {{ generate_hashkey(["'EMPLOYEE'", "toString(employee_id)"]) }} AS employee_hk,
    {{ generate_hashkey(["'STORE'", "store_id"]) }} AS store_hk,

    'stg_employees' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_employees') }}
WHERE employee_id IS NOT NULL AND store_id IS NOT NULL
