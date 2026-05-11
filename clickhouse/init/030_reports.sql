CREATE TABLE IF NOT EXISTS bdtrino.rpt_sales_by_product
(
    product_key UInt32,
    product_name String,
    category_name String,
    total_revenue Float64,
    units_sold Int64,
    order_count Int64,
    avg_rating Nullable(Float64),
    review_count Nullable(Int32)
)
ENGINE = MergeTree
ORDER BY product_key;

CREATE TABLE IF NOT EXISTS bdtrino.rpt_sales_by_customer
(
    customer_key UInt32,
    customer_email String,
    customer_country Nullable(String),
    total_revenue Float64,
    order_count Int64,
    avg_order_value Float64
)
ENGINE = MergeTree
ORDER BY customer_key;

CREATE TABLE IF NOT EXISTS bdtrino.rpt_sales_by_time
(
    period_type LowCardinality(String),
    year_num UInt16,
    month_num UInt8,
    month_name Nullable(String),
    revenue Float64,
    order_count Int64,
    avg_order_value Float64
)
ENGINE = MergeTree
ORDER BY (period_type, year_num, month_num);

CREATE TABLE IF NOT EXISTS bdtrino.rpt_sales_by_store
(
    store_key UInt32,
    store_name String,
    city Nullable(String),
    country Nullable(String),
    revenue Float64,
    order_count Int64,
    avg_check Float64
)
ENGINE = MergeTree
ORDER BY store_key;

CREATE TABLE IF NOT EXISTS bdtrino.rpt_sales_by_supplier
(
    supplier_key UInt32,
    supplier_name Nullable(String),
    supplier_country Nullable(String),
    revenue Float64,
    units_sold Int64,
    avg_unit_price Nullable(Float64)
)
ENGINE = MergeTree
ORDER BY supplier_key;

CREATE TABLE IF NOT EXISTS bdtrino.rpt_product_quality
(
    product_key UInt32,
    product_name String,
    product_rating Nullable(Float64),
    review_count Nullable(Int32),
    total_revenue Float64,
    units_sold Int64
)
ENGINE = MergeTree
ORDER BY product_key;
