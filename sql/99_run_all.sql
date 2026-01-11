\set ON_ERROR_STOP on
\pset pager off

\echo '=== (0) Create raw ==='
\i /sql/00_create_schemas.sql
\i /sql/01_create_raw_tables.sql
\i /sql/02_copy_raw_data.sql

\echo '=== (1) Create DW tables ==='
\i /sql/10_create_dw_tables.sql
\i /sql/11_load_dw_dim_tables.sql
\i /sql/12_load_dw_facts.sql
\i /sql/13_dw_indexes_and_qa.sql

\echo '=== (3) Build marts ==='
\i /sql/20_create_mart_schema.sql
\i /sql/21_mart_order_facts.sql
\i /sql/21b_mart_order_facts_indexes.sql
\i /sql/22_mart_rfm.sql
\i /sql/23_mart_sla.sql
\i /sql/24_mart_item_facts.sql
\i /sql/24b_mart_item_facts_indexes.sql
\i /sql/25_mart_delivery_review.sql
\i /sql/25b_mart_delivery_review_indexes.sql
\i /sql/26_mart_sla_enriched_view.sql
\i /sql/27_mart_sla_model_cohort.sql

\echo '=== (4) qa ==='
\i /sql/90_qa_customer_rfm.sql
\i /sql/91_qa_sla_marts.sql


\echo '=== DONE ==='
