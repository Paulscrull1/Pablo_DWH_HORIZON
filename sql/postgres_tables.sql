CREATE TABLE IF NOT EXISTS clients (
    client_id INTEGER PRIMARY KEY,
    full_name VARCHAR(255),
    gender VARCHAR(10),
    birth_date DATE,
    phone VARCHAR(20),
    email VARCHAR(255),
    registration_date DATE,
    city VARCHAR(100),
    income_level VARCHAR(50)
);

-- Таблица карт лояльности
CREATE TABLE IF NOT EXISTS cards (
    card_id INTEGER PRIMARY KEY,
    client_id INTEGER REFERENCES clients(client_id),
    card_number VARCHAR(50),
    card_type VARCHAR(20),
    issue_date DATE,
    expiry_date DATE,
    status VARCHAR(20),
    points_balance INTEGER
);

-- Таблица транзакций лояльности
CREATE TABLE IF NOT EXISTS transactions (
    loyalty_transaction_id INTEGER PRIMARY KEY,
    card_id INTEGER REFERENCES cards(card_id),
    points INTEGER,
    transaction_date TIMESTAMP,
    store_id VARCHAR(50),
    source_transaction_id VARCHAR(100),
    operation_type VARCHAR(20)
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_cards_client ON cards(client_id);
CREATE INDEX IF NOT EXISTS idx_txn_card ON transactions(card_id);
CREATE INDEX IF NOT EXISTS idx_txn_date ON transactions(transaction_date);
