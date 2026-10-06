-- SAT_EMPLOYEE: атрибуты сотрудника
-- 
-- Атрибуты: full_name, position, hire_date, termination_date
-- termination_date = NULL означает, что сотрудник работает
-- Источник: hr.json (эмуляция API ERP)

{{ config(materialized='table') }}

SELECT
    {{ generate_hashkey(["'EMPLOYEE'", "toString(employee_id)"]) }} AS employee_hk,
    employee_id,
    full_name,
    position,
    hire_date,
    termination_date,
    'stg_employees' AS record_source,
    load_date AS load_dts
FROM {{ source('staging', 'stg_employees') }}
WHERE employee_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY load_date DESC) = 1
