import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
import os
from datetime import datetime

PG_HOST = '130.193.59.106'
PG_PORT = 5432
PG_USER = 'hduser'
PG_PASSWORD = 'hduser'
PG_DB = 'loyalty_db'
DATA_PATH = 'data'

def load_to_postgres():
    print("=" * 60)
    print("ЗАГРУЗКА ДАННЫХ В POSTGRESQL (loyalty_db)")
    print("=" * 60)
    
    conn = psycopg2.connect(host=PG_HOST, port=PG_PORT, user=PG_USER, password=PG_PASSWORD, dbname=PG_DB)
    cursor = conn.cursor()
    
    # 1. Clients
    print(" Загрузка clients...")
    df = pd.read_csv(os.path.join(DATA_PATH, 'clients.csv'))
    df['birth_date'] = pd.to_datetime(df['birth_date'])
    df['registration_date'] = pd.to_datetime(df['registration_date'])
    df = df.fillna('')
    
    records = [tuple(x) for x in df.to_numpy()]
    execute_values(cursor, """
        INSERT INTO clients (client_id, full_name, gender, birth_date, phone, email, registration_date, city, income_level)
        VALUES %s
        ON CONFLICT (client_id) DO NOTHING
    """, records)
    print(f" Загружено {len(records)} клиентов")
    
    # 2. Cards
    print(" Загрузка cards...")
    df = pd.read_csv(os.path.join(DATA_PATH, 'cards.csv'))
    df['issue_date'] = pd.to_datetime(df['issue_date'])
    df['expiry_date'] = pd.to_datetime(df['expiry_date'])
    
    records = [tuple(x) for x in df.to_numpy()]
    execute_values(cursor, """
        INSERT INTO cards (card_id, client_id, card_number, card_type, issue_date, expiry_date, status, points_balance)
        VALUES %s
        ON CONFLICT (card_id) DO NOTHING
    """, records)
    print(f" Загружено {len(records)} карт")
    
    # 3. Transactions
    print(" Загрузка transactions...")
    df = pd.read_csv(os.path.join(DATA_PATH, 'loyalty_transactions.csv'))
    df['transaction_date'] = pd.to_datetime(df['transaction_date'])
    
    records = [tuple(x) for x in df.to_numpy()]
    execute_values(cursor, """
        INSERT INTO transactions (loyalty_transaction_id, card_id, points, transaction_date, store_id, source_transaction_id, operation_type)
        VALUES %s
        ON CONFLICT (loyalty_transaction_id) DO NOTHING
    """, records)
    print(f" Загружено {len(records)} транзакций")
    
    conn.commit()
    cursor.close()
    conn.close()
    print("\n Все данные успешно загружены в PostgreSQL!")

if __name__ == '__main__':
    load_to_postgres()
