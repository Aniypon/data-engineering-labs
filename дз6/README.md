# Домашнее задание 6: Spring Boot приложение для интернет-магазина

## Описание проекта

Spring Boot REST API приложение для управления данными интернет-магазина с использованием PostgreSQL базы данных.

## Функциональность

### Реализованные возможности:
1. **Создание товаров** - POST `/api/products`
2. **Редактирование полей товара** - PUT `/api/products/{id}`
3. **Создание категорий** - POST `/api/categories`
4. **Привязка товара к категории** - PUT `/api/products/{productId}/category/{categoryId}`
5. **Получение всех товаров с категориями** - GET `/api/products/with-categories` (JOIN запрос)

### Технологический стек:
- **Java 23**
- **Spring Boot 3.3.6**
- **PostgreSQL 15**
- **Spring Data JPA**
- **Swagger/OpenAPI 3**
- **Docker & Docker Compose**

## Архитектура приложения

```
src/main/java/com/example/schemka/
├── entity/          # JPA сущности
│   ├── Category.java
│   └── Product.java
├── dto/             # Data Transfer Objects
│   ├── CategoryCreateRequest.java
│   ├── ProductCreateRequest.java
│   ├── ProductUpdateRequest.java
│   └── ProductWithCategoryResponse.java
├── repository/      # JPA репозитории
│   ├── CategoryRepository.java
│   └── ProductRepository.java
├── service/         # Бизнес-логика
│   ├── CategoryService.java
│   └── ProductService.java
└── controller/      # REST контроллеры
    ├── CategoryController.java
    └── ProductController.java
```

## Запуск приложения

### Через Docker Compose (рекомендуется):

```bash
cd дз6
docker-compose up --build
```

### Локально:

1. Запустить PostgreSQL:
```bash
docker-compose up postgres -d
```

2. Запустить приложение:
```bash
cd schemka
./gradlew bootRun
```

## API Documentation

После запуска приложения документация Swagger доступна по адресу:
http://localhost:8888/swagger-ui/index.html

## Примеры API запросов

### 1. Создание категории:
```bash
curl -X POST http://localhost:8888/api/categories \
  -H "Content-Type: application/json" \
  -d '{"name": "Электроника", "description": "Электронные устройства"}'
```

### 2. Создание товара:
```bash
curl -X POST http://localhost:8888/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "iPhone 15", "description": "Новый смартфон", "price": 99999.99, "stockQuantity": 10, "categoryId": 1}'
```

### 3. Редактирование товара:
```bash
curl -X PUT http://localhost:8888/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "iPhone 15 Pro", "price": 109999.99}'
```

### 4. Привязка товара к категории:
```bash
curl -X PUT http://localhost:8888/api/products/1/category/2
```

### 5. Получение товаров с категориями:
```bash
curl -X GET http://localhost:8888/api/products/with-categories
```

## База данных

Приложение автоматически создает схему базы данных и заполняет её тестовыми данными при первом запуске.

### Структура таблиц:
- `categories` - категории товаров
- `products` - товары с привязкой к категориям

## Особенности реализации

1. **JPA аннотации** для маппинга сущностей на таблицы БД
2. **Двунаправленные связи** между Product и Category
3. **Custom JPQL запрос** для получения товаров с категориями
4. **Swagger аннотации** для автоматической генерации документации
5. **Environment variables** для конфигурации БД в Docker
6. **Многоэтапная сборка Docker** для оптимизации размера образа

## Требования к системе

- Java 23+
- Docker & Docker Compose
- 4GB свободной RAM для контейнеров
