CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_id INTEGER,
    image_url VARCHAR(255),
    FOREIGN KEY (parent_id) REFERENCES categories(id)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER NOT NULL,
    image_url VARCHAR(255),
    category_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

INSERT INTO categories (name, description, parent_id, image_url)
VALUES
('Электроника', 'Электронные устройства и гаджеты', NULL, '/images/electronics.jpg'),
('Смартфоны', 'Мобильные телефоны с сенсорным экраном', 1, '/images/smartphones.jpg'),
('Ноутбуки', 'Портативные компьютеры', 1, '/images/laptops.jpg'),
('Одежда', 'Вещи для мужчин, женщин и детей', NULL, '/images/clothes.jpg'),
('Мужская одежда', 'Одежда для мужчин', 4, '/images/mens_clothes.jpg');

INSERT INTO products (name, description, price, stock_quantity, image_url, category_id)
VALUES
('iPhone 15', 'Новейший смартфон от Apple', 89990.00, 25, '/images/iphone15.jpg', 2),
('Samsung Galaxy S23', 'Флагманский Android-смартфон', 75990.00, 30, '/images/samsung_s23.jpg', 2),
('MacBook Pro 16"', 'Мощный ноутбук для профессионалов', 199990.00, 10, '/images/macbook_pro.jpg', 3),
('Кожаная куртка', 'Стильная куртка из натуральной кожи', 15990.00, 15, '/images/leather_jacket.jpg', 5);
