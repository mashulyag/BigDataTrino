-- Проверки в ClickHouse (порт хоста 8124, пароль bdtrino_ch).
-- Пример:
--   docker compose exec -T clickhouse clickhouse-client --user default --password bdtrino_ch --queries-file /etc/manual/01_checks.sql
-- Или из хоста с clickhouse-client, подключившись к localhost:8124.

SELECT 'mock_data_ch' AS tbl, count() AS n FROM bdtrino.mock_data;
SELECT 'fact_sales' AS tbl, count() AS n FROM bdtrino.fact_sales;
SELECT 'rpt_sales_by_product' AS tbl, count() AS n FROM bdtrino.rpt_sales_by_product;

SELECT
    (SELECT count() FROM bdtrino.fact_sales) AS fact_rows,
    (SELECT count() FROM bdtrino.mock_data) AS ch_mock_rows;

SELECT sum(total_price) AS sum_fact_total_price FROM bdtrino.fact_sales;
