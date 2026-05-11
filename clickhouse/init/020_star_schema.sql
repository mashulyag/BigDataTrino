CREATE TABLE IF NOT EXISTS bdtrino.dim_geography
(
    geo_key UInt32,
    city String,
    state_region String,
    country String
)
ENGINE = MergeTree
ORDER BY geo_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_product_category
(
    category_key UInt32,
    category_name String
)
ENGINE = MergeTree
ORDER BY category_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_customer
(
    customer_key UInt32,
    customer_email String,
    customer_first_name Nullable(String),
    customer_last_name Nullable(String),
    customer_age Nullable(Int32),
    customer_country Nullable(String),
    customer_postal_code Nullable(String),
    customer_pet_type Nullable(String),
    customer_pet_name Nullable(String),
    customer_pet_breed Nullable(String)
)
ENGINE = MergeTree
ORDER BY customer_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_seller
(
    seller_key UInt32,
    seller_email String,
    seller_first_name Nullable(String),
    seller_last_name Nullable(String),
    seller_country Nullable(String),
    seller_postal_code Nullable(String)
)
ENGINE = MergeTree
ORDER BY seller_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_store
(
    store_key UInt32,
    store_hash String,
    store_name String,
    store_location Nullable(String),
    store_phone Nullable(String),
    store_email Nullable(String),
    geo_key UInt32
)
ENGINE = MergeTree
ORDER BY store_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_supplier
(
    supplier_key UInt32,
    supplier_hash String,
    supplier_name Nullable(String),
    supplier_contact Nullable(String),
    supplier_email Nullable(String),
    supplier_phone Nullable(String),
    supplier_address Nullable(String),
    geo_key UInt32
)
ENGINE = MergeTree
ORDER BY supplier_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_product
(
    product_key UInt32,
    product_hash String,
    category_key UInt32,
    product_name String,
    product_brand Nullable(String),
    product_size Nullable(String),
    product_material Nullable(String),
    product_color Nullable(String),
    product_weight Nullable(Float64),
    pet_category Nullable(String),
    product_description Nullable(String),
    product_rating Nullable(Float64),
    product_reviews Nullable(Int32),
    product_release_date Nullable(Date),
    product_expiry_date Nullable(Date)
)
ENGINE = MergeTree
ORDER BY product_key;

CREATE TABLE IF NOT EXISTS bdtrino.dim_date
(
    date_key Int32,
    full_date Date,
    year_num Int32,
    quarter_num Int32,
    month_num Int32,
    day_of_month Int32,
    day_of_week Int32,
    month_name String
)
ENGINE = MergeTree
ORDER BY date_key;

CREATE TABLE IF NOT EXISTS bdtrino.fact_sales
(
    sale_key UInt64,
    date_key Int32,
    customer_key UInt32,
    seller_key UInt32,
    product_key UInt32,
    store_key UInt32,
    supplier_key UInt32,
    quantity Int32,
    total_price Decimal(14, 2),
    unit_list_price Nullable(Decimal(14, 2)),
    source_sale_customer_id Nullable(Int32),
    source_sale_seller_id Nullable(Int32),
    source_sale_product_id Nullable(Int32)
)
ENGINE = MergeTree
ORDER BY sale_key;
