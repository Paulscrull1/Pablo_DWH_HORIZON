import os
import json
import pandas as pd
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from clickhouse_driver import Client
import psycopg2

# Настройки подключений через внутреннюю docker-сеть
CH_HOST = 'clickhouse'
CH_PORT = 9000
CH_USER = 'hduser'
CH_PASSWORD = 'hduser'

PG_HOST = 'postgres'
PG_PORT = 5432
PG_USER = 'hduser'
PG_PASSWORD = 'hduser'
PG_DB = 'loyalty_db'

DATA_PATH = '/opt/airflow/data'

def get_ch_client():
    return Client(host=CH_HOST, port=CH_PORT, user=CH_USER, password=CH_PASSWORD)

# ==============================================================================
# ВЕТКА 1: Загрузка справочников и инкрементальных продаж из CSV
# ==============================================================================
def load_csv_data(**context):
    client = get_ch_client()
    ds = context['ds']
    ds_nodash = ds.replace('-', '')
    
    print(f"Загрузка CSV данных для даты: {ds}")
    
    # 1. Справочник магазинов
    df_stores = pd.read_csv(os.path.join(DATA_PATH, 'stores.csv'))
    df_stores['store_id'] = df_stores['store_id'].astype(str)
    df_stores['chain'] = df_stores['chain'].astype(str)
    df_stores['format'] = df_stores['format'].astype(str)
    df_stores['region'] = df_stores['region'].astype(str)
    df_stores['city'] = df_stores['city'].astype(str)
    df_stores['district'] = df_stores['district'].astype(str)
    df_stores['address'] = df_stores['address'].astype(str)
    df_stores['phone'] = df_stores['phone'].astype(str)
    df_stores['opening_year'] = df_stores['opening_year'].astype(int)
    df_stores['area_sqm'] = df_stores['area_sqm'].astype(int)
    
    client.execute("""
        INSERT INTO staging.stg_stores 
        (store_id, chain, format, region, city, district, address, phone, opening_year, area_sqm) 
        VALUES
    """, [tuple(x) for x in df_stores.values.tolist()])
    print(f"  Загружено магазинов: {len(df_stores)}")
    
    # 2. Справочник товаров
    df_products = pd.read_csv(os.path.join(DATA_PATH, 'products.csv'))
    df_products['product_id'] = df_products['product_id'].astype(str)
    df_products['product_name'] = df_products['product_name'].astype(str)
    df_products['category'] = df_products['category'].astype(str)
    df_products['brand'] = df_products['brand'].astype(str)
    df_products['unit_price'] = df_products['unit_price'].astype(float)
    df_products['status'] = df_products['status'].astype(str)
    
    client.execute("""
        INSERT INTO staging.stg_products 
        (product_id, product_name, category, brand, unit_price, status) 
        VALUES
    """, [tuple(x) for x in df_products.values.tolist()])
    print(f"  Загружено товаров: {len(df_products)}")
    
    # 3. Инкрементальные продажи (НАДЕЖНАЯ ОБРАБОТКА Nullable(Int32))
    sales_file = os.path.join(DATA_PATH, f"sales_{ds_nodash}.csv")
    if os.path.exists(sales_file):
        df_sales = pd.read_csv(sales_file)
        df_sales['datetime'] = pd.to_datetime(df_sales['datetime']).dt.to_pydatetime()
        
        # Ручная сборка данных для исключения скрытых преобразований pandas (NaN -> float)
        data_to_insert = []
        for row in df_sales.itertuples(index=False):
            # Явная обработка loyalty_card_id
            if pd.isna(row.loyalty_card_id):
                card_id = None
            else:
                card_id = int(float(row.loyalty_card_id))
                
            data_to_insert.append((
                str(row.transaction_id),
                str(row.product_id),
                float(row.amount),
                float(row.quantity),
                str(row.store_id),
                row.datetime,
                card_id,
                str(row.payment_method)
            ))
        
        # types_check=True гарантирует безопасную упаковку None как NULL
        client.execute("""
            INSERT INTO staging.stg_sales 
            (transaction_id, product_id, amount, quantity, store_id, datetime, loyalty_card_id, payment_method) 
            VALUES
        """, data_to_insert, types_check=True)
        print(f"  Загружено продаж: {len(data_to_insert)}")
    else:
        print(f"  Файл продаж за {ds} не найден")

