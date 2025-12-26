# Olist Retail Warehouse & BI (Postgres → DW → Analytics Marts)

End-to-end analytics engineering project using the Brazilian Olist e-commerce dataset.
Built a reproducible local data warehouse with Docker + PostgreSQL, loaded raw CSVs into a **RAW layer**,
modeled a **star schema DW layer (dimensions + fact)**, and built initial **analytics marts** for customer analytics (RFM).

## Tech Stack
- PostgreSQL (Docker)
- SQL (raw → dw → mart)
- (Planned) Tableau dashboard
- (Planned) R analysis (logistic regression, segmentation)
- (Planned) Redshift validation (same schema + marts)

## Project Structure

```text
.
├── docker-compose.yml
├── data_raw/                  # ignored by git (raw CSV files)
├── sql/
│   ├── 00_create_schemas.sql
│   ├── 01_create_raw_tables.sql
│   ├── 01_reset_raw_tables.sql
│   ├── 02_copy_raw_data.sql
│   ├── 10_create_dw_tables.sql
│   ├── 11_load_dw_dims.sql
│   ├── 12_load_dw_fact.sql
│   ├── 13_dw_indexes_and_qa.sql
│   ├── 03_create_mart_schema.sql
│   ├── 04_mart_order_facts.sql
│   ├── 04b_mart_order_facts_indexes.sql
│   ├── 05_mart_customer_rfm.sql
│   └── 06_qa_customer_rfm.sql
└── README.md
````

## Prerequisites

* Docker Desktop
* Git

## Quick Start (Local Postgres)

### 1) Start Postgres

```bash
docker compose up -d
```

### 2) Create schemas + raw tables

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/00_create_schemas.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_create_raw_tables.sql
```

### 3) Load raw CSV data

Place the Olist CSV files under `data_raw/` (this folder is git-ignored), then run:

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/02_copy_raw_data.sql
```

### 4) Validate RAW row counts

```bash
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
```

## Build the DW Layer (Star Schema)

### 5) Create DW tables (dims + fact)

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/10_create_dw_tables.sql
```

### 6) Load DW dimensions

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/11_load_dw_dims.sql
```

### 7) Load DW fact table

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/12_load_dw_fact.sql
```

### 8) Add indexes + run DW QA checks

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/13_dw_indexes_and_qa.sql
```

### 9) Validate DW row counts (dims)

```bash
docker exec -it olist_postgres psql -U olist -d olist_dw -P pager=off -c "
SELECT 'dim_customer' t, COUNT(*) c FROM dw.dim_customer UNION ALL
SELECT 'dim_sellers', COUNT(*) FROM dw.dim_sellers UNION ALL
SELECT 'dim_products', COUNT(*) FROM dw.dim_products UNION ALL
SELECT 'dim_date', COUNT(*) FROM dw.dim_date
ORDER BY t;
"
```

## Build Analytics Marts

### 10) Create mart schema

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/03_create_mart_schema.sql
```

### 11) Build order_facts (order-level mart)

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/04_mart_order_facts.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/04b_mart_order_facts_indexes.sql
```

### 12) Build customer RFM mart + QA

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/05_mart_customer_rfm.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/06_qa_customer_rfm.sql
```

## Reset RAW Layer (Optional)

If you need to rebuild the raw layer from scratch:

```bash
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_reset_raw_tables.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/01_create_raw_tables.sql
docker exec -i olist_postgres psql -U olist -d olist_dw -v ON_ERROR_STOP=1 < sql/02_copy_raw_data.sql
```

## Data Model (Star Schema)

The DW layer follows a star schema to support reusable BI queries and downstream marts.

### Grain

* **Fact table grain:** 1 row per **order item** (`order_id`, `order_item_id`)

### Tables

**Dimensions**

* `dw.dim_customer` (PK: `customer_id`)
  Customer attributes: unique_id, city/state, zip prefix
* `dw.dim_sellers` (PK: `seller_id`)
  Seller attributes: city/state, zip prefix
* `dw.dim_products` (PK: `product_id`)
  Product attributes: category + **English category name** (via translation table), weight/dimensions
* `dw.dim_date` (PK: `date_key`)
  Calendar attributes: year/month/day/day_of_week (1 row per calendar day)

**Fact**

* `dw.fact_order_items` (PK: `order_id`, `order_item_id`)
  Order-item measures and events:

  * Measures: `price`, `freight_value`
  * Order context: `order_status`
  * Timestamps: purchase/approval/delivery/estimated delivery, shipping limit

### Join Keys

* `dw.fact_order_items.customer_id` → `dw.dim_customer.customer_id`
* `dw.fact_order_items.seller_id` → `dw.dim_sellers.seller_id`
* `dw.fact_order_items.product_id` → `dw.dim_products.product_id`
* (For time slicing) `purchase_ts::date` → `dw.dim_date.date_key`

## Analytics Marts

### mart.order_facts

**Purpose:** Order-level summary for delivery SLAs, payment metrics, and customer analytics.
**Grain:** 1 row per **order** (`order_id`).

**Key fields**

* Identifiers: `order_id`, `customer_id`, `order_status`
* Timestamps: `purchase_ts`, `approved_ts`, `delivered_carrier_ts`, `delivered_customer_ts`, `estimated_delivery_date`
* Delivery KPIs: `delivery_days`, `is_late`
* Items aggregated: `items_cnt`, `items_revenue`, `freight_total`, `gmv`
* Payments aggregated: `payment_value_total`, `max_installments`, `primary_payment_type`

### mart.customer_rfm

**Purpose:** Customer segmentation for retention / win-back analysis.
**Grain:** 1 row per **customer** (uses `customer_unique_id` as `customer_id`).

**Definitions**

* Orders included: `order_status = 'delivered'`
* `as_of_date`: `MAX(purchase_ts)::date` (dataset-stable reference date)
* Recency: `recency_days = as_of_date - last_purchase_date` (smaller = more recent)
* Frequency: number of delivered orders per customer
* Monetary: `SUM(payment_value_total)` per customer

**Scoring**

* Uses quintiles: `NTILE(5)` to assign `r_score`, `f_score`, `m_score` in `[1..5]`
* Recency is reversed so that more recent customers get higher `r_score`

**Segments (current)**

* `champions`, `loyal_customers`, `new_customers`, `new_high_value`,
  `at_risk_loyal`, `big_spenders_at_risk`, `lost`, `others`

## Roadmap

* [x] Local Postgres via Docker
* [x] RAW layer: schemas, tables, and CSV load
* [x] DW layer: star schema (dims + fact)
* [x] DW performance + QA (indexes, PK uniqueness, date range checks)
* [x] Analytics marts: order_facts + RFM
* [ ] Additional marts: delivery→review, seller SLA
* [ ] Tableau dashboard
* [ ] R analysis (logistic regression, segmentation)
* [ ] Redshift validation


