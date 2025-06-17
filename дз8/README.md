# Домашнее задание №8 - Redis

## Альтернативное задание

Все задачи решаются, используя Redis-CLI. К каждому заданию прилагается команда в CLI и её вывод.

---

## Списки

### 1. Создание списка `todo:list` и добавление задач

#### Добавление первой задачи в начало списка:
```bash
docker exec -it redis redis-cli LPUSH todo:list "Check homework"
```
**Вывод:** `(integer) 1`

#### Добавление второй задачи в конец списка:
```bash
docker exec -it redis redis-cli RPUSH todo:list "Complete homework"
```
**Вывод:** `(integer) 2`

#### Добавление третьей задачи в конец списка:
```bash
docker exec -it redis redis-cli RPUSH todo:list "Send homework"
```
**Вывод:** `(integer) 3`

### 2. Вывод всего списка задач:
```bash
docker exec -it redis redis-cli LRANGE todo:list 0 -1
```
**Вывод:**
```
1) "Check homework"
2) "Complete homework"
3) "Send homework"
```

### 3. Вывод количества задач в списке:
```bash
docker exec -it redis redis-cli LLEN todo:list
```
**Вывод:** `(integer) 3`

### 4. Извлечение задачи из начала списка (задача выполнена):
```bash
docker exec -it redis redis-cli LPOP todo:list
```
**Вывод:** `"Check homework"`

### 5. Удаление задачи "Send homework" из списка:
```bash
docker exec -it redis redis-cli LREM todo:list 0 "Send homework"
```
**Вывод:** `(integer) 1`

### 6. Проверка, что осталось в списке:
```bash
docker exec -it redis redis-cli LRANGE todo:list 0 -1
```
**Вывод:**
```
1) "Complete homework"
```

---

## Очереди

### 1. Создание списка `message:queue` и добавление сообщений

#### Добавление первого сообщения в конец очереди:
```bash
docker exec -it redis redis-cli RPUSH message:queue "msg1"
```
**Вывод:** `(integer) 1`

#### Добавление второго и третьего сообщений в конец очереди:
```bash
docker exec -it redis redis-cli RPUSH message:queue "msg2" "msg3"
```
**Вывод:** `(integer) 3`

### 2. Извлечение сообщений из начала очереди по одному

#### Извлечение первого сообщения:
```bash
docker exec -it redis redis-cli LPOP message:queue
```
**Вывод:** `"msg1"`

#### Извлечение второго сообщения:
```bash
docker exec -it redis redis-cli LPOP message:queue
```
**Вывод:** `"msg2"`

#### Извлечение третьего сообщения:
```bash
docker exec -it redis redis-cli LPOP message:queue
```
**Вывод:** `"msg3"`

### 3. Проверка, что очередь пуста:
```bash
docker exec -it redis redis-cli LLEN message:queue
```
**Вывод:** `(integer) 0`

---

## Перенос задач из очередей

### 1. Создание двух очередей и добавление задач в `queue:pending`:
```bash
docker exec -it redis redis-cli RPUSH queue:pending "task1" "task2" "task3"
```
**Вывод:** `(integer) 3`

### 2. Перенос задач одну за одной в `queue:processing`

#### Перенос первой задачи:
```bash
docker exec -it redis redis-cli RPOPLPUSH queue:pending queue:processing
```
**Вывод:** `"task3"`

#### Перенос второй задачи:
```bash
docker exec -it redis redis-cli RPOPLPUSH queue:pending queue:processing
```
**Вывод:** `"task2"`

#### Перенос третьей задачи:
```bash
docker exec -it redis redis-cli RPOPLPUSH queue:pending queue:processing
```
**Вывод:** `"task1"`

### 3. Проверка результатов

#### Проверка очереди pending (должна быть пуста):
```bash
docker exec -it redis redis-cli LRANGE queue:pending 0 -1
```
**Вывод:** `(empty array)`

#### Проверка очереди processing (должна содержать все задачи):
```bash
docker exec -it redis redis-cli LRANGE queue:processing 0 -1
```
**Вывод:**
```
1) "task1"
2) "task2"
3) "task3"
```

---

## Заключение

Все задания выполнены успешно:
- ✅ Работа со списками: создание, добавление, извлечение и удаление элементов
- ✅ Работа с очередями: FIFO (first-in, first-out) операции
- ✅ Перенос задач между очередями с использованием атомарной операции RPOPLPUSH

Команда `RPOPLPUSH` особенно полезна для надежного переноса элементов между очередями, поскольку выполняется атомарно и гарантирует, что элемент не будет потерян в случае сбоя.