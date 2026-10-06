# Скрипт валидации качества данных в staging через Great Expectations
import great_expectations as gx
from great_expectations.core.batch import RuntimeBatchRequest
from clickhouse_driver import Client
import pandas as pd
import json

# Подключение к ClickHouse через внутреннюю docker-сеть
client = Client(host='clickhouse', port=9000, user='hduser', password='hduser')

# Получаем данные из staging
query = """
SELECT 
    transaction_id,
    product_id,
    amount,
    quantity,
    store_id,
    datetime,
    loyalty_card_id,
    payment_method
FROM staging.stg_sales
"""

print("Загрузка данных из staging.stg_sales...")
result = client.execute(query)
df = pd.DataFrame(result, columns=[
    'transaction_id', 'product_id', 'amount', 'quantity',
    'store_id', 'datetime', 'loyalty_card_id', 'payment_method'
])
print(f"Загружено строк: {len(df)}")

# Инициализация GX контекста
context = gx.get_context(context_root_dir="/opt/airflow/great_expectations")

# Загружаем expectation suite из JSON-файла
suite_path = "/opt/airflow/gx_reports/stg_sales_suite.json"
with open(suite_path, 'r') as f:
    suite_json = json.load(f)

# Создаём data source на основе pandas
data_source = context.sources.add_or_update_pandas(name="staging_sales")
data_asset = data_source.add_dataframe_asset(name="sales_df")
batch_request = data_asset.build_batch_request(dataframe=df)

# Создаём expectation suite
suite = context.add_expectation_suite(expectation_suite_name="stg_sales_suite")

# Добавляем ожидания из JSON
for exp in suite_json['expectations']:
    suite.add_expectation(
        gx.core.expectation_configuration.ExpectationConfiguration(
            expectation_type=exp['expectation_type'],
            kwargs=exp['kwargs'],
            meta=exp.get('meta', {})
        )
    )

# Сохраняем suite
context.save_expectation_suite(suite)

# Запускаем валидацию
validator = context.get_validator(batch_request=batch_request, expectation_suite=suite)
results = validator.validate()

# Вывод результатов
print("=" * 60)
print("GREAT EXPECTATIONS: РЕЗУЛЬТАТЫ ВАЛИДАЦИИ STAGING")
print("=" * 60)
print(f"Общий статус: {'УСПЕХ' if results.success else 'ПРОВАЛ'}")
print(f"Проверено ожиданий: {results.statistics['evaluated_expectations']}")
print(f"Пройдено: {results.statistics['successful_expectations']}")
print(f"Провалено: {results.statistics['unsuccessful_expectations']}")

if not results.success:
    print("\nПроваленные проверки:")
    for result in results.results:
        if not result.success:
            col = result.expectation_config.kwargs.get('column', 'таблица')
            print(f"  - {result.expectation_config.expectation_type} (колонка: {col})")
    exit(1)
else:
    print("\nВсе проверки качества данных пройдены!")
    exit(0)
