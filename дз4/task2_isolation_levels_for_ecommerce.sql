-- ЗАДАЧА 2: Выбор уровней изоляции для сценариев интернет-магазина

-- Пересоздаем основные таблицы нашего интернет-магазина
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS cart;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- Создание основных таблиц (упрощенная версия из ДЗ2)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE cart (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (cart_id) REFERENCES cart(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Заполнение тестовыми данными
INSERT INTO users (username, email) VALUES
    ('user1', 'user1@example.com'),
    ('user2', 'user2@example.com');

INSERT INTO categories (name) VALUES
    ('Электроника'),
    ('Одежда');

INSERT INTO products (name, description, price, stock_quantity, category_id) VALUES
    ('Смартфон', 'Новейшая модель', 29990.00, 10, 1),
    ('Наушники', 'Беспроводные', 5990.00, 20, 1),
    ('Футболка', 'Хлопок, размер L', 1590.00, 50, 2),
    ('Джинсы', 'Классические, синие', 3990.00, 30, 2);

-- Создаем корзины для пользователей
INSERT INTO cart (user_id) VALUES (1), (2);

-- Добавляем товары в корзины
INSERT INTO cart_items (cart_id, product_id, quantity) VALUES
    (1, 1, 1),  -- Корзина user1: 1 смартфон
    (1, 2, 2),  -- Корзина user1: 2 наушников
    (2, 3, 3),  -- Корзина user2: 3 футболки
    (2, 4, 1);  -- Корзина user2: 1 джинсы

-- СЦЕНАРИЙ 1: Получение товаров с пагинацией

/*
Вопрос: Может ли "скакать" пагинация, если другой пользователь будет удалять/добавлять товары?

Ответ: Да, при уровне изоляции READ COMMITTED пагинация может "скакать", если другие 
пользователи удаляют или добавляют товары между запросами страниц.

Например, если мы получим первую страницу с товарами 1-10, а затем добавятся новые 
товары в начало списка или удалятся существующие, то при запросе второй страницы мы
можем либо пропустить какие-то товары, либо увидеть их повторно.

Какой уровень изоляции нужен?

Минимально необходимый уровень: REPEATABLE READ

Обоснование:
- READ UNCOMMITTED и READ COMMITTED не подходят, так как они допускают изменение 
  результатов между запросами в рамках одной логической операции пагинации
- REPEATABLE READ гарантирует стабильный снимок данных на время всей транзакции
- SERIALIZABLE не нужен, так как нам не требуется предотвращать фантомные записи
  при пагинации - мы только хотим стабильный набор данных
*/

-- Демонстрация проблемы при использовании READ COMMITTED
-- Терминал 1: Получаем первую страницу товаров (2 первых товара в категории Электроника)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT * FROM products 
WHERE category_id = 1 
ORDER BY id 
LIMIT 2 OFFSET 0;
-- Результат: получаем Смартфон и Наушники

-- Терминал 2: Добавляем новый товар в начало списка (с меньшим id, если пересортировать)
BEGIN;
INSERT INTO products (name, description, price, stock_quantity, category_id)
VALUES ('Планшет', 'Новая модель', 15990.00, 5, 1);
COMMIT;

-- Терминал 1: Получаем вторую страницу (следующие 2 товара)
SELECT * FROM products 
WHERE category_id = 1 
ORDER BY id 
LIMIT 2 OFFSET 2;
-- Проблема: на второй странице нет товаров, так как их всего 3,
-- но первые 2 мы уже видели, а новый 'Планшет' попал бы на первую страницу,
-- если бы мы запросили её снова. Произошел "скачок" пагинации.

COMMIT;

-- Демонстрация решения с REPEATABLE READ
-- Терминал 1: Получаем первую страницу товаров
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT * FROM products 
WHERE category_id = 1 
ORDER BY id 
LIMIT 2 OFFSET 0;
-- Результат: получаем те же товары (не видим новый 'Планшет')

-- Терминал 2: Добавляем еще один товар
BEGIN;
INSERT INTO products (name, description, price, stock_quantity, category_id)
VALUES ('Колонка', 'Беспроводная', 3990.00, 15, 1);
COMMIT;

-- Терминал 1: Получаем вторую страницу
SELECT * FROM products 
WHERE category_id = 1 
ORDER BY id 
LIMIT 2 OFFSET 2;
-- Результат: Пагинация не "скачет", так как мы видим согласованный снимок данных

COMMIT;

-- СЦЕНАРИЙ 2: Получение содержимого корзины и его итоговой суммы

/*
Вопрос: Другой пользователь одновременно с этим может изменить цену какого-то товара
из корзины. Какой уровень изоляции минимально необходим?

Ответ: Для получения согласованного представления корзины с корректным расчетом 
итоговой суммы нужен уровень изоляции, который гарантирует, что цены товаров 
не изменятся во время выполнения запроса.

Минимально необходимый уровень: REPEATABLE READ

Обоснование:
- READ UNCOMMITTED и READ COMMITTED могут привести к тому, что мы увидим разные цены
  для одних и тех же товаров в рамках одного логического запроса корзины
- REPEATABLE READ гарантирует, что мы увидим цены такими, какими они были на момент
  начала транзакции
- SERIALIZABLE избыточен, так как нам нужно только гарантировать неизменность 
  данных при чтении, но не требуется защита от параллельной модификации
*/

-- Демонстрация проблемы при READ COMMITTED
-- Терминал 1: Получаем содержимое корзины пользователя 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Получаем товары в корзине
SELECT p.id, p.name, p.price, ci.quantity
FROM cart_items ci
JOIN products p ON ci.product_id = p.id
WHERE ci.cart_id = 1;

-- Терминал 2: Администратор меняет цену товара
BEGIN;
UPDATE products SET price = 27990.00 WHERE id = 1; -- Снижаем цену на смартфон
COMMIT;

-- Терминал 1: Рассчитываем итоговую сумму
SELECT SUM(p.price * ci.quantity) AS total_amount
FROM cart_items ci
JOIN products p ON ci.product_id = p.id
WHERE ci.cart_id = 1;
-- Проблема: Итоговая сумма не соответствует ценам, которые мы показали пользователю,
-- так как цена на смартфон изменилась между запросами

COMMIT;

-- Демонстрация решения с REPEATABLE READ
-- Терминал 1: Получаем содержимое корзины пользователя 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Получаем товары в корзине
SELECT p.id, p.name, p.price, ci.quantity
FROM cart_items ci
JOIN products p ON ci.product_id = p.id
WHERE ci.cart_id = 1;

-- Терминал 2: Администратор меняет цену товара
BEGIN;
UPDATE products SET price = 25990.00 WHERE id = 1; -- Снижаем цену на смартфон еще сильнее
COMMIT;

-- Терминал 1: Рассчитываем итоговую сумму
SELECT SUM(p.price * ci.quantity) AS total_amount
FROM cart_items ci
JOIN products p ON ci.product_id = p.id
WHERE ci.cart_id = 1;
-- Результат: Итоговая сумма корректна и соответствует ценам, которые мы показали пользователю

COMMIT;

-- СЦЕНАРИЙ 3: Проверка наличия товара перед оформлением заказа

/*
Вопрос: Два пользователя одновременно заказывают один и тот же товар, хотя в наличии
всего одна штука. Какой уровень изоляции предотвратит overselling?

Ответ: Для предотвращения overselling (продажи товаров больше, чем есть на самом деле)
нужен уровень изоляции, который защищает от параллельных изменений количества товара.

Минимально необходимый уровень: SERIALIZABLE

Обоснование:
- READ UNCOMMITTED и READ COMMITTED не предотвращают проблему, так как транзакции 
  могут одновременно проверить наличие товара и создать заказ
- REPEATABLE READ может привести к аномалии write-skew, когда обе транзакции видят
  достаточное количество товара, но вместе создают заказы на больше товаров, чем есть
- SERIALIZABLE гарантирует, что конфликтующие транзакции будут выполнены так, 
  будто они шли последовательно, что предотвратит overselling
*/

-- Сначала установим количество товара в 1 штуку
UPDATE products SET stock_quantity = 1 WHERE id = 1;

-- Демонстрация проблемы с REPEATABLE READ
-- Терминал 1: Пользователь 1 проверяет наличие и создает заказ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Проверяем наличие товара (Смартфон, id=1)
SELECT id, name, stock_quantity FROM products WHERE id = 1;
-- Результат: stock_quantity = 1, товар в наличии

-- Терминал 2: Пользователь 2 также проверяет наличие и создает заказ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Проверяем наличие товара
SELECT id, name, stock_quantity FROM products WHERE id = 1;
-- Результат: stock_quantity = 1, товар в наличии (транзакция 1 еще не завершена)

-- Терминал 1: Пользователь 1 создает заказ
-- Создаем заказ
INSERT INTO orders (user_id, status, total_amount)
VALUES (1, 'Оформлен', 29990.00)
RETURNING id;
-- Предположим, что вернулся id = 1

-- Добавляем товар в заказ
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (1, 1, 1, 29990.00);

-- Обновляем количество товара
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE id = 1;

COMMIT;

-- Терминал 2: Пользователь 2 также создает заказ
-- Создаем заказ
INSERT INTO orders (user_id, status, total_amount)
VALUES (2, 'Оформлен', 29990.00)
RETURNING id;
-- Предположим, что вернулся id = 2

-- Добавляем товар в заказ
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (2, 1, 1, 29990.00);

-- Обновляем количество товара
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE id = 1;
-- На REPEATABLE READ это выполнится успешно, что приведет к отрицательному количеству товара!

COMMIT;

-- Проверяем результат
SELECT id, name, stock_quantity FROM products WHERE id = 1;
-- Результат: stock_quantity = -1 (произошел overselling!)

-- Демонстрация решения с SERIALIZABLE
-- Сначала вернем товар в наличие
UPDATE products SET stock_quantity = 1 WHERE id = 1;

-- Терминал 1: Пользователь 1 проверяет наличие и создает заказ
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Проверяем наличие товара
SELECT id, name, stock_quantity FROM products WHERE id = 1;
-- Результат: stock_quantity = 1, товар в наличии

-- Терминал 2: Пользователь 2 также проверяет наличие и создает заказ
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Проверяем наличие товара
SELECT id, name, stock_quantity FROM products WHERE id = 1;
-- Результат: stock_quantity = 1, товар в наличии (транзакция 1 еще не завершена)

-- Терминал 1: Пользователь 1 создает заказ
-- Создаем заказ
INSERT INTO orders (user_id, status, total_amount)
VALUES (1, 'Оформлен', 29990.00)
RETURNING id;
-- Предположим, что вернулся id = 3

-- Добавляем товар в заказ
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (3, 1, 1, 29990.00);

-- Обновляем количество товара
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE id = 1;

COMMIT;

-- Терминал 2: Пользователь 2 также пытается создать заказ
-- Создаем заказ
INSERT INTO orders (user_id, status, total_amount)
VALUES (2, 'Оформлен', 29990.00)
RETURNING id;
-- Предположим, что вернулся id = 4

-- Добавляем товар в заказ
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (4, 1, 1, 29990.00);

-- Обновляем количество товара
UPDATE products SET stock_quantity = stock_quantity - 1 WHERE id = 1;

COMMIT;
-- Результат: Вторая транзакция завершится с ошибкой:
-- ERROR: could not serialize access due to read/write dependencies among transactions
-- SERIALIZABLE предотвратил overselling!

-- СЦЕНАРИЙ 4: Агрегирование данных (например, общее количество товаров в категории)


/*
Вопрос: Вы делаете SELECT COUNT(*) по фильтру. Одновременно с этим другой пользователь
удаляет/добавляет товары в категорию. Какой уровень изоляции даст вам точный,
воспроизводимый результат?

Ответ: Для получения точного и воспроизводимого результата агрегации нужен уровень
изоляции, который гарантирует стабильный набор данных.

Минимально необходимый уровень: REPEATABLE READ

Обоснование:
- READ UNCOMMITTED и READ COMMITTED не подходят, так как могут давать разные результаты
  при повторном выполнении агрегации в рамках одной транзакции
- REPEATABLE READ гарантирует, что набор строк не изменится в процессе выполнения транзакции
- SERIALIZABLE избыточен, так как нам достаточно согласованного снимка данных,
  и не требуется защита от параллельных изменений
*/

-- Демонстрация проблемы на READ COMMITTED
-- Терминал 1: Запрашиваем агрегированные данные
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Считаем количество товаров в категории "Электроника"
SELECT COUNT(*) FROM products WHERE category_id = 1;
-- Например, получаем результат 4

-- Терминал 2: Добавляем новый товар
BEGIN;
INSERT INTO products (name, description, price, stock_quantity, category_id)
VALUES ('Телевизор', 'Smart TV', 49990.00, 3, 1);
COMMIT;

-- Терминал 1: Повторно запрашиваем агрегированные данные
SELECT COUNT(*) FROM products WHERE category_id = 1;
-- Получаем результат 5, что не согласуется с предыдущим запросом
-- Это может привести к некорректным расчетам при многоступенчатых отчетах

-- Терминал 1: Считаем среднюю цену товаров
SELECT AVG(price) FROM products WHERE category_id = 1;
-- Результат учитывает новый товар, что не согласуется с первым запросом COUNT(*)

COMMIT;

-- Демонстрация решения с REPEATABLE READ
-- Терминал 1: Запрашиваем агрегированные данные
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Считаем количество товаров в категории "Электроника"
SELECT COUNT(*) FROM products WHERE category_id = 1;
-- Получаем результат (например, 5)

-- Терминал 2: Добавляем новый товар
BEGIN;
INSERT INTO products (name, description, price, stock_quantity, category_id)
VALUES ('Фотоаппарат', 'Цифровой', 35990.00, 2, 1);
COMMIT;

-- Терминал 1: Повторно запрашиваем агрегированные данные
SELECT COUNT(*) FROM products WHERE category_id = 1;
-- Получаем тот же результат 5, что согласуется с предыдущим запросом

-- Терминал 1: Считаем среднюю цену товаров
SELECT AVG(price) FROM products WHERE category_id = 1;
-- Результат согласован с первым запросом COUNT(*) и не учитывает новый товар

COMMIT;

-- ИТОГОВАЯ СВОДКА ПО МИНИМАЛЬНО НЕОБХОДИМЫМ УРОВНЯМ ИЗОЛЯЦИИ

/*
1. Получение товаров с пагинацией:
   Минимально необходимый уровень: REPEATABLE READ
   Причина: Предотвращает "скачки" пагинации из-за изменений данных другими пользователями.

2. Получение содержимого корзины и его итоговой суммы:
   Минимально необходимый уровень: REPEATABLE READ
   Причина: Гарантирует согласованность цен товаров на протяжении всего процесса
   отображения корзины и расчета общей суммы.

3. Проверка наличия товара перед оформлением заказа:
   Минимально необходимый уровень: SERIALIZABLE
   Причина: Только этот уровень гарантированно предотвращает overselling при
   одновременном оформлении заказов разными пользователями.

4. Агрегирование данных:
   Минимально необходимый уровень: REPEATABLE READ
   Причина: Обеспечивает точный и воспроизводимый результат агрегации даже при
   параллельных изменениях данных.
*/ 