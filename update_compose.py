
"""
Скрипт для обновления docker-compose.yml на основе .env файла
"""
import re
from dotenv import load_dotenv
import os

# Загружаем переменные из .env
load_dotenv()

HOST_IP = os.getenv("HOST_IP")
CH_PORT_HTTP = os.getenv("CH_PORT_HTTP", "8123")
CH_PORT_NATIVE = os.getenv("CH_PORT_NATIVE", "9000")
PG_PORT = os.getenv("PG_PORT", "5432")
AIRFLOW_PORT = os.getenv("AIRFLOW_PORT", "8080")

if not HOST_IP:
    print(" Ошибка: HOST_IP не найден в .env файле")
    exit(1)

print(f" Читаем конфигурацию из .env:")
print(f"   HOST_IP: {HOST_IP}")
print(f"   ClickHouse: {CH_PORT_HTTP}, {CH_PORT_NATIVE}")
print(f"   PostgreSQL: {PG_PORT}")
print(f"   Airflow: {AIRFLOW_PORT}")

# Читаем текущий docker-compose.yml
with open('docker-compose.yml', 'r') as f:
    content = f.read()

# Заменяем порты с явным указанием IP
# Формат: "IP:PORT:PORT" или просто "PORT:PORT"
content = re.sub(
    r'- "\d+\.\d+\.\d+\.\d+:(\d+):\1"',  # Старый формат с IP
    f'- "{HOST_IP}:\\1:\\1"',
    content
)

content = re.sub(
    r'- "(\d+):\1"',  # Старый формат без IP
    f'- "{HOST_IP}:\\1:\\1"',
    content
)

# Записываем обратно
with open('docker-compose.yml', 'w') as f:
    f.write(content)

print(f"\n docker-compose.yml обновлен с IP {HOST_IP}")
print(f"\n Теперь выполните: docker compose down && docker compose up -d")

