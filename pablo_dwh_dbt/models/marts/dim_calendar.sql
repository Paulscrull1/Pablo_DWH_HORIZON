-- DIM_CALENDAR: измерение календаря
-- 
-- Суррогатный ключ: date_key (формат YYYYMMDD, тип Int32)
-- Генерируется на лету через range() для диапазона дат
-- 
-- Атрибуты: день недели, месяц, квартал, год, флаг праздника
-- Используется во всех фактах для временного анализа

{{ config(materialized='table') }}

SELECT
    toInt32(toYYYYMMDD(d)) AS date_key,
    d AS full_date,
    toDayOfWeek(d) AS day_of_week,
    toString(toDayOfWeek(d)) AS day_name,
    toMonth(d) AS month,
    toString(toMonth(d)) AS month_name,
    toQuarter(d) AS quarter,
    toYear(d) AS year,
    0 AS is_holiday
FROM (
    SELECT toDate('2025-10-01') + number AS d
    FROM numbers(730)
)
