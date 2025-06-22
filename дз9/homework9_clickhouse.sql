-- Домашнее задание 9: Работа с ClickHouse ReplacingMergeTree и переносом партиций
-- 
-- Требования:
-- 1. Создать две таблицы с ReplacingMergeTree (events_main и events_archive)
-- 2. Заполнить данными минимум в 3 разные партиции с дубликатами
-- 3. Перенести партиции между таблицами
-- 4. Написать проверочные запросы

-- =============================================================================
-- 1. СОЗДАНИЕ ТАБЛИЦ
-- =============================================================================

-- Создаем основную таблицу events_main с ReplacingMergeTree
CREATE TABLE IF NOT EXISTS events_main (
    event_id UInt64,
    user_id UInt32,
    event_time DateTime,
    event_type Enum8('page_view' = 1, 'click' = 2, 'purchase' = 3, 'logout' = 4),
    page_url String,
    country String
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMMDDhhmmss(event_time)  -- Партиционирование по минутам
ORDER BY (user_id, event_id);  -- Ключ сортировки для определения дубликатов

-- Создаем архивную таблицу events_archive с аналогичной структурой
CREATE TABLE IF NOT EXISTS events_archive (
    event_id UInt64,
    user_id UInt32,
    event_time DateTime,
    event_type Enum8('page_view' = 1, 'click' = 2, 'purchase' = 3, 'logout' = 4),
    page_url String,
    country String
) ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMMDDhhmmss(event_time)  -- Партиционирование по минутам
ORDER BY (user_id, event_id);  -- Ключ сортировки для определения дубликатов

-- =============================================================================
-- 2. ЗАПОЛНЕНИЕ ДАННЫМИ (минимум 3 партиции + дубликаты)
-- =============================================================================

-- Вставляем данные в разные партиции (разные минуты)
INSERT INTO events_main VALUES
-- Партиция 1: 14:30:xx
(1, 1001, '2024-06-01 14:30:15', 'page_view', '/home', 'Russia'),
(2, 1002, '2024-06-01 14:30:45', 'click', '/products', 'USA'),

-- Партиция 2: 14:31:xx  
(3, 1003, '2024-06-01 14:31:20', 'page_view', '/about', 'Germany'),
(4, 1001, '2024-06-01 14:31:50', 'purchase', '/checkout', 'Russia'),

-- Партиция 3: 14:32:xx
(5, 1004, '2024-06-01 14:32:10', 'page_view', '/contact', 'France'),
(6, 1002, '2024-06-01 14:32:30', 'logout', '/logout', 'USA');

-- Добавляем дубликаты для демонстрации ReplacingMergeTree
-- Дубликат записи с event_id=1, user_id=1001 (новая версия)
INSERT INTO events_main VALUES
(1, 1001, '2024-06-01 14:30:15', 'page_view', '/home-updated', 'Russia');

-- Дубликат записи с event_id=3, user_id=1003 (новая версия)
INSERT INTO events_main VALUES
(3, 1003, '2024-06-01 14:31:20', 'page_view', '/about-updated', 'Germany');

-- =============================================================================
-- 3. ПРОВЕРОЧНЫЕ ЗАПРОСЫ ДО ПЕРЕНОСА
-- =============================================================================

-- Просмотр созданных партиций в основной таблице
SELECT 
    partition,
    name,
    rows,
    bytes_on_disk,
    modification_time
FROM system.parts
WHERE table = 'events_main' 
  AND database = currentDatabase()
  AND active = 1
ORDER BY partition;

-- Просмотр всех данных с дубликатами (без FINAL)
SELECT 'Данные С дубликатами:' as info;
SELECT * FROM events_main ORDER BY event_time, event_id;

-- Просмотр данных без дубликатов (с FINAL)
SELECT 'Данные БЕЗ дубликатов (FINAL):' as info;
SELECT * FROM events_main FINAL ORDER BY event_time;

-- Количество записей в основной таблице
SELECT 'Количество записей в events_main:' as info, count() as total_rows FROM events_main;

-- =============================================================================
-- 4. ПЕРЕНОС ПАРТИЦИЙ
-- =============================================================================

-- Копируем первую партицию (14:30:xx) в архивную таблицу
ALTER TABLE events_archive ATTACH PARTITION 20240601143015 FROM events_main;

-- Удаляем скопированную партицию из основной таблицы
ALTER TABLE events_main DROP PARTITION 20240601143015;

-- Копируем вторую партицию (14:31:xx) в архивную таблицу  
ALTER TABLE events_archive ATTACH PARTITION 20240601143120 FROM events_main;

-- Удаляем скопированную партицию из основной таблицы
ALTER TABLE events_main DROP PARTITION 20240601143120;

-- =============================================================================
-- 5. ПРОВЕРОЧНЫЕ ЗАПРОСЫ ПОСЛЕ ПЕРЕНОСА
-- =============================================================================

-- Проверяем партиции в основной таблице после переноса
SELECT 'Партиции в events_main после переноса:' as info;
SELECT 
    partition,
    name,
    rows,
    bytes_on_disk
FROM system.parts
WHERE table = 'events_main' 
  AND database = currentDatabase()
  AND active = 1
ORDER BY partition;

-- Проверяем партиции в архивной таблице после переноса
SELECT 'Партиции в events_archive после переноса:' as info;
SELECT 
    partition,
    name,
    rows,
    bytes_on_disk
FROM system.parts
WHERE table = 'events_archive' 
  AND database = currentDatabase()
  AND active = 1
ORDER BY partition;

-- Проверяем количество записей в каждой таблице
SELECT 'Количество записей в events_main после переноса:' as info, count() as total_rows FROM events_main;
SELECT 'Количество записей в events_archive после переноса:' as info, count() as total_rows FROM events_archive;

-- Проверяем данные в основной таблице (должна остаться только партиция 14:32:xx)
SELECT 'Данные в events_main после переноса:' as info;
SELECT * FROM events_main FINAL ORDER BY event_time;

-- Проверяем данные в архивной таблице (должны быть партиции 14:30:xx и 14:31:xx)
SELECT 'Данные в events_archive после переноса:' as info;
SELECT * FROM events_archive FINAL ORDER BY event_time;

-- =============================================================================
-- 6. ДОПОЛНИТЕЛЬНЫЕ ПРОВЕРКИ
-- =============================================================================

-- Проверяем работу ReplacingMergeTree в архивной таблице
-- Принудительное слияние для применения дедупликации
OPTIMIZE TABLE events_archive;

-- Финальная проверка данных без дубликатов
SELECT 'Финальные данные в events_archive без дубликатов:' as info;
SELECT * FROM events_archive FINAL ORDER BY event_time;

-- Статистика по событиям в архиве
SELECT 
    'Статистика по событиям в архиве:' as info,
    event_type,
    count() as event_count,
    uniq(user_id) as unique_users
FROM events_archive FINAL
GROUP BY event_type
ORDER BY event_count DESC; 