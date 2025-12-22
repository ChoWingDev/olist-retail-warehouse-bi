DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

#reset commands
#docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_reset_raw_tables.sql
#docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_create_raw_tables.sql
#docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/02_copy_raw_data.sql