# ==============================================================================
# ВЕТКА 2: Извлечение данных программы лояльности из PostgreSQL
# ==============================================================================
def extract_from_postgres(**context):
    print("Извлечение данных из PostgreSQL (loyalty_db)")
    
    conn = psycopg2.connect(host=PG_HOST, port=PG_PORT, user=PG_USER, password=PG_PASSWORD, dbname=PG_DB)
    cursor = conn.cursor()
    client = get_ch_client()
    
    # Клиенты
    cursor.execute("SELECT client_id, full_name, gender, birth_date, phone, email, registration_date, city, income_level FROM clients")
    clients = cursor.fetchall()
    client.execute("INSERT INTO staging.stg_clients (client_id, full_name, gender, birth_date, phone, email, registration_date, city, income_level) VALUES", clients)
    print(f"  Загружено клиентов: {len(clients)}")
    
    # Карты
    cursor.execute("SELECT card_id, client_id, card_number, card_type, issue_date, expiry_date, status, points_balance FROM cards")
    cards = cursor.fetchall()
    client.execute("INSERT INTO staging.stg_cards (card_id, client_id, card_number, card_type, issue_date, expiry_date, status, points_balance) VALUES", cards)
    print(f"  Загружено карт: {len(cards)}")
    
    # Транзакции лояльности
    cursor.execute("SELECT loyalty_transaction_id, card_id, points, transaction_date, store_id, source_transaction_id, operation_type FROM transactions")
    txns = cursor.fetchall()
    client.execute("INSERT INTO staging.stg_loyalty_transactions (loyalty_transaction_id, card_id, points, transaction_date, store_id, source_transaction_id, operation_type) VALUES", txns)
    print(f"  Загружено транзакций лояльности: {len(txns)}")
    
    cursor.close()
    conn.close()

# ==============================================================================
# ВЕТКА 3: Загрузка сотрудников из JSON (эмуляция API ERP)
# ==============================================================================
def load_from_json_api(**context):
    print("Загрузка данных из JSON (эмуляция API ERP)")
    
    with open(os.path.join(DATA_PATH, 'hr.json'), 'r', encoding='utf-8') as f:
        employees = json.load(f)
    
    data = []
    for emp in employees:
        hire = datetime.strptime(emp['hire_date'], '%Y-%m-%d').date()
        term = datetime.strptime(emp['termination_date'], '%Y-%m-%d').date() if emp['termination_date'] else None
        data.append((
            int(emp['employee_id']), 
            str(emp['full_name']), 
            str(emp['position']), 
            str(emp['store_id']), 
            hire, 
            term
        ))
    
    client = get_ch_client()
    client.execute("INSERT INTO staging.stg_employees (employee_id, full_name, position, store_id, hire_date, termination_date) VALUES", data)
    print(f"  Загружено сотрудников: {len(data)}")

# ==============================================================================
# ОПРЕДЕЛЕНИЕ DAG
# ==============================================================================
with DAG(
    dag_id='load_staging_data',
    default_args={
        'owner': 'hduser',
        'depends_on_past': False,
        'start_date': datetime(2025, 10, 3),
        'retries': 1,
        'retry_delay': timedelta(minutes=1),
    },
    schedule_interval='@daily',
    catchup=False,
    tags=['pablo_dwh', 'staging', 'elt', 'gx'],
    description='ELT-пайплайн с 3 параллельными ветками и валидацией GX'
) as dag:

    t0_check = PythonOperator(
        task_id='0_check_staging_ready', 
        python_callable=lambda: print("Staging готов к загрузке")
    )
    
    t1_csv = PythonOperator(
        task_id='1a_load_csv_data', 
        python_callable=load_csv_data, 
        provide_context=True
    )
    
    t2_pg = PythonOperator(
        task_id='1b_extract_from_postgres', 
        python_callable=extract_from_postgres
    )
    
    t3_json = PythonOperator(
        task_id='1c_load_from_json_api', 
        python_callable=load_from_json_api
    )
    
    t4_validate = BashOperator(
        task_id='2_validate_staging_with_gx',
        bash_command='python /opt/airflow/dags/validate_staging.py',
    )
    
    # Граф зависимостей: проверка -> 3 ветки параллельно -> валидация GX
    t0_check >> [t1_csv, t2_pg, t3_json] >> t4_validate
