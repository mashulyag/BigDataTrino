COPY mock_data FROM '/data/csv/MOCK_DATA (5).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY mock_data FROM '/data/csv/MOCK_DATA (6).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY mock_data FROM '/data/csv/MOCK_DATA (7).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY mock_data FROM '/data/csv/MOCK_DATA (8).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
COPY mock_data FROM '/data/csv/MOCK_DATA (9).csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

SELECT COUNT(*) AS mock_data_rows_pg FROM mock_data;
