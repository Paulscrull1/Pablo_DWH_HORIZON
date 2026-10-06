-- Сверка суммы продаж между staging и mart слоями
-- Расхождение должно быть 0

WITH staging_sum AS (
    SELECT SUM(amount) AS total FROM staging.stg_sales
),
mart_sum AS (
    SELECT SUM(sum_sales) AS total FROM dds.fct_sales_daily
)
SELECT 
    s.total AS staging_total,
    m.total AS mart_total,
    ABS(s.total - m.total) AS difference,
    IF(ABS(s.total - m.total) < 0.01, 'OK', 'MISMATCH') AS status
FROM staging_sum s, mart_sum m;
