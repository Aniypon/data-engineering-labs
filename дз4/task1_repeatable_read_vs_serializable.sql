
-- Подготовка тестовой таблицы
DROP TABLE IF EXISTS test_products;
CREATE TABLE test_products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER NOT NULL
);

-- Заполнение тестовыми данными
INSERT INTO test_products (name, price, stock_quantity) VALUES
    ('Смартфон', 29990.00, 10),
    ('Наушники', 5990.00, 20),
    ('Планшет', 19990.00, 5);

-- СЦЕНАРИЙ 1: Фантомное чтение (phantom read) - REPEATABLE READ vs SERIALIZABLE

-- Терминал 1: Начинаем транзакцию с уровнем изоляции REPEATABLE READ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Терминал 1: Выполняем запрос, который ищет товары дешевле 10000
SELECT * FROM test_products WHERE price < 10000;
-- Результат: Мы видим только "Наушники" с price = 5990.00

-- Терминал 2: В другой сессии добавляем новый товар в диапазон запроса
BEGIN;
INSERT INTO test_products (name, price, stock_quantity) VALUES ('Чехол', 999.00, 50);
COMMIT;

-- Терминал 1: Повторяем запрос в той же транзакции
SELECT * FROM test_products WHERE price < 10000;
-- Результат: С REPEATABLE READ мы все равно видим только "Наушники"
-- (запрос дает тот же результат, несмотря на вставку нового товара)

-- Терминал 1: Теперь попробуем вставить товар с похожими характеристиками
INSERT INTO test_products (name, price, stock_quantity) VALUES ('Зарядное устройство', 1500.00, 30);
-- Результат: Вставка выполнится успешно на REPEATABLE READ

COMMIT;

-- Повторим тот же сценарий, но с SERIALIZABLE

-- Сначала сбросим таблицу до предыдущего состояния
DELETE FROM test_products WHERE name IN ('Чехол', 'Зарядное устройство');

-- Терминал 1: Начинаем транзакцию с уровнем изоляции SERIALIZABLE
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Терминал 1: Выполняем запрос, который ищет товары дешевле 10000
SELECT * FROM test_products WHERE price < 10000;
-- Результат: Мы видим только "Наушники" с price = 5990.00

-- Терминал 2: В другой сессии добавляем новый товар в диапазон запроса
BEGIN;
INSERT INTO test_products (name, price, stock_quantity) VALUES ('Чехол', 999.00, 50);
COMMIT;

-- Терминал 1: Повторяем запрос в той же транзакции
SELECT * FROM test_products WHERE price < 10000;
-- Результат: С SERIALIZABLE мы тоже видим только "Наушники"
-- (так же как и с REPEATABLE READ)

-- Терминал 1: Теперь попробуем вставить товар с похожими характеристиками
INSERT INTO test_products (name, price, stock_quantity) VALUES ('Зарядное устройство', 1500.00, 30);
-- Результат: На SERIALIZABLE эта операция вызовет ошибку сериализации:
-- ERROR:  could not serialize access due to read/write dependencies among transactions
-- Это отличие от REPEATABLE READ, где вставка выполнилась успешно

ROLLBACK; -- или COMMIT, но после ошибки транзакция всё равно будет отменена

-- СЦЕНАРИЙ 2: Аномалия записи-чтения-записи (write-skew) - REPEATABLE READ vs SERIALIZABLE

-- Предположим, у нас есть правило, что сумма quantity всех товаров должна быть не менее 30

-- Терминал 1: Начинаем транзакцию с уровнем изоляции REPEATABLE READ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Терминал 1: Проверяем общее количество товаров
SELECT SUM(stock_quantity) FROM test_products;
-- Результат: Сумма = 35 (10 + 20 + 5)

-- Терминал 1: Уменьшаем количество первого товара на 15 (останется 35 - 15 = 20, что < 30)
UPDATE test_products SET stock_quantity = stock_quantity - 15 WHERE id = 1;

