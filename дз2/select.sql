-- Список всех товаров с их категориями
SELECT p.id, p.name AS product_name, p.price, p.stock_quantity,
       c.name AS category_name
FROM products p
JOIN categories c ON p.category_id = c.id
ORDER BY p.id;

-- Запрос 2: Поиск товаров по цене в диапазоне
SELECT name, price, stock_quantity
FROM products
WHERE price BETWEEN 50000.00 AND 100000.00
ORDER BY price ASC;

-- Запрос 3: Информация о заказе с элементами заказа
SELECT o.order_number, o.created_at, o.status,
       u.username, u.email,
       p.name AS product_name, oi.quantity, oi.price,
       o.total_amount
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.id = 2;

-- Запрос 4: Список пользователей и их избранных товаров
SELECT u.username, u.email, p.name AS favorite_product, p.price
FROM users u
JOIN favorites f ON u.id = f.user_id
JOIN products p ON f.product_id = p.id
ORDER BY u.username, p.name;

-- Запрос 5: Товары в корзине пользователя
SELECT u.username, p.name AS product_name, ci.quantity, p.price,
       (p.price * ci.quantity) AS subtotal
FROM users u
JOIN cart c ON u.id = c.user_id
JOIN cart_items ci ON c.id = ci.cart_id
JOIN products p ON ci.product_id = p.id
WHERE u.id = 2;

-- Запрос 6: Статистика по категориям товаров
SELECT c.name AS category_name,
       COUNT(p.id) AS total_products,
       SUM(p.stock_quantity) AS total_stock,
       MIN(p.price) AS min_price,
       MAX(p.price) AS max_price,
       AVG(p.price) AS avg_price
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY total_products DESC;