# Домашнее задание 10 - Проектирование таблиц в Cassandra

## Задание
Разработать схему базы данных в Cassandra для сбора статистики по просмотрам товаров в маркетплейсе. Необходимо спроектировать таблицы так, чтобы они поддерживали эффективное выполнение заданных запросов.

## Требования к данным

Данные для хранения:
- ID просмотренного товара
- ID пользователя, который посмотрел товар
- Время события (в формате "yyyy-MM-dd hh:mm:ss.SSSSSS")
- Тип события (просмотр товара, добавление в корзину)

## Решение

В решении учтен главный принцип проектирования таблиц в Cassandra: **проектируйте таблицы под запросы, а не под модель данных**.

### Созданные таблицы

#### 1. product_events
Таблица оптимизирована для запросов получения последних действий по конкретному товару:
```cql
CREATE TABLE IF NOT EXISTS product_events (
    product_id UUID,
    event_timestamp TIMESTAMP,
    user_id UUID,
    event_type TEXT,
    PRIMARY KEY (product_id, event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000;
```

#### 2. user_events
Таблица оптимизирована для запросов получения последних действий по конкретному пользователю:
```cql
CREATE TABLE IF NOT EXISTS user_events (
    user_id UUID,
    event_timestamp TIMESTAMP,
    product_id UUID,
    event_type TEXT,
    PRIMARY KEY (user_id, event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000;
```

#### 3. product_views_by_date
Таблица оптимизирована для запросов подсчёта событий в заданном временном диапазоне:
```cql
CREATE TABLE IF NOT EXISTS product_views_by_date (
    product_id UUID,
    date TEXT,
    event_timestamp TIMESTAMP,
    user_id UUID,
    event_type TEXT,
    PRIMARY KEY ((product_id, date), event_timestamp)
) WITH CLUSTERING ORDER BY (event_timestamp DESC)
  AND default_time_to_live = 2592000;
```

### Особенности решения

1. **Денормализация данных** - мы создали три отдельные таблицы, содержащие одни и те же данные, но с разными ключами партиционирования и кластеризации для оптимизации под конкретные запросы.

2. **TTL (Time To Live)** - для всех таблиц установлен TTL в 30 дней (2592000 секунд), как требовалось в задании.

3. **Оптимизация кластеризации** - все таблицы используют сортировку по убыванию временной метки (DESC), чтобы самые новые события оказывались первыми при выборке.

4. **Партиционирование по дате** - для запросов по временному интервалу в таблице `product_views_by_date` используется составной ключ партиционирования `(product_id, date)`, что позволяет эффективно выполнять запросы за конкретный день.

### Запросы

1. **Получение 10 последних действий по определённому товару:**
```cql
SELECT * FROM product_events
WHERE product_id = 9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c
LIMIT 10;
```

2. **Получение 10 последних действий по определённому клиенту:**
```cql
SELECT * FROM user_events
WHERE user_id = 5d7c31b6-6c7d-40b9-8957-df3d9f90b3a8
LIMIT 10;
```

3. **Подсчёт просмотров товара в заданном временном интервале:**
```cql
SELECT COUNT(*) FROM product_views_by_date
WHERE product_id = 9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c
AND date = '2025-06-01'
AND event_timestamp >= TIMESTAMP '2025-06-01 10:00:00.000000'
AND event_timestamp <= TIMESTAMP '2025-06-01 13:00:00.000000'
AND event_type = 'view';
```

## Заключение

Данное решение демонстрирует ключевые принципы проектирования в Cassandra:
- Проектирование под запросы, а не под данные
- Использование денормализации для оптимизации чтения
- Эффективное партиционирование и кластеризация
- Правильное определение первичных ключей для поддержки нужных запросов

При такой структуре таблиц все требуемые запросы будут выполняться с высокой эффективностью. 