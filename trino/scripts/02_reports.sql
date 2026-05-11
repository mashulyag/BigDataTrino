-- ЛР4: витрины из звезды (ClickHouse) → 6 отчётных таблиц в ClickHouse через Trino.
-- При INSERT коннектор ожидает bigint для целых ключей и varbinary для String (см. 01_star.sql).

TRUNCATE TABLE clickhouse.bdtrino.rpt_sales_by_product;
TRUNCATE TABLE clickhouse.bdtrino.rpt_sales_by_customer;
TRUNCATE TABLE clickhouse.bdtrino.rpt_sales_by_time;
TRUNCATE TABLE clickhouse.bdtrino.rpt_sales_by_store;
TRUNCATE TABLE clickhouse.bdtrino.rpt_sales_by_supplier;
TRUNCATE TABLE clickhouse.bdtrino.rpt_product_quality;

INSERT INTO clickhouse.bdtrino.rpt_sales_by_product
SELECT
    CAST(p.product_key AS bigint) AS product_key,
    p.product_name,
    c.category_name,
    CAST(sum(CAST(f.total_price AS double)) AS double) AS total_revenue,
    CAST(sum(CAST(f.quantity AS bigint)) AS bigint) AS units_sold,
    CAST(count(*) AS bigint) AS order_count,
    CAST(max(p.product_rating) AS double) AS avg_rating,
    CAST(max(p.product_reviews) AS integer) AS review_count
FROM clickhouse.bdtrino.fact_sales f
INNER JOIN clickhouse.bdtrino.dim_product p ON f.product_key = p.product_key
INNER JOIN clickhouse.bdtrino.dim_product_category c ON p.category_key = c.category_key
GROUP BY p.product_key, p.product_name, c.category_name;

INSERT INTO clickhouse.bdtrino.rpt_sales_by_customer
SELECT
    CAST(c.customer_key AS bigint) AS customer_key,
    c.customer_email,
    c.customer_country,
    CAST(sum(CAST(f.total_price AS double)) AS double) AS total_revenue,
    CAST(count(*) AS bigint) AS order_count,
    CAST(sum(CAST(f.total_price AS double)) / count(*) AS double) AS avg_order_value
FROM clickhouse.bdtrino.fact_sales f
INNER JOIN clickhouse.bdtrino.dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_email, c.customer_country;

INSERT INTO clickhouse.bdtrino.rpt_sales_by_time
SELECT
    period_type,
    year_num,
    month_num,
    month_name,
    revenue,
    order_count,
    avg_order_value
FROM (
    SELECT
        to_utf8('month') AS period_type,
        CAST(dd.year_num AS smallint) AS year_num,
        CAST(dd.month_num AS tinyint) AS month_num,
        to_utf8(trim(from_utf8(dd.month_name))) AS month_name,
        sum(CAST(f.total_price AS double)) AS revenue,
        CAST(count(*) AS bigint) AS order_count,
        sum(CAST(f.total_price AS double)) / count(*) AS avg_order_value
    FROM clickhouse.bdtrino.fact_sales f
    INNER JOIN clickhouse.bdtrino.dim_date dd ON f.date_key = dd.date_key
    GROUP BY dd.year_num, dd.month_num, trim(from_utf8(dd.month_name))

    UNION ALL

    SELECT
        to_utf8('year') AS period_type,
        CAST(dd.year_num AS smallint) AS year_num,
        CAST(0 AS tinyint) AS month_num,
        CAST(NULL AS varbinary) AS month_name,
        sum(CAST(f.total_price AS double)) AS revenue,
        CAST(count(*) AS bigint) AS order_count,
        sum(CAST(f.total_price AS double)) / count(*) AS avg_order_value
    FROM clickhouse.bdtrino.fact_sales f
    INNER JOIN clickhouse.bdtrino.dim_date dd ON f.date_key = dd.date_key
    GROUP BY dd.year_num
) u;

INSERT INTO clickhouse.bdtrino.rpt_sales_by_store
SELECT
    CAST(dst.store_key AS bigint) AS store_key,
    dst.store_name,
    g.city,
    g.country,
    CAST(sum(CAST(f.total_price AS double)) AS double) AS revenue,
    CAST(count(*) AS bigint) AS order_count,
    CAST(sum(CAST(f.total_price AS double)) / count(*) AS double) AS avg_check
FROM clickhouse.bdtrino.fact_sales f
INNER JOIN clickhouse.bdtrino.dim_store dst ON f.store_key = dst.store_key
INNER JOIN clickhouse.bdtrino.dim_geography g ON dst.geo_key = g.geo_key
GROUP BY dst.store_key, dst.store_name, g.city, g.country;

INSERT INTO clickhouse.bdtrino.rpt_sales_by_supplier
SELECT
    CAST(s.supplier_key AS bigint) AS supplier_key,
    s.supplier_name,
    g.country AS supplier_country,
    CAST(sum(CAST(f.total_price AS double)) AS double) AS revenue,
    CAST(sum(CAST(f.quantity AS bigint)) AS bigint) AS units_sold,
    CASE
        WHEN sum(CAST(f.quantity AS double)) = 0 THEN CAST(NULL AS double)
        ELSE sum(CAST(f.total_price AS double)) / sum(CAST(f.quantity AS double))
    END AS avg_unit_price
FROM clickhouse.bdtrino.fact_sales f
INNER JOIN clickhouse.bdtrino.dim_supplier s ON f.supplier_key = s.supplier_key
INNER JOIN clickhouse.bdtrino.dim_geography g ON s.geo_key = g.geo_key
GROUP BY s.supplier_key, s.supplier_name, g.country;

INSERT INTO clickhouse.bdtrino.rpt_product_quality
SELECT
    CAST(p.product_key AS bigint) AS product_key,
    p.product_name,
    CAST(max(p.product_rating) AS double) AS product_rating,
    CAST(max(p.product_reviews) AS integer) AS review_count,
    CAST(sum(CAST(f.total_price AS double)) AS double) AS total_revenue,
    CAST(sum(CAST(f.quantity AS bigint)) AS bigint) AS units_sold
FROM clickhouse.bdtrino.fact_sales f
INNER JOIN clickhouse.bdtrino.dim_product p ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_name;
