# Olist Retail Warehouse & BI (Postgres → DW → Analytics Marts)

End-to-end analytics engineering project using the Brazilian Olist e-commerce dataset.
Built a reproducible local data warehouse with Docker + PostgreSQL, loaded raw CSVs,
and (next) will model a star schema (DW) and analytics marts for BI dashboards and R analysis.

## Tech Stack
- PostgreSQL (Docker)
- SQL (raw → dw → mart)
- (Planned) Tableau dashboard
- (Planned) R analysis (logistic regression, RFM segmentation)
- (Planned) Redshift validation (same schema + marts)

## Project Structure

├── docker-compose.yml
├── data_raw/ # ignored by git (raw CSV files)
├── sql/
│ ├── 00_create_schemas.sql
│ ├── 01_create_raw_tables.sql
│ ├── 01_reset_raw_tables.sql
│ ├── 02_copy_raw_data.sql
│ └── (next) dw/ mart/ scripts...
└── README.md


## Prerequisites
- Docker Desktop
- Git

## Quick Start (Local Postgres)
1) Start Postgres
```bash
docker compose up -d

2）Create schemas + raw tables

docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/00_create_schemas.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_create_raw_tables.sql

3）Load raw CSV data
   Place the Olist CSV files under data_raw/ (this folder is git-ignored), then run:

   docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/02_copy_raw_data.sql

4) Validate row counts:
docker exec -it olist_postgres psql -U olist -d olist_dw -P pager=off -c "
SELECT 'customers' AS t, COUNT(*) FROM raw.olist_customers UNION ALL
SELECT 'geolocation', COUNT(*) FROM raw.olist_geolocation UNION ALL
SELECT 'orders', COUNT(*) FROM raw.olist_orders UNION ALL
SELECT 'order_items', COUNT(*) FROM raw.olist_order_items UNION ALL
SELECT 'payments', COUNT(*) FROM raw.olist_order_payments UNION ALL
SELECT 'reviews', COUNT(*) FROM raw.olist_order_reviews UNION ALL
SELECT 'products', COUNT(*) FROM raw.olist_products UNION ALL
SELECT 'sellers', COUNT(*) FROM raw.olist_sellers UNION ALL
SELECT 'category_translation', COUNT(*) FROM raw.product_category_name_translation
ORDER BY t;
"
