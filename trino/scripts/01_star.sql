-- ЛР4: объединение mock_data (PG + CH) в памяти Trino → схема звезды в ClickHouse.
-- Запуск: docker compose exec -T trino trino http://localhost:8080 -f /etc/trino/scripts/01_star.sql

DROP TABLE IF EXISTS memory.default.mock_all;

-- Коннектор Trino → ClickHouse отдаёт String как varbinary; в PG mock_data — varchar.
-- CAST(varbinary AS varchar) в Trino запрещён — используем from_utf8().
CREATE TABLE memory.default.mock_all AS
SELECT * FROM postgresql.public.mock_data
UNION ALL
SELECT
    from_utf8(id) AS id,
    from_utf8(customer_first_name) AS customer_first_name,
    from_utf8(customer_last_name) AS customer_last_name,
    from_utf8(customer_age) AS customer_age,
    from_utf8(customer_email) AS customer_email,
    from_utf8(customer_country) AS customer_country,
    from_utf8(customer_postal_code) AS customer_postal_code,
    from_utf8(customer_pet_type) AS customer_pet_type,
    from_utf8(customer_pet_name) AS customer_pet_name,
    from_utf8(customer_pet_breed) AS customer_pet_breed,
    from_utf8(seller_first_name) AS seller_first_name,
    from_utf8(seller_last_name) AS seller_last_name,
    from_utf8(seller_email) AS seller_email,
    from_utf8(seller_country) AS seller_country,
    from_utf8(seller_postal_code) AS seller_postal_code,
    from_utf8(product_name) AS product_name,
    from_utf8(product_category) AS product_category,
    from_utf8(product_price) AS product_price,
    from_utf8(product_quantity) AS product_quantity,
    from_utf8(sale_date) AS sale_date,
    from_utf8(sale_customer_id) AS sale_customer_id,
    from_utf8(sale_seller_id) AS sale_seller_id,
    from_utf8(sale_product_id) AS sale_product_id,
    from_utf8(sale_quantity) AS sale_quantity,
    from_utf8(sale_total_price) AS sale_total_price,
    from_utf8(store_name) AS store_name,
    from_utf8(store_location) AS store_location,
    from_utf8(store_city) AS store_city,
    from_utf8(store_state) AS store_state,
    from_utf8(store_country) AS store_country,
    from_utf8(store_phone) AS store_phone,
    from_utf8(store_email) AS store_email,
    from_utf8(pet_category) AS pet_category,
    from_utf8(product_weight) AS product_weight,
    from_utf8(product_color) AS product_color,
    from_utf8(product_size) AS product_size,
    from_utf8(product_brand) AS product_brand,
    from_utf8(product_material) AS product_material,
    from_utf8(product_description) AS product_description,
    from_utf8(product_rating) AS product_rating,
    from_utf8(product_reviews) AS product_reviews,
    from_utf8(product_release_date) AS product_release_date,
    from_utf8(product_expiry_date) AS product_expiry_date,
    from_utf8(supplier_name) AS supplier_name,
    from_utf8(supplier_contact) AS supplier_contact,
    from_utf8(supplier_email) AS supplier_email,
    from_utf8(supplier_phone) AS supplier_phone,
    from_utf8(supplier_address) AS supplier_address,
    from_utf8(supplier_city) AS supplier_city,
    from_utf8(supplier_country) AS supplier_country
FROM clickhouse.bdtrino.mock_data;

TRUNCATE TABLE clickhouse.bdtrino.fact_sales;
TRUNCATE TABLE clickhouse.bdtrino.dim_store;
TRUNCATE TABLE clickhouse.bdtrino.dim_supplier;
TRUNCATE TABLE clickhouse.bdtrino.dim_product;
TRUNCATE TABLE clickhouse.bdtrino.dim_seller;
TRUNCATE TABLE clickhouse.bdtrino.dim_customer;
TRUNCATE TABLE clickhouse.bdtrino.dim_date;
TRUNCATE TABLE clickhouse.bdtrino.dim_geography;
TRUNCATE TABLE clickhouse.bdtrino.dim_product_category;

INSERT INTO clickhouse.bdtrino.dim_geography
SELECT
    CAST(row_number() OVER (ORDER BY city, state_region, country) AS bigint) AS geo_key,
    to_utf8(city) AS city,
    to_utf8(state_region) AS state_region,
    to_utf8(country) AS country
FROM (
    SELECT DISTINCT
        store_city AS city,
        coalesce(nullif(trim(store_state), ''), '') AS state_region,
        store_country AS country
    FROM memory.default.mock_all
    UNION
    SELECT DISTINCT
        supplier_city AS city,
        '' AS state_region,
        supplier_country AS country
    FROM memory.default.mock_all
) g;

INSERT INTO clickhouse.bdtrino.dim_product_category
SELECT
    CAST(row_number() OVER (ORDER BY category_name) AS bigint) AS category_key,
    to_utf8(category_name) AS category_name
FROM (
    SELECT DISTINCT product_category AS category_name
    FROM memory.default.mock_all
    WHERE nullif(trim(product_category), '') IS NOT NULL
) c;

INSERT INTO clickhouse.bdtrino.dim_customer
SELECT
    CAST(row_number() OVER (ORDER BY customer_email) AS bigint) AS customer_key,
    to_utf8(customer_email) AS customer_email,
    to_utf8(customer_first_name) AS customer_first_name,
    to_utf8(customer_last_name) AS customer_last_name,
    try_cast(nullif(trim(customer_age), '') AS integer) AS customer_age,
    to_utf8(nullif(trim(customer_country), '')) AS customer_country,
    to_utf8(nullif(trim(customer_postal_code), '')) AS customer_postal_code,
    to_utf8(nullif(trim(customer_pet_type), '')) AS customer_pet_type,
    to_utf8(nullif(trim(customer_pet_name), '')) AS customer_pet_name,
    to_utf8(nullif(trim(customer_pet_breed), '')) AS customer_pet_breed
FROM (
    SELECT
        *,
        row_number() OVER (PARTITION BY customer_email ORDER BY id) AS rn
    FROM memory.default.mock_all
) s
WHERE s.rn = 1;

INSERT INTO clickhouse.bdtrino.dim_seller
SELECT
    CAST(row_number() OVER (ORDER BY seller_email) AS bigint) AS seller_key,
    to_utf8(seller_email) AS seller_email,
    to_utf8(seller_first_name) AS seller_first_name,
    to_utf8(seller_last_name) AS seller_last_name,
    to_utf8(nullif(trim(seller_country), '')) AS seller_country,
    to_utf8(nullif(trim(seller_postal_code), '')) AS seller_postal_code
FROM (
    SELECT
        *,
        row_number() OVER (PARTITION BY seller_email ORDER BY id) AS rn
    FROM memory.default.mock_all
) s
WHERE s.rn = 1;

INSERT INTO clickhouse.bdtrino.dim_store
SELECT
    CAST(row_number() OVER (ORDER BY s.store_hash) AS bigint) AS store_key,
    to_utf8(s.store_hash) AS store_hash,
    to_utf8(s.store_name) AS store_name,
    to_utf8(s.store_location) AS store_location,
    to_utf8(s.store_phone) AS store_phone,
    to_utf8(s.store_email) AS store_email,
    CAST(g.geo_key AS bigint) AS geo_key
FROM (
    SELECT DISTINCT
        lower(to_hex(md5(to_utf8(concat_ws('|',
            coalesce(store_name, ''),
            coalesce(nullif(trim(store_location), ''), ''),
            coalesce(store_city, ''),
            coalesce(nullif(trim(store_state), ''), ''),
            coalesce(store_country, ''),
            coalesce(nullif(trim(store_phone), ''), ''),
            coalesce(nullif(trim(store_email), ''), '')
        ))))) AS store_hash,
        store_name,
        store_location,
        store_phone,
        store_email,
        store_city,
        coalesce(nullif(trim(store_state), ''), '') AS state_region,
        store_country
    FROM memory.default.mock_all
) s
INNER JOIN clickhouse.bdtrino.dim_geography g
    ON s.store_city = from_utf8(g.city)
   AND s.state_region = from_utf8(g.state_region)
   AND s.store_country = from_utf8(g.country);

INSERT INTO clickhouse.bdtrino.dim_supplier
SELECT
    CAST(row_number() OVER (ORDER BY s.supplier_hash) AS bigint) AS supplier_key,
    to_utf8(s.supplier_hash) AS supplier_hash,
    to_utf8(s.supplier_name) AS supplier_name,
    to_utf8(s.supplier_contact) AS supplier_contact,
    to_utf8(s.supplier_email) AS supplier_email,
    to_utf8(s.supplier_phone) AS supplier_phone,
    to_utf8(s.supplier_address) AS supplier_address,
    CAST(g.geo_key AS bigint) AS geo_key
FROM (
    SELECT DISTINCT
        lower(to_hex(md5(to_utf8(concat_ws('|',
            coalesce(nullif(trim(supplier_name), ''), ''),
            coalesce(nullif(trim(supplier_contact), ''), ''),
            coalesce(nullif(trim(supplier_email), ''), ''),
            coalesce(nullif(trim(supplier_phone), ''), ''),
            coalesce(nullif(trim(supplier_address), ''), ''),
            coalesce(supplier_city, ''),
            coalesce(supplier_country, '')
        ))))) AS supplier_hash,
        nullif(trim(supplier_name), '') AS supplier_name,
        nullif(trim(supplier_contact), '') AS supplier_contact,
        nullif(trim(supplier_email), '') AS supplier_email,
        nullif(trim(supplier_phone), '') AS supplier_phone,
        nullif(trim(supplier_address), '') AS supplier_address,
        supplier_city,
        supplier_country
    FROM memory.default.mock_all
) s
INNER JOIN clickhouse.bdtrino.dim_geography g
    ON s.supplier_city = from_utf8(g.city)
   AND from_utf8(g.state_region) = ''
   AND s.supplier_country = from_utf8(g.country);

