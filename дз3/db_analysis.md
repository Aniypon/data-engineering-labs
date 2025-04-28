# Анализ базы данных интернет-магазина

## Анализ паттернов чтения и записи

### Таблицы с преобладанием операций чтения

1. **categories**
   - Чтение: Отображение категорий в навигации, фильтрация товаров, построение иерархии категорий
   - Запись: Только административные действия по добавлению/редактированию категорий (редко)
   - Вывод: Преимущественно операции чтения

2. **products**
   - Чтение: Просмотр списков товаров, детальных страниц, поиск, сортировка
   - Запись: Обновление товаров администраторами, изменение количества товаров на складе
   - Вывод: Преимущественно операции чтения, запись происходит реже

3. **users**
   - Чтение: Аутентификация, отображение профиля, информация для заказов
   - Запись: Регистрация новых пользователей, обновление профиля (редко)
   - Вывод: Преимущественно операции чтения

4. **orders** и **order_items**
   - Чтение: История заказов, детали заказа, административные отчеты
   - Запись: Создание новых заказов, обновление статуса
   - Вывод: После создания заказа преобладают операции чтения

### Таблицы с преобладанием операций записи

1. **cart** и **cart_items**
   - Чтение: Отображение содержимого корзины
   - Запись: Добавление/удаление товаров, изменение количества, очистка корзины
   - Вывод: Частые операции записи, высокая изменчивость данных

2. **favorites**
   - Чтение: Отображение избранных товаров пользователя
   - Запись: Добавление/удаление товаров из избранного
   - Вывод: Частые операции как чтения, так и записи

## Основные типы запросов для приложения

### 1. Навигация по категориям и товарам
```sql
-- Получение всех категорий верхнего уровня
SELECT id, name, description, image_url
FROM categories
WHERE parent_id IS NULL
ORDER BY name;

-- Получение подкатегорий для заданной категории
SELECT id, name, description, image_url
FROM categories
WHERE parent_id = :category_id
ORDER BY name;

-- Получение товаров в категории с пагинацией
SELECT p.id, p.name, p.price, p.image_url
FROM products p
WHERE p.category_id = :category_id
ORDER BY p.name
LIMIT 20 OFFSET :offset;
```

### 2. Поиск и фильтрация товаров
```sql
-- Поиск товаров по названию или описанию
SELECT id, name, price, image_url
FROM products
WHERE name ILIKE '%:search_term%' OR description ILIKE '%:search_term%'
ORDER BY name;

-- Фильтрация товаров по цене
SELECT id, name, price, image_url
FROM products
WHERE category_id = :category_id AND price BETWEEN :min_price AND :max_price
ORDER BY price;
```

### 3. Работа с корзиной
```sql
-- Получение содержимого корзины пользователя
SELECT p.id, p.name, p.price, ci.quantity, p.image_url,
       (p.price * ci.quantity) AS subtotal
FROM cart c
JOIN cart_items ci ON c.id = ci.cart_id
JOIN products p ON ci.product_id = p.id
WHERE c.user_id = :user_id;

-- Добавление товара в корзину
INSERT INTO cart_items (cart_id, product_id, quantity)
VALUES (:cart_id, :product_id, :quantity)
ON CONFLICT (cart_id, product_id) 
DO UPDATE SET quantity = cart_items.quantity + :quantity;
```

### 4. Оформление заказа
```sql
-- Создание нового заказа
INSERT INTO orders (order_number, user_id, status, total_amount, shipping_address, payment_method)
VALUES (:order_number, :user_id, 'В обработке', :total_amount, :shipping_address, :payment_method)
RETURNING id;

-- Добавление товаров из корзины в заказ
INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT :order_id, ci.product_id, ci.quantity, p.price
FROM cart_items ci
JOIN products p ON ci.product_id = p.id
WHERE ci.cart_id = :cart_id;
```

### 5. Управление избранными товарами
```sql
-- Получение списка избранных товаров пользователя
SELECT p.id, p.name, p.price, p.image_url
FROM favorites f
JOIN products p ON f.product_id = p.id
WHERE f.user_id = :user_id;

-- Добавление товара в избранное
INSERT INTO favorites (user_id, product_id)
VALUES (:user_id, :product_id)
ON CONFLICT (user_id, product_id) DO NOTHING;
```

### 6. История и детали заказов
```sql
-- Получение истории заказов пользователя
SELECT id, order_number, created_at, status, total_amount
FROM orders
WHERE user_id = :user_id
ORDER BY created_at DESC;

-- Получение деталей конкретного заказа
SELECT p.name, oi.quantity, oi.price, (oi.quantity * oi.price) AS subtotal
FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE oi.order_id = :order_id;
``` 