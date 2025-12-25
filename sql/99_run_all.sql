\set ON_ERROR_STOP on
\pset pager off

\echo '=== (0) Create schemas ==='
\i /sql/00_create_schemas.sql

\echo '=== (1) Create raw tables ==='
\i /sql/01_create_raw_tables.sql

\echo '=== (2) Load raw CSV data ==='
\i /sql/02_copy_raw_data.sql

\echo '=== (3) Build DW tables ==='
\i /sql/create_dw_tables.sql

\echo '=== (4) Build marts ==='
\i /sql/04_mart_order_facts.sql
\i /sql/04b_mart_order_facts_indexes.sql

\echo '=== DONE ==='