INSERT INTO clickhouse.bdtrino.dim_product
SELECT
    CAST(row_number() OVER (ORDER BY x.product_hash, x.product_name) AS bigint) AS product_key,
    to_utf8(x.product_hash) AS product_hash,
    CAST(x.category_key AS bigint) AS category_key,
    to_utf8(x.product_name) AS product_name,
    to_utf8(x.product_brand) AS product_brand,
    to_utf8(x.product_size) AS product_size,
    to_utf8(x.product_material) AS product_material,
    to_utf8(x.product_color) AS product_color,
    x.product_weight,
    to_utf8(x.pet_category) AS pet_category,
    to_utf8(x.product_description) AS product_description,
    x.product_rating,
    x.product_reviews,
    x.product_release_date,
    x.product_expiry_date
FROM (
    SELECT
        p0.*,
        row_number() OVER (PARTITION BY product_hash ORDER BY product_name) AS rn
    FROM (
        SELECT
            lower(to_hex(md5(to_utf8(concat_ws('|',
                coalesce(m.product_name, ''),
                coalesce(m.product_category, ''),
                coalesce(m.product_brand, ''),
                coalesce(nullif(trim(m.product_size), ''), ''),
                coalesce(nullif(trim(m.product_material), ''), ''),
                coalesce(nullif(trim(m.product_color), ''), ''),
                coalesce(nullif(trim(m.product_weight), ''), ''),
                coalesce(nullif(trim(m.pet_category), ''), ''),
                coalesce(nullif(trim(m.product_rating), ''), ''),
                coalesce(nullif(trim(m.product_reviews), ''), ''),
                coalesce(nullif(trim(m.product_release_date), ''), ''),
                coalesce(nullif(trim(m.product_expiry_date), ''), '')
            ))))) AS product_hash,
            CAST(c.category_key AS bigint) AS category_key,
            m.product_name AS product_name,
            nullif(trim(m.product_brand), '') AS product_brand,
            nullif(trim(m.product_size), '') AS product_size,
            nullif(trim(m.product_material), '') AS product_material,
            nullif(trim(m.product_color), '') AS product_color,
            try_cast(
                nullif(regexp_replace(coalesce(nullif(trim(m.product_weight), ''), ''), ',', '.'), '')
                AS double
            ) AS product_weight,
            nullif(trim(m.pet_category), '') AS pet_category,
            m.product_description AS product_description,
            try_cast(
                nullif(regexp_replace(coalesce(nullif(trim(m.product_rating), ''), ''), ',', '.'), '')
                AS double
            ) AS product_rating,
            try_cast(nullif(trim(m.product_reviews), '') AS integer) AS product_reviews,
            try(
                cast(
                    parse_datetime(
                        nullif(trim(coalesce(m.product_release_date, '')), ''),
                        'M/d/uuuu'
                    ) AS date
                )
            ) AS product_release_date,
            try(
                cast(
                    parse_datetime(
                        nullif(trim(coalesce(m.product_expiry_date, '')), ''),
                        'M/d/uuuu'
                    ) AS date
                )
            ) AS product_expiry_date
        FROM memory.default.mock_all m
        INNER JOIN clickhouse.bdtrino.dim_product_category c
            ON m.product_category = from_utf8(c.category_name)
    ) p0
) x
WHERE x.rn = 1;

INSERT INTO clickhouse.bdtrino.dim_date
SELECT
    CAST(format_datetime(CAST(d AS timestamp(0)), 'yyyyMMdd') AS bigint) AS date_key,
    d AS full_date,
    CAST(year(d) AS integer) AS year_num,
    CAST(quarter(d) AS integer) AS quarter_num,
    CAST(month(d) AS integer) AS month_num,
    CAST(day(d) AS integer) AS day_of_month,
    CAST(day_of_week(d) AS integer) AS day_of_week,
    to_utf8(format_datetime(CAST(d AS timestamp(0)), 'MMMM')) AS month_name
FROM (
    SELECT DISTINCT coalesce(
        try(cast(parse_datetime(nullif(sd, ''), 'M/d/uuuu') AS date)),
        try(date_parse(nullif(sd, ''), '%c/%e/%Y')),
        try(date_parse(nullif(sd, ''), '%m/%d/%Y'))
    ) AS d
    FROM (
        SELECT replace(replace(trim(coalesce(sale_date, '')), chr(13), ''), chr(10), '') AS sd
        FROM memory.default.mock_all
    ) raw
) s
WHERE s.d IS NOT NULL;

