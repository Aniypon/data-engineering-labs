USE marketplace;

-- INSERT-ы (5 записей)
-- Примечание: в реальном приложении UUID обычно генерируются, но для примера используем конкретные значения
INSERT INTO product_events (product_id, event_timestamp, user_id, event_type)
VALUES (uuid(), TIMESTAMP '2025-06-01 10:15:00.000000', uuid(), 'view');

INSERT INTO product_events (product_id, event_timestamp, user_id, event_type)
VALUES (uuid(), TIMESTAMP '2025-06-01 11:20:00.000000', uuid(), 'add_to_cart');

-- Используем одинаковый product_id для демонстрации
INSERT INTO product_events (product_id, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, TIMESTAMP '2025-06-01 10:30:00.000000', uuid(), 'view');

INSERT INTO product_events (product_id, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, TIMESTAMP '2025-06-01 11:45:00.000000', uuid(), 'add_to_cart');

INSERT INTO product_events (product_id, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, TIMESTAMP '2025-06-01 12:10:00.000000', uuid(), 'view');

-- Те же данные добавляем в таблицу user_events
INSERT INTO user_events (user_id, event_timestamp, product_id, event_type)
VALUES (uuid(), TIMESTAMP '2025-06-01 10:15:00.000000', uuid(), 'view');

INSERT INTO user_events (user_id, event_timestamp, product_id, event_type)
VALUES (uuid(), TIMESTAMP '2025-06-01 11:20:00.000000', uuid(), 'add_to_cart');

-- Используем одинаковый user_id для демонстрации
INSERT INTO user_events (user_id, event_timestamp, product_id, event_type)
VALUES (5d7c31b6-6c7d-40b9-8957-df3d9f90b3a8, TIMESTAMP '2025-06-01 10:30:00.000000', uuid(), 'view');

INSERT INTO user_events (user_id, event_timestamp, product_id, event_type)
VALUES (5d7c31b6-6c7d-40b9-8957-df3d9f90b3a8, TIMESTAMP '2025-06-01 11:45:00.000000', uuid(), 'add_to_cart');

INSERT INTO user_events (user_id, event_timestamp, product_id, event_type)
VALUES (5d7c31b6-6c7d-40b9-8957-df3d9f90b3a8, TIMESTAMP '2025-06-01 12:10:00.000000', uuid(), 'view');

-- Данные для таблицы с временными интервалами
INSERT INTO product_views_by_date (product_id, date, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, '2025-06-01', TIMESTAMP '2025-06-01 10:30:00.000000', uuid(), 'view');

INSERT INTO product_views_by_date (product_id, date, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, '2025-06-01', TIMESTAMP '2025-06-01 11:45:00.000000', uuid(), 'add_to_cart');

INSERT INTO product_views_by_date (product_id, date, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, '2025-06-01', TIMESTAMP '2025-06-01 12:10:00.000000', uuid(), 'view');

INSERT INTO product_views_by_date (product_id, date, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, '2025-06-01', TIMESTAMP '2025-06-01 12:45:00.000000', uuid(), 'view');

INSERT INTO product_views_by_date (product_id, date, event_timestamp, user_id, event_type)
VALUES (9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c, '2025-06-01', TIMESTAMP '2025-06-01 13:20:00.000000', uuid(), 'view');

-- Запрос, возвращающий 10 последних действий по определённому товару
SELECT * FROM product_events
WHERE product_id = 9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c
LIMIT 10;

-- Запрос, возвращающий 10 последних действий по определённому клиенту
SELECT * FROM user_events
WHERE user_id = 5d7c31b6-6c7d-40b9-8957-df3d9f90b3a8
LIMIT 10;

-- Запрос, возвращающий количество просмотров определённого товара в промежуток времени
-- Сначала получаем все записи в интервале, а затем фильтруем и считаем просмотры
SELECT COUNT(*) FROM product_views_by_date
WHERE product_id = 9b3a45e7-2f42-4b54-9390-87cc7d9c1c1c
AND date = '2025-06-01'
AND event_timestamp >= TIMESTAMP '2025-06-01 10:00:00.000000'
AND event_timestamp <= TIMESTAMP '2025-06-01 13:00:00.000000'
AND event_type = 'view'; 