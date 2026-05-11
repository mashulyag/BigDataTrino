# Лабораторная работа №4. BigDataTrino

### Выполнила: Глебова Мария Алексеевна М8О-307Б-23

**Задание:** [MAIStudents/BigDataTrino](https://github.com/MAIStudents/BigDataTrino)

Из **10 CSV** первые **пять** загружаются в **ClickHouse** (`bdtrino.mock_data`, **5000** строк), следующие **пять** — в **PostgreSQL** (`mock_data`, **5000** строк). **Trino** объединяет оба источника (каталог `memory`), перекладывает данные в модель **«звезда / снежинка»** в **ClickHouse**.

---

## Что лежит в репозитории


| Путь                              | Содержимое                                                              |
| --------------------------------- | ----------------------------------------------------------------------- |
| `data/`                           | Десять CSV: `MOCK_DATA.csv` и `MOCK_DATA (1).csv` … `MOCK_DATA (9).csv` |
| `docker-compose.yml`              | PostgreSQL, ClickHouse, одноразовый `ch-loader`, Trino                  |
| `postgres/01_mock_ddl.sql`        | Таблица `mock_data` под импорт                                          |
| `postgres/02_load.sql`            | `COPY` пяти файлов `(5)`…`(9)` в PostgreSQL                             |
| `clickhouse/init/`                | БД `bdtrino`, таблица `mock_data`, DDL звезды и витрин                  |
| `clickhouse/manual/01_checks.sql` | Проверки в ClickHouse после ETL                                         |
| `clickhouse/load-mock.sh`         | Ручная загрузка пяти CSV в CH по HTTP (файл в **LF**)                   |
| `trino/catalog/`                  | Каталоги `postgresql`, `clickhouse`, `memory`                           |
| `trino/scripts/01_star.sql`       | Trino: объединение источников → звезда в ClickHouse                     |
| `trino/scripts/02_reports.sql`    | Trino: звезда → шесть таблиц `rpt_*` в ClickHouse                       |
| `scripts/copy_data.ps1`           | Копирование CSV из `..\3\data` или `..\BigDataSpark\data`               |
| `run_etl.ps1`                     | Подряд оба Trino-скрипта                                                |


## Разделение файлов по условию


| Источник   | Файлы                                                      |
| ---------- | ---------------------------------------------------------- |
| ClickHouse | `MOCK_DATA.csv`, `MOCK_DATA (1).csv` … `MOCK_DATA (4).csv` |
| PostgreSQL | `MOCK_DATA (5).csv` … `MOCK_DATA (9).csv`                  |


## Архитектура

`PostgreSQL (5000)` + `ClickHouse mock_data (5000)` → **Trino** (`memory.mock_all` = `UNION ALL`) → **звезда в ClickHouse** → **Trino** → **6 × `rpt_*` в ClickHouse**.

Сервис `**ch-loader`** после старта ClickHouse один раз выполняет `TRUNCATE` и `INSERT … FORMAT CSVWithNames` через `**clickhouse-client**` (порт **9000**); загрузка через HTTP `curl` с `TRUNCATE` на части окружений давала **500**, поэтому в Compose используется native-клиент.

---

## Запуск

Нужны **Docker Desktop** и папка проекта, например `**C:\abd\4`**.

Если в `data/` ещё нет десяти CSV:

```powershell
.\scripts\copy_data.ps1
```

Поднять контейнеры:

```powershell
cd C:\abd\4
docker compose up -d
```

Проверка статуса:

```powershell
docker compose ps
```

Должны быть **healthy**: `bdtrino_pg`, `bdtrino_ch`, `bdtrino_trino`; сервис `ch-loader` — **Completed** (одноразовая загрузка в ClickHouse).

### Запуск Trino-ETL (звезда, затем витрины)

```powershell
.\run_etl.ps1
```

---

## Подключение к PostgreSQL (DBeaver / psql)


| Параметр  | Значение     |
| --------- | ------------ |
| Хост      | `localhost`  |
| Порт      | `5435`       |
| База      | `bdtrino`    |
| Логин     | `bds`        |
| Пароль    | `bds`        |
| Контейнер | `bdtrino_pg` |


Порт **5435** задан в `docker-compose.yml`, чтобы не пересечься с другими лабораторными Postgres.

---

## Подключение к ClickHouse


| Параметр     | Значение     |
| ------------ | ------------ |
| Хост         | `localhost`  |
| HTTP         | `8124`       |
| Native       | `9001`       |
| База         | `bdtrino`    |
| Пользователь | `default`    |
| Пароль       | `bdtrino_ch` |
| Контейнер    | `bdtrino_ch` |


---

## Подключение к Trino


| Параметр         | Значение                                                |
| ---------------- | ------------------------------------------------------- |
| URL (CLI / JDBC) | `http://localhost:8080` / `jdbc:trino://localhost:8080` |
| Каталоги         | `postgresql`, `clickhouse`, `memory`                    |
| Контейнер        | `bdtrino_trino`                                         |


В **DBeaver**: драйвер Trino, JDBC `jdbc:trino://localhost:8080`, при необходимости указать каталог по умолчанию (`clickhouse` или `postgresql`).

---

## Проверка результата

### Количество строк в источниках

```powershell
docker compose exec -T postgres psql -U bds -d bdtrino -c "SELECT COUNT(*) AS mock_data_pg FROM mock_data;"
docker compose exec -T clickhouse clickhouse-client --user default --password bdtrino_ch -q "SELECT count() AS mock_data_ch FROM bdtrino.mock_data"
```

Ожидается **5000** в каждом запросе.

### После `run_etl.ps1` (факт и витрины)

```powershell
docker compose exec -T clickhouse clickhouse-client --user default --password bdtrino_ch -q "SELECT count() FROM bdtrino.fact_sales"
```

Ожидается **10000**.

Сводные проверки ClickHouse:

```powershell
docker compose exec -T clickhouse clickhouse-client --user default --password bdtrino_ch --queries-file /etc/manual/01_checks.sql
```

Шесть витрин: `rpt_sales_by_product`, `rpt_sales_by_customer`, `rpt_sales_by_time`, `rpt_sales_by_store`, `rpt_sales_by_supplier`, `rpt_product_quality`.

---

## Отчёты по условию задания

По [условию](https://github.com/MAIStudents/BigDataTrino) нужно: **ETL в Trino** из **ClickHouse (5 файлов)** и **PostgreSQL (5 файлов)** в **звезду/снежинку в ClickHouse**, затем **шесть отчётов** — **шесть отдельных таблиц** в ClickHouse.

Подпункты в тексте задания (топ-10, топ-5, «корреляция», сравнение периодов и т.д.) — это **цели анализа** на основе витрин. Их проверяют **запросами SQL** к уже построенным таблицам `rpt_*` (в DBeaver к ClickHouse или через `clickhouse-client`), а не отдельными таблицами на каждый подпункт — иначе вместо шести таблиц получилось бы много дублей одной и той же агрегации.


| Тема отчёта из условия        | Таблица в `bdtrino`     |
| ----------------------------- | ----------------------- |
| Витрина продаж по продуктам   | `rpt_sales_by_product`  |
| Витрина продаж по клиентам    | `rpt_sales_by_customer` |
| Витрина продаж по времени     | `rpt_sales_by_time`     |
| Витрина продаж по магазинам   | `rpt_sales_by_store`    |
| Витрина продаж по поставщикам | `rpt_sales_by_supplier` |
| Витрина качества продукции    | `rpt_product_quality`   |


### Какие поля за что отвечают

- `**rpt_sales_by_product`** — выручка, объём продаж, число «заказов» (строк факта по продукту), рейтинг и отзывы на уровне продукта/категории в строке витрины.
- `**rpt_sales_by_customer**` — выручка, число заказов, средний чек, страна клиента.
- `**rpt_sales_by_time**` — строки с `period_type` = `month` или `year`, выручка, число заказов, средний размер заказа за период.
- `**rpt_sales_by_store**` — выручка, заказы, средний чек, город и страна магазина.
- `**rpt_sales_by_supplier**` — выручка, объём в штуках, средняя цена за единицу (`avg_unit_price`), страна поставщика.
- `**rpt_product_quality**` — рейтинг, число отзывов, выручка и объём по продукту (удобно для сравнения «рейтинг vs объём продаж» в одном запросе).

### Примеры SQL в ClickHouse (после `run_etl.ps1`)

Выполнять в **DBeaver** (подключение к `localhost:8124`, БД `bdtrino`) или через CLI:

```sql
-- 1) Топ-10 продуктов по выручке
SELECT product_name, category_name, total_revenue, units_sold
FROM bdtrino.rpt_sales_by_product
ORDER BY total_revenue DESC
LIMIT 10;

-- 2) Общая выручка по категориям продуктов
SELECT category_name, sum(total_revenue) AS revenue_by_category
FROM bdtrino.rpt_sales_by_product
GROUP BY category_name
ORDER BY revenue_by_category DESC;

-- 3) Топ-10 клиентов по сумме покупок
SELECT customer_email, customer_country, total_revenue, order_count, avg_order_value
FROM bdtrino.rpt_sales_by_customer
ORDER BY total_revenue DESC
LIMIT 10;

-- 4) Распределение клиентов по странам (число клиентов в выборке витрины)
SELECT customer_country, count() AS customers_cnt
FROM bdtrino.rpt_sales_by_customer
GROUP BY customer_country
ORDER BY customers_cnt DESC;

-- 5) Топ-5 магазинов по выручке
SELECT store_name, city, country, revenue, order_count, avg_check
FROM bdtrino.rpt_sales_by_store
ORDER BY revenue DESC
LIMIT 5;

-- 6) Топ-5 поставщиков по выручке
SELECT supplier_name, supplier_country, revenue, units_sold, avg_unit_price
FROM bdtrino.rpt_sales_by_supplier
ORDER BY revenue DESC
LIMIT 5;

-- 7) Месячные тренды (и при необходимости сравнить два месяца двумя запросами или подзапросом)
SELECT year_num, month_num, month_name, revenue, order_count, avg_order_value
FROM bdtrino.rpt_sales_by_time
WHERE period_type = 'month'
ORDER BY year_num, month_num;

-- 8) Качество: наибольший / наименьший рейтинг (фрагменты; «корреляция» — отдельный аналитический запрос по двум метрикам)
SELECT product_name, product_rating, review_count, total_revenue, units_sold
FROM bdtrino.rpt_product_quality
ORDER BY product_rating DESC
LIMIT 10;

SELECT product_name, product_rating, review_count, total_revenue, units_sold
FROM bdtrino.rpt_product_quality
WHERE product_rating IS NOT NULL
ORDER BY product_rating ASC
LIMIT 10;

-- 9) Продукты с наибольшим числом отзывов (по полю витрины)
SELECT product_name, review_count, product_rating, total_revenue
FROM bdtrino.rpt_product_quality
ORDER BY review_count DESC
LIMIT 10;
```

Одной командой из PowerShell (пример — только топ-10 продуктов):

```powershell
docker compose exec -T clickhouse clickhouse-client --user default --password bdtrino_ch -q "SELECT product_name, total_revenue FROM bdtrino.rpt_sales_by_product ORDER BY total_revenue DESC LIMIT 10 FORMAT PrettyCompact"
```

---

## Проверка: Trino (кросс-каталог)

```powershell
docker compose exec -T trino trino http://localhost:8080 --execute "SELECT count(*) AS pg FROM postgresql.public.mock_data"
docker compose exec -T trino trino http://localhost:8080 --execute "SELECT count(*) AS ch FROM clickhouse.bdtrino.mock_data"
```

---

## Пересоздать всё с нуля

```powershell
docker compose down -v
docker compose up -d
.\run_etl.ps1
```

`down -v` удаляет том PostgreSQL; при следующем `up` снова выполняются скрипты из `postgres/`. ClickHouse при пустом томе заново применяет `clickhouse/init/` и затем `ch-loader` снова заливает пять CSV.

---

## Остановка

```powershell
docker compose down
```

---

