-- Проверка отсутствия дубликатов хэш-ключей в Хабах

WITH table_counts AS (
    SELECT 'hub_client' AS table_name, COUNT() AS total, COUNT(DISTINCT client_hk) AS unique_keys FROM dds.hub_client UNION ALL
    SELECT 'hub_product', COUNT(), COUNT(DISTINCT product_hk) FROM dds.hub_product UNION ALL
    SELECT 'hub_store', COUNT(), COUNT(DISTINCT store_hk) FROM dds.hub_store UNION ALL
    SELECT 'hub_transaction', COUNT(), COUNT(DISTINCT transaction_hk) FROM dds.hub_transaction UNION ALL
    SELECT 'hub_card', COUNT(), COUNT(DISTINCT card_hk) FROM dds.hub_card UNION ALL
    SELECT 'hub_loyalty_transaction', COUNT(), COUNT(DISTINCT loyalty_transaction_hk) FROM dds.hub_loyalty_transaction UNION ALL
    SELECT 'hub_employee', COUNT(), COUNT(DISTINCT employee_hk) FROM dds.hub_employee
)
SELECT 
    table_name,
    total,
    unique_keys,
    IF(total = unique_keys, 'No duplicates', 'Duplicates found') AS status
FROM table_counts
ORDER BY table_name;
