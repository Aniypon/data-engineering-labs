db = db.getSiblingDB('shop');

db.createCollection('products');
db.createCollection('orders');

db.products.insertMany([
    {
        name: "iPhone 15",
        price: 80000,
        quantity: 10,
        description: "Новый iPhone с чипом A17 Pro",
        category: "Смартфоны"
    },
    {
        name: "Samsung Galaxy S23",
        price: 70000,
        quantity: 15,
        description: "Флагманский смартфон Samsung",
        category: "Смартфоны"
    },
    {
        name: "MacBook Pro 16",
        price: 190000,
        quantity: 5,
        description: "Профессиональный ноутбук для работы",
        category: "Ноутбуки"
    },
    {
        name: "Dell XPS 15",
        price: 120000,
        quantity: 8,
        description: "Мощный ноутбук с высоким разрешением экрана",
        category: "Ноутбуки"
    },
    {
        name: "AirPods Pro",
        price: 20000,
        quantity: 30,
        description: "Беспроводные наушники с шумоподавлением",
        category: "Аудио"
    },
    {
        name: "PlayStation 5",
        price: 60000,
        quantity: 3,
        description: "Игровая консоль нового поколения",
        category: "Игры"
    },
    {
        name: "Xiaomi Robot Vacuum",
        price: 25000,
        quantity: 12,
        description: "Умный робот-пылесос",
        category: "Бытовая техника"
    },
    {
        name: "Apple Watch Series 9",
        price: 35000,
        quantity: 20,
        description: "Смарт-часы с мониторингом здоровья",
        category: "Носимые устройства"
    },
    {
        name: "Распродажный товар",
        price: 1000,
        quantity: 0,
        description: "Товар, который закончился на складе",
        category: "Распродажа"
    }
]);

db.orders.insertMany([
    {
        customer_email: "ivan@mail.ru",
        product_name: "iPhone 15",
        quantity: 2,
        total_price: 160000,
        order_date: new Date("2023-12-15")
    },
    {
        customer_email: "maria@gmail.com",
        product_name: "MacBook Pro 16",
        quantity: 1,
        total_price: 190000,
        order_date: new Date("2023-12-10")
    },
    {
        customer_email: "alex@yandex.ru",
        product_name: "AirPods Pro",
        quantity: 3,
        total_price: 60000,
        order_date: new Date("2023-12-05")
    },
    {
        customer_email: "elena@mail.ru",
        product_name: "Samsung Galaxy S23",
        quantity: 1,
        total_price: 70000,
        order_date: new Date("2023-11-28")
    },
    {
        customer_email: "ivan@mail.ru",
        product_name: "PlayStation 5",
        quantity: 1,
        total_price: 60000,
        order_date: new Date("2023-11-15")
    },
    {
        customer_email: "sergey@gmail.com",
        product_name: "Dell XPS 15",
        quantity: 2,
        total_price: 240000,
        order_date: new Date("2023-11-10")
    },
    {
        customer_email: "anna@yandex.ru",
        product_name: "AirPods Pro",
        quantity: 1,
        total_price: 20000,
        order_date: new Date("2023-10-25")
    },
    {
        customer_email: "maria@gmail.com",
        product_name: "AirPods Pro",
        quantity: 2,
        total_price: 40000,
        order_date: new Date("2023-10-15")
    }
]);

print("Количество товаров: " + db.products.countDocuments());
print("Количество заказов: " + db.orders.countDocuments());

print("\n--- ПРОСТЫЕ ЗАПРОСЫ ---");

print("\n1. Все товары дороже 50000 рублей:");
const expensiveProducts = db.products.find({ price: { $gt: 50000 } }).toArray();
printjson(expensiveProducts);

print("\n2. Обновить цену iPhone 15 на 85000:");
const updateResult = db.products.updateOne(
    { name: "iPhone 15" },
    { $set: { price: 85000 } }
);
printjson(updateResult);
printjson(db.products.findOne({ name: "iPhone 15" }));

print("\n3. Удалить товары с количеством 0:");
const deleteResult = db.products.deleteMany({ quantity: 0 });
printjson(deleteResult);
print("Остаток товаров: " + db.products.countDocuments());

print("\n--- АГРЕГАЦИИ ---");

print("\n1. Средняя цена товаров по категориям:");
const avgPriceByCategory = db.products.aggregate([
    {
        $group: {
            _id: "$category",
            averagePrice: { $avg: "$price" }
        }
    },
    {
        $project: {
            category: "$_id",
            averagePrice: { $round: ["$averagePrice", 2] },
            _id: 0
        }
    },
    { $sort: { averagePrice: -1 } }
]).toArray();
printjson(avgPriceByCategory);

print("\n2. Топ-3 самых дорогих товара с категориями:");
const topExpensiveProducts = db.products.find({}, {
    _id: 0,
    name: 1,
    price: 1,
    category: 1
}).sort({ price: -1 }).limit(3).toArray();
printjson(topExpensiveProducts);

print("\n3. Общая стоимость всех товаров на складе:");
const inventoryValue = db.products.aggregate([
    {
        $group: {
            _id: null,
            totalValue: { $sum: { $multiply: ["$price", "$quantity"] } }
        }
    },
    {
        $project: {
            _id: 0,
            totalValue: 1
        }
    }
]).toArray();
printjson(inventoryValue);

print("\n4. Категории со средней ценой больше 30000 рублей:");
const categoriesWithHighAvgPrice = db.products.aggregate([
    {
        $group: {
            _id: "$category",
            averagePrice: { $avg: "$price" }
        }
    },
    {
        $match: {
            averagePrice: { $gt: 30000 }
        }
    },
    {
        $project: {
            category: "$_id",
            averagePrice: { $round: ["$averagePrice", 2] },
            _id: 0
        }
    },
    { $sort: { averagePrice: -1 } }
]).toArray();
printjson(categoriesWithHighAvgPrice);

print("\n5. Сумма всех заказов:");
const totalOrdersValue = db.orders.aggregate([
    {
        $group: {
            _id: null,
            totalValue: { $sum: "$total_price" }
        }
    },
    {
        $project: {
            _id: 0,
            totalValue: 1
        }
    }
]).toArray();
printjson(totalOrdersValue);

print("\n6. Сумма заказов по клиентам (сортировка по убыванию):");
const ordersByCustomer = db.orders.aggregate([
    {
        $group: {
            _id: "$customer_email",
            totalSpent: { $sum: "$total_price" }
        }
    },
    {
        $project: {
            customer_email: "$_id",
            totalSpent: 1,
            _id: 0
        }
    },
    { $sort: { totalSpent: -1 } }
]).toArray();
printjson(ordersByCustomer);

print("\n7. Топ-3 самых продаваемых товара:");
const bestSellingProducts = db.orders.aggregate([
    {
        $group: {
            _id: "$product_name",
            totalSold: { $sum: "$quantity" }
        }
    },
    {
        $project: {
            product_name: "$_id",
            totalSold: 1,
            _id: 0
        }
    },
    { $sort: { totalSold: -1 } },
    { $limit: 3 }
]).toArray();
printjson(bestSellingProducts); 