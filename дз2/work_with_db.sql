-- Создание таблицы пользователей
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    address TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы категорий
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_id INTEGER,
    image_url VARCHAR(255),
    FOREIGN KEY (parent_id) REFERENCES categories(id)
);

-- Создание таблицы товаров
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER NOT NULL,
    image_url VARCHAR(255),
    category_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Создание таблицы заказов
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    user_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_address TEXT NOT NULL,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Создание таблицы элементов заказа
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Создание таблицы корзины
CREATE TABLE cart (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Создание таблицы элементов корзины
CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES cart(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Создание таблицы избранных товаров
CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Добавление пользователей
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, address)
VALUES
('user1', 'user1@example.com', 'hashed_password_1', 'Иван', 'Иванов', '+7 900 123-45-67', 'г. Москва, ул. Ленина, д. 1, кв. 1'),
('user2', 'user2@example.com', 'hashed_password_2', 'Мария', 'Петрова', '+7 911 987-65-43', 'г. Санкт-Петербург, пр. Невский, д. 15'),
('user3', 'user3@example.com', 'hashed_password_3', 'Алексей', 'Сидоров', '+7 922 456-78-90', 'г. Екатеринбург, ул. Мира, д. 5');

-- Добавление категорий
INSERT INTO categories (name, description, parent_id, image_url)
VALUES
('Электроника', 'Электронные устройства и гаджеты', NULL, '/images/electronics.jpg'),
('Смартфоны', 'Мобильные телефоны с сенсорным экраном', 1, '/images/smartphones.jpg'),
('Ноутбуки', 'Портативные компьютеры', 1, '/images/laptops.jpg'),
('Одежда', 'Вещи для мужчин, женщин и детей', NULL, '/images/clothes.jpg'),
('Мужская одежда', 'Одежда для мужчин', 4, '/images/mens_clothes.jpg');

-- Добавление товаров
INSERT INTO products (name, description, price, stock_quantity, image_url, category_id)
VALUES
('iPhone 15', 'Новейший смартфон от Apple', 89990.00, 25, '/images/iphone15.jpg', 2),
('Samsung Galaxy S23', 'Флагманский Android-смартфон', 75990.00, 30, '/images/samsung_s23.jpg', 2),
('MacBook Pro 16"', 'Мощный ноутбук для профессионалов', 199990.00, 10, '/images/macbook_pro.jpg', 3),
('Кожаная куртка', 'Стильная куртка из натуральной кожи', 15990.00, 15, '/images/leather_jacket.jpg', 5);

-- Добавление заказов
INSERT INTO orders (order_number, user_id, status, total_amount, shipping_address, payment_method)
VALUES
('ORD-2025-001', 1, 'Доставлен', 89990.00, 'г. Москва, ул. Ленина, д. 1, кв. 1', 'Кредитная карта'),
('ORD-2025-002', 2, 'В обработке', 215980.00, 'г. Санкт-Петербург, пр. Невский, д. 15', 'PayPal'),
('ORD-2025-003', 3, 'Отправлен', 75990.00, 'г. Екатеринбург, ул. Мира, д. 5', 'Наличными');

-- Добавление элементов заказа
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES
(1, 1, 1, 89990.00),
(2, 1, 1, 89990.00),
(2, 3, 1, 125990.00),
(3, 2, 1, 75990.00);

-- Добавление корзин для пользователей
INSERT INTO cart (user_id)
VALUES
(1),
(2),
(3);

-- Добавление товаров в корзины
INSERT INTO cart_items (cart_id, product_id, quantity)
VALUES
(1, 3, 1),
(2, 4, 2),
(3, 1, 1);

-- Добавление избранных товаров
INSERT INTO favorites (user_id, product_id)
VALUES
(1, 2),
(1, 3),
(2, 1),
(3, 4);