-- Терминал 2: Параллельно в другой сессии с REPEATABLE READ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Терминал 2: Также проверяем общее количество товаров
SELECT SUM(stock_quantity) FROM test_products;
-- Результат: Сумма = 35 (транзакция 1 еще не завершена)

-- Терминал 2: Уменьшаем количество второго товара на 10 (останется 35 - 10 = 25, что < 30)
UPDATE test_products SET stock_quantity = stock_quantity - 10 WHERE id = 2;

-- Терминал 1: Завершаем первую транзакцию
COMMIT;

-- Терминал 2: Завершаем вторую транзакцию
COMMIT;

-- После выполнения обеих транзакций проверяем сумму
SELECT SUM(stock_quantity) FROM test_products;
-- Результат: Сумма = 10 (было 35, стало 35 - 15 - 10 = 10)
-- Это нарушает наше правило о минимальной сумме 30!
-- REPEATABLE READ не предотвратил эту аномалию

-- Сбросим данные обратно
UPDATE test_products SET stock_quantity = 10 WHERE id = 1;
UPDATE test_products SET stock_quantity = 20 WHERE id = 2;
UPDATE test_products SET stock_quantity = 5 WHERE id = 3;

-- Повторим тот же сценарий, но с SERIALIZABLE

-- Терминал 1: Начинаем транзакцию с уровнем изоляции SERIALIZABLE
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Терминал 1: Проверяем общее количество товаров
SELECT SUM(stock_quantity) FROM test_products;
-- Результат: Сумма = 35

-- Терминал 1: Уменьшаем количество первого товара на 15
UPDATE test_products SET stock_quantity = stock_quantity - 15 WHERE id = 1;

-- Терминал 2: Параллельно в другой сессии с SERIALIZABLE
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Терминал 2: Также проверяем общее количество товаров
SELECT SUM(stock_quantity) FROM test_products;
-- Результат: Сумма = 35 (транзакция 1 еще не завершена)

-- Терминал 2: Уменьшаем количество второго товара на 10
UPDATE test_products SET stock_quantity = stock_quantity - 10 WHERE id = 2;

-- Терминал 1: Завершаем первую транзакцию
COMMIT;

-- Терминал 2: Пытаемся завершить вторую транзакцию
COMMIT;
-- Результат: Вторая транзакция завершится с ошибкой:
-- ERROR: could not serialize access due to read/write dependencies among transactions
-- SERIALIZABLE предотвратил аномалию write-skew, и бизнес-правило сохранено

-- КРАТКИЙ ИТОГ СРАВНЕНИЯ REPEATABLE READ И SERIALIZABLE

/*
1. REPEATABLE READ предотвращает:
   - Грязное чтение (dirty read)
   - Неповторяющееся чтение (non-repeatable read)
   Но допускает:
   - Некоторые фантомные аномалии
   - Аномалии write-skew

2. SERIALIZABLE предотвращает все аномалии, включая:
   - Грязное чтение (dirty read)
   - Неповторяющееся чтение (non-repeatable read)
   - Фантомное чтение (phantom read)
   - Аномалии write-skew
   
3. Основные различия:
   - REPEATABLE READ обычно имеет более высокую производительность, так как меньше блокирует
   - SERIALIZABLE обеспечивает полную изоляцию, но может приводить к сериализационным ошибкам,
     требующим повторного выполнения транзакций
   - SERIALIZABLE в PostgreSQL использует механизм Serializable Snapshot Isolation (SSI),
     который обнаруживает и предотвращает аномалии, а не просто блокирует операции

4. Выбор уровня изоляции:
   - REPEATABLE READ подходит для большинства приложений, где нет строгих требований к сериализации
   - SERIALIZABLE необходим, когда критически важна согласованность данных и бизнес-правил,
     особенно в распределенных транзакциях
*/ 