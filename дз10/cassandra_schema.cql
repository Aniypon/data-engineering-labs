-- Создание keyspace для нашего приложения
CREATE KEYSPACE IF NOT EXISTS marketplace 
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };

USE marketplace;

-- Таблица для запросов по продукту (получение последних действий по продукту)
CREATE TABLE IF NOT EXISTS product_events (
    product_id UUID,
    event_timestamp TIMESTAMP,
    user_id UUID,
    event_type TEXT, -- 'view', 'add_to_cart'
    PRIMARY KEY (product_id, event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000; -- TTL 30 дней (30*24*60*60 секунд)

-- Таблица для запросов по пользователю (получение последних действий пользователя)
CREATE TABLE IF NOT EXISTS user_events (
    user_id UUID,
    event_timestamp TIMESTAMP,
    product_id UUID,
    event_type TEXT, -- 'view', 'add_to_cart'
    PRIMARY KEY (user_id, event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000; -- TTL 30 дней

-- Таблица для запросов по счетчикам просмотров товара по временным интервалам
-- Используем партиционирование по дате для оптимизации запросов по временному интервалу
CREATE TABLE IF NOT EXISTS product_views_by_date (
    product_id UUID,
    date TEXT, -- в формате 'yyyy-MM-dd'
    event_timestamp TIMESTAMP,
    user_id UUID,
    event_type TEXT, -- 'view', 'add_to_cart'
    PRIMARY KEY ((product_id, date), event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000; -- TTL 30 дней 