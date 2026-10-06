from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from clickhouse_driver import Client
import os

def test_clickhouse():
    client = Client(
        host=os.getenv('CH_HOST', 'clickhouse'),
        port=int(os.getenv('CH_PORT', 9000)),
        user=os.getenv('CH_USER', 'hduser'),
        password=os.getenv('CH_PASSWORD', 'hduser')
    )
    result = client.execute('SELECT version()')
    print(f"✅ ClickHouse version: {result[0][0]}")

with DAG(
    dag_id='test_connection',
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False
) as dag:
    
    task = PythonOperator(
        task_id='test_ch',
        python_callable=test_clickhouse
    )