INSERT INTO clickhouse.bdtrino.fact_sales
SELECT
    CAST(row_number() OVER (
        ORDER BY
            m.customer_email,
            m.sale_date,
            m.sale_product_id,
            m.sale_total_price,
            m.id
    ) AS bigint) AS sale_key,
    CAST(dd.date_key AS bigint) AS date_key,
    CAST(dc.customer_key AS bigint) AS customer_key,
    CAST(ds.seller_key AS bigint) AS seller_key,
    CAST(dp.product_key AS bigint) AS product_key,
    CAST(dst.store_key AS bigint) AS store_key,
    CAST(dsup.supplier_key AS bigint) AS supplier_key,
    CAST(try_cast(nullif(trim(m.sale_quantity), '') AS integer) AS integer) AS quantity,
    CAST(
        regexp_replace(coalesce(nullif(trim(m.sale_total_price), ''), '0'), ',', '.')
        AS decimal(14, 2)
    ) AS total_price,
    CAST(
        try_cast(regexp_replace(coalesce(nullif(trim(m.product_price), ''), '0'), ',', '.') AS double)
        AS decimal(14, 2)
    ) AS unit_list_price,
    try_cast(nullif(trim(m.sale_customer_id), '') AS integer) AS source_sale_customer_id,
    try_cast(nullif(trim(m.sale_seller_id), '') AS integer) AS source_sale_seller_id,
    try_cast(nullif(trim(m.sale_product_id), '') AS integer) AS source_sale_product_id
FROM memory.default.mock_all m
INNER JOIN clickhouse.bdtrino.dim_date dd
    ON coalesce(
        try(cast(parse_datetime(nullif(replace(replace(trim(coalesce(m.sale_date, '')), chr(13), ''), chr(10), ''), ''), 'M/d/uuuu') AS date)),
        try(date_parse(nullif(replace(replace(trim(coalesce(m.sale_date, '')), chr(13), ''), chr(10), ''), ''), '%c/%e/%Y')),
        try(date_parse(nullif(replace(replace(trim(coalesce(m.sale_date, '')), chr(13), ''), chr(10), ''), ''), '%m/%d/%Y'))
    ) = dd.full_date
INNER JOIN clickhouse.bdtrino.dim_customer dc
    ON m.customer_email = from_utf8(dc.customer_email)
INNER JOIN clickhouse.bdtrino.dim_seller ds
    ON m.seller_email = from_utf8(ds.seller_email)
INNER JOIN clickhouse.bdtrino.dim_product dp
    ON lower(to_hex(md5(to_utf8(concat_ws('|',
        coalesce(m.product_name, ''),
        coalesce(m.product_category, ''),
        coalesce(m.product_brand, ''),
        coalesce(nullif(trim(m.product_size), ''), ''),
        coalesce(nullif(trim(m.product_material), ''), ''),
        coalesce(nullif(trim(m.product_color), ''), ''),
        coalesce(nullif(trim(m.product_weight), ''), ''),
        coalesce(nullif(trim(m.pet_category), ''), ''),
        coalesce(nullif(trim(m.product_rating), ''), ''),
        coalesce(nullif(trim(m.product_reviews), ''), ''),
        coalesce(nullif(trim(m.product_release_date), ''), ''),
        coalesce(nullif(trim(m.product_expiry_date), ''), '')
    ))))) = from_utf8(dp.product_hash)
INNER JOIN clickhouse.bdtrino.dim_store dst
    ON lower(to_hex(md5(to_utf8(concat_ws('|',
        coalesce(m.store_name, ''),
        coalesce(nullif(trim(m.store_location), ''), ''),
        coalesce(m.store_city, ''),
        coalesce(nullif(trim(m.store_state), ''), ''),
        coalesce(m.store_country, ''),
        coalesce(nullif(trim(m.store_phone), ''), ''),
        coalesce(nullif(trim(m.store_email), ''), '')
    ))))) = from_utf8(dst.store_hash)
INNER JOIN clickhouse.bdtrino.dim_supplier dsup
    ON lower(to_hex(md5(to_utf8(concat_ws('|',
        coalesce(nullif(trim(m.supplier_name), ''), ''),
        coalesce(nullif(trim(m.supplier_contact), ''), ''),
        coalesce(nullif(trim(m.supplier_email), ''), ''),
        coalesce(nullif(trim(m.supplier_phone), ''), ''),
        coalesce(nullif(trim(m.supplier_address), ''), ''),
        coalesce(m.supplier_city, ''),
        coalesce(m.supplier_country, '')
    ))))) = from_utf8(dsup.supplier_hash);

DROP TABLE memory.default.mock_all;
