
db = db.getSiblingDB('shop');

// === ПРОСТЫЕ ЗАПРОСЫ ===

// 1. Найти все товары дороже 50000 рублей
db.products.find({ price: { $gt: 50000 } });

// 2. Обновить цену товара по названию
db.products.updateOne(
    { name: "iPhone 15" },
    { $set: { price: 85000 } }
);
db.products.findOne({ name: "iPhone 15" });

// 3. Удалить товар с количеством 0
db.products.deleteMany({ quantity: 0 });
db.products.countDocuments();

// === АГРЕГАЦИИ ===

// 1. Подсчет средней цены товаров в каждой категории
db.products.aggregate([
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
]);

// 2. Топ-3 самых дорогих товара с их категориями
db.products.find({}, {
    _id: 0,
    name: 1,
    price: 1,
    category: 1
}).sort({ price: -1 }).limit(3);

// 3. Общая стоимость всех товаров на складе (цена × количество)
db.products.aggregate([
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
]);

// 4. Категории, где средняя цена товаров больше 30000 рублей
db.products.aggregate([
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
]);

// 5. Сумма всех заказов
db.orders.aggregate([
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
]);

// 6. Сумма всех заказов по customer_email с сортировкой по убыванию общей суммы
db.orders.aggregate([
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
]);

// 7. Топ-3 самых продаваемых товара
db.orders.aggregate([
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
]); 