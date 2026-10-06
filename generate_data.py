import pandas as pd
import numpy as np
import json
import uuid
from datetime import datetime, timedelta
import os
import random

NUM_STORES = 50
NUM_PRODUCTS = 3000
NUM_CLIENTS = 10000
TRANSACTIONS_PER_DAY = 1500

OUTPUT_DIR = 'data'
os.makedirs(OUTPUT_DIR, exist_ok=True)

np.random.seed(42)
random.seed(42)

# Генерируем только за 5 дней
start_date = datetime(2026, 10, 1)
NUM_DAYS = 5

print("=" * 60)
print(f"ГЕНЕРАТОР ДАННЫХ (только {NUM_DAYS} дней)")
print("=" * 60)

all_loyalty_txns = []
loyalty_txn_id_counter = 1

# 1. Магазины
regions_data = {'Москва': ['Центральный', 'Северный'], 'Санкт-Петербург': ['Адмиралтейский', 'Василеостровский'], 'Казань': ['Вахитовский', 'Кировский']}
stores = [{'store_id': f'STORE-{i:03d}', 'chain': 'Горизонт', 'format': random.choice(['Супермаркет', 'Гипермаркет']), 'region': random.choice(list(regions_data.keys())), 'city': random.choice(list(regions_data.keys())), 'district': random.choice(regions_data[random.choice(list(regions_data.keys()))]), 'address': f'ул. Ленина, д. {i}', 'phone': f'+7900{i:07d}', 'opening_year': 2020, 'area_sqm': 500} for i in range(1, NUM_STORES + 1)]
pd.DataFrame(stores).to_csv(f'{OUTPUT_DIR}/stores.csv', index=False)

# 2. Товары
categories = ['Молочные продукты', 'Хлеб', 'Мясо', 'Овощи', 'Напитки']
products = [{'product_id': f'SKU-{i:05d}', 'product_name': f'Товар {i}', 'category': random.choice(categories), 'brand': 'БрендА', 'unit_price': round(random.uniform(10, 500), 2), 'status': 'active'} for i in range(1, NUM_PRODUCTS + 1)]
pd.DataFrame(products).to_csv(f'{OUTPUT_DIR}/products.csv', index=False)

# 3. Клиенты и Карты
clients = [{'client_id': i, 'full_name': f'Клиент {i}', 'gender': random.choice(['M', 'F']), 'birth_date': (datetime(1970, 1, 1) + timedelta(days=random.randint(0, 15000))).strftime('%Y-%m-%d'), 'phone': f'+7900000{i:04d}', 'email': f'client{i}@test.com', 'registration_date': '2023-01-01', 'city': 'Москва', 'income_level': 'medium'} for i in range(1, NUM_CLIENTS + 1)]
pd.DataFrame(clients).to_csv(f'{OUTPUT_DIR}/clients.csv', index=False)

cards = []
card_id = 1
for c in clients:
    for _ in range(random.choices([1, 2], weights=[0.8, 0.2])[0]):
        cards.append({'card_id': card_id, 'client_id': c['client_id'], 'card_number': f'CARD-{card_id:06d}', 'card_type': 'classic', 'issue_date': '2023-01-01', 'expiry_date': '2026-01-01', 'status': random.choice(['active', 'active', 'active', 'blocked']), 'points_balance': random.randint(0, 1000)})
        card_id += 1
pd.DataFrame(cards).to_csv(f'{OUTPUT_DIR}/cards.csv', index=False)

# 4. Сотрудники
employees = [{'employee_id': i, 'full_name': f'Сотрудник {i}', 'position': random.choice(['Кассир', 'Продавец', 'Управляющий']), 'store_id': f'STORE-{(i % NUM_STORES) + 1:03d}', 'hire_date': '2022-01-01', 'termination_date': None} for i in range(1, 2000)]
with open(f'{OUTPUT_DIR}/hr.json', 'w', encoding='utf-8') as f:
    json.dump(employees, f, ensure_ascii=False, indent=2)

# 5. Продажи и Лояльность (только за 5 дней)
active_cards = [c['card_id'] for c in cards if c['status'] == 'active']
total_sales = 0

for day_offset in range(NUM_DAYS):
    current_date = start_date + timedelta(days=day_offset)
    date_str = current_date.strftime('%Y%m%d')
    
    daily_sales = []
    num_transactions = int(TRANSACTIONS_PER_DAY * (1.2 if current_date.weekday() >= 5 else 1.0))
    
    for _ in range(num_transactions):
        txn_id = str(uuid.uuid4())
        store = random.choice(stores)
        txn_time = current_date.replace(hour=random.randint(8, 21), minute=random.randint(0, 59), second=random.randint(0, 59))
        
        num_items = random.randint(1, 5)
        for _ in range(num_items):
            product = random.choice(products)
            qty = round(random.uniform(1, 3), 2)
            amount = round(product['unit_price'] * qty * random.choice([1.0, 0.9, 0.8]), 2)
            loyalty_card = random.choice(active_cards) if random.random() < 0.7 else None
            payment = random.choice(['cash', 'card', 'card', 'mobile'])
            
            daily_sales.append({
                'transaction_id': txn_id, 'product_id': product['product_id'], 'amount': amount,
                'quantity': qty, 'store_id': store['store_id'], 'datetime': txn_time.strftime('%Y-%m-%d %H:%M:%S'),
                'loyalty_card_id': loyalty_card, 'payment_method': payment
            })
            
            if loyalty_card:
                points = int(amount / 10)
                op_type = 'accrual' if random.random() > 0.1 else 'writeoff'
                if op_type == 'writeoff': points = -abs(points)
                
                all_loyalty_txns.append({
                    'loyalty_transaction_id': loyalty_txn_id_counter, 'card_id': loyalty_card,
                    'points': points, 'transaction_date': txn_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'store_id': store['store_id'], 'source_transaction_id': txn_id, 'operation_type': op_type
                })
                loyalty_txn_id_counter += 1
                
    pd.DataFrame(daily_sales).to_csv(f'{OUTPUT_DIR}/sales_{date_str}.csv', index=False)
    total_sales += len(daily_sales)

pd.DataFrame(all_loyalty_txns).to_csv(f'{OUTPUT_DIR}/loyalty_transactions.csv', index=False)

print(f"✅ Сгенерировано: {len(stores)} магазинов, {len(products)} товаров, {len(clients)} клиентов, {len(cards)} карт, {len(employees)} сотрудников.")
print(f"✅ Сгенерировано: {total_sales} строк продаж и {len(all_loyalty_txns)} транзакций лояльности за {NUM_DAYS} дней.")
print(f"✅ Файлы продаж: sales_20261001.csv - sales_20261005.csv")
