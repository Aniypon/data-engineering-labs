-- ДЗ5: Триггер для автоматического создания партиций при вставке новых записей

-- ФУНКЦИЯ ТРИГГЕРА ДЛЯ АВТОМАТИЧЕСКОГО СОЗДАНИЯ ПАРТИЦИЙ
CREATE OR REPLACE FUNCTION create_partition_if_not_exists()
RETURNS TRIGGER AS $$
DECLARE
    partition_date DATE;
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
    partition_exists BOOLEAN;
BEGIN
    -- Получаем дату из создаваемого заказа
    partition_date := DATE_TRUNC('month', NEW.created_at);
    
    -- Формируем имя партиции
    partition_name := 'orders_' || TO_CHAR(partition_date, 'YYYY_MM');
    
    -- Вычисляем границы партиции (месяц)
    start_date := partition_date;
    end_date := partition_date + INTERVAL '1 month';
    
    -- Проверяем, существует ли уже такая партиция
    SELECT EXISTS(
        SELECT 1 
        FROM pg_inherits i
        JOIN pg_class c ON i.inhrelid = c.oid
        WHERE c.relname = partition_name
    ) INTO partition_exists;
    
    -- Если партиция не существует, создаем её
    IF NOT partition_exists THEN
        RAISE NOTICE 'Создание новой партиции: %', partition_name;
        
        -- Создаем партиции с использованием динамического SQL
        EXECUTE format('
            CREATE TABLE %I PARTITION OF orders
            FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            start_date,
            end_date
        );
        
        -- Создаем индексы для новой партиции
        EXECUTE format('
            CREATE INDEX idx_%I_created_at ON %I (created_at)',
            partition_name,
            partition_name
        );
        
        EXECUTE format('
            CREATE INDEX idx_%I_user_id ON %I (user_id)',
            partition_name,
            partition_name
        );
        
        EXECUTE format('
            CREATE INDEX idx_%I_status ON %I (status)',
            partition_name,
            partition_name
        );
        
        RAISE NOTICE 'Партиция % успешно создана с индексами', partition_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- СОЗДАНИЕ ТРИГГЕРА НА ВСТАВКУ
DROP TRIGGER IF EXISTS trigger_auto_create_partition ON orders;

CREATE TRIGGER trigger_auto_create_partition
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION create_partition_if_not_exists();

-- ДОПОЛНИТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ ЗАРАНЕЕ
CREATE OR REPLACE FUNCTION create_partitions_for_period(
    start_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    start_month INTEGER DEFAULT EXTRACT(MONTH FROM CURRENT_DATE),
    num_months INTEGER DEFAULT 12
) 
RETURNS TEXT AS $$
DECLARE
    current_date DATE;
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
    i INTEGER := 0;
    result_message TEXT := '';
BEGIN
    current_date := DATE_TRUNC('month', DATE(start_year || '-' || start_month || '-01'));
    
    WHILE i < num_months LOOP
        partition_name := 'orders_' || TO_CHAR(current_date, 'YYYY_MM');
        start_date := current_date;
        end_date := current_date + INTERVAL '1 month';
        
        -- Проверяем, существует ли партиция
        IF NOT EXISTS(
            SELECT 1 
            FROM pg_inherits i
            JOIN pg_class c ON i.inhrelid = c.oid
            WHERE c.relname = partition_name
        ) THEN
            -- Создаем партицию
            EXECUTE format('
                CREATE TABLE %I PARTITION OF orders
                FOR VALUES FROM (%L) TO (%L)',
                partition_name,
                start_date,
                end_date
            );
            
            -- Создаем индексы
            EXECUTE format('
                CREATE INDEX idx_%I_created_at ON %I (created_at)',
                partition_name,
                partition_name
            );
            
            EXECUTE format('
                CREATE INDEX idx_%I_user_id ON %I (user_id)',
                partition_name,
                partition_name
            );
            
            EXECUTE format('
                CREATE INDEX idx_%I_status ON %I (status)',
                partition_name,
                partition_name
            );
            
            result_message := result_message || 'Создана партиция: ' || partition_name || E'\n';
        ELSE
            result_message := result_message || 'Партиция уже существует: ' || partition_name || E'\n';
        END IF;
        
        current_date := current_date + INTERVAL '1 month';
        i := i + 1;
    END LOOP;
    
    RETURN result_message;
END;
$$ LANGUAGE plpgsql;

-- ФУНКЦИЯ ДЛЯ ОЧИСТКИ СТАРЫХ ПАРТИЦИЙ
CREATE OR REPLACE FUNCTION drop_old_partitions(months_to_keep INTEGER DEFAULT 24)
RETURNS TEXT AS $$
DECLARE
    partition_record RECORD;
    cutoff_date DATE;
    result_message TEXT := '';
BEGIN
    cutoff_date := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month' * months_to_keep);
    
    FOR partition_record IN
        SELECT 
            schemaname,
            tablename,
            SUBSTRING(tablename FROM 'orders_(\d{4}_\d{2})') as date_part
        FROM pg_tables 
        WHERE tablename LIKE 'orders_____%%'
        AND schemaname = 'public'
    LOOP
        -- Проверяем, является ли партиция старой
        IF TO_DATE(partition_record.date_part, 'YYYY_MM') < cutoff_date THEN
            EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', partition_record.tablename);
            result_message := result_message || 'Удалена старая партиция: ' || partition_record.tablename || E'\n';
        END IF;
    END LOOP;
    
    IF result_message = '' THEN
        result_message := 'Нет старых партиций для удаления';
    END IF;
    
    RETURN result_message;
END;
$$ LANGUAGE plpgsql;

-- ДЕМОНСТРАЦИЯ РАБОТЫ ТРИГГЕРА
-- Создадим несколько партиций заранее для тестирования
SELECT create_partitions_for_period(2025, 1, 6);
