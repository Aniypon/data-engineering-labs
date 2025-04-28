-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ PRODUCTS ==========

-- B-Tree индекс по полю category_id, так как это частый критерий фильтрации при просмотре товаров по категориям
-- Используется в JOIN и WHERE условиях
CREATE INDEX idx_products_category_id ON products USING btree(category_id);

-- B-Tree индекс по полю price для ускорения сортировки и фильтрации по ценовому диапазону
-- Подходит для операторов сравнения (<, >, BETWEEN)
CREATE INDEX idx_products_price ON products USING btree(price);

-- GIN индекс для полнотекстового поиска по name и description
-- Важно для функциональности поиска товаров по названию или описанию
CREATE INDEX idx_products_fulltext ON products USING gin(to_tsvector('russian', name || ' ' || description));
COMMENT ON INDEX idx_products_fulltext IS 'Индекс для полнотекстового поиска по названию и описанию товаров';

-- Не создаем индекс по stock_quantity, так как:
-- 1. Редко используется для поиска/фильтрации
-- 2. Часто обновляется при операциях с заказами
-- 3. Добавление индекса замедлит операции обновления количества товаров


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ USERS ==========

-- B-Tree индекс по email для быстрой аутентификации пользователей
-- Часто используется в WHERE условиях при входе в систему
CREATE INDEX idx_users_email ON users USING btree(email);

-- B-Tree индекс по username для быстрого поиска пользователей
-- Используется при аутентификации и поиске пользователей
CREATE INDEX idx_users_username ON users USING btree(username);

-- Не создаем составной индекс по first_name и last_name, так как:
-- 1. Поиск по имени и фамилии выполняется редко
-- 2. При необходимости можно добавить позже, если аналитика покажет частое использование


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ ORDERS ==========

-- B-Tree индекс по user_id для быстрого получения истории заказов пользователя
-- Частый сценарий использования - просмотр заказов в личном кабинете
CREATE INDEX idx_orders_user_id ON orders USING btree(user_id);

-- B-Tree индекс по created_at для ускорения сортировки заказов по дате
-- Используется в ORDER BY для истории заказов
CREATE INDEX idx_orders_created_at ON orders USING btree(created_at);

-- B-Tree индекс по order_number для быстрого поиска заказа по его номеру
-- Используется при отслеживании заказа, в службе поддержки
CREATE INDEX idx_orders_order_number ON orders USING btree(order_number);

-- Не создаем индекс по status, так как:
-- 1. Низкая кардинальность (мало уникальных значений)
-- 2. Неэффективно при частых фильтрациях по статусу


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ ORDER_ITEMS ==========

-- B-Tree индекс по order_id для быстрого получения состава заказа
-- Используется при просмотре деталей заказа
CREATE INDEX idx_order_items_order_id ON order_items USING btree(order_id);

-- B-Tree индекс по product_id для анализа продаж по товарам
-- Используется в аналитических запросах для отчетов
CREATE INDEX idx_order_items_product_id ON order_items USING btree(product_id);

-- Не создаем составной индекс (order_id, product_id), так как:
-- 1. В одном заказе обычно не повторяются одни и те же товары
-- 2. Первичный индекс уже обеспечивает уникальность


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ CART_ITEMS ==========

-- B-Tree индекс по cart_id для быстрого получения содержимого корзины
-- Используется при отображении корзины пользователя
CREATE INDEX idx_cart_items_cart_id ON cart_items USING btree(cart_id);

-- Уникальный составной индекс по cart_id и product_id
-- Предотвращает дублирование товаров в корзине и ускоряет операции UPDATE
CREATE UNIQUE INDEX idx_cart_items_cart_product ON cart_items USING btree(cart_id, product_id);

-- Не создаем индекс по quantity, так как:
-- 1. Не используется для поиска или сортировки
-- 2. Часто обновляется при изменении количества товаров в корзине


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ FAVORITES ==========

-- B-Tree индекс по user_id для быстрого получения избранных товаров пользователя
-- Используется при отображении списка избранного
CREATE INDEX idx_favorites_user_id ON favorites USING btree(user_id);

-- Уникальный составной индекс по user_id и product_id
-- Предотвращает дублирование товаров в избранном и ускоряет операции поиска и удаления
CREATE UNIQUE INDEX idx_favorites_user_product ON favorites USING btree(user_id, product_id);

-- Не создаем индекс по added_at, так как:
-- 1. Редко используется для сортировки избранных товаров
-- 2. Добавление лишнего индекса увеличит размер таблицы


-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ CATEGORIES ==========

-- B-Tree индекс по parent_id для построения дерева категорий
-- Используется при навигации по иерархии категорий
CREATE INDEX idx_categories_parent_id ON categories USING btree(parent_id);

-- Не создаем индекс по name, так как:
-- 1. Таблица категорий обычно небольшая
-- 2. Полное сканирование будет эффективнее использования индекса
-- 3. Операции поиска по имени категории выполняются редко

-- ========== ИНДЕКСЫ ДЛЯ ТАБЛИЦЫ CART ==========

-- B-Tree индекс по user_id для быстрого получения корзины пользователя
-- Важно для быстрого доступа к корзине конкретного пользователя
CREATE INDEX idx_cart_user_id ON cart USING btree(user_id);

-- Не создаем индекс по created_at/updated_at, так как:
-- 1. Редко используются для поиска или сортировки
-- 2. Дополнительный индекс увеличит нагрузку при обновлении корзины 