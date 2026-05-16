# Olist Retail Warehouse & BI (Postgres → DW → Analytics & Proactive Risk Scoring)

End-to-end analytics engineering and data science project using the Brazilian Olist e-commerce dataset.

This project addresses a critical e-commerce challenge: **identifying severe delivery delay impacts on customer experience and proactively deploying a Ridge Logistic Regression model to flag high-risk orders before they result in low customer reviews.**

Built a reproducible local data warehouse with Docker + PostgreSQL, modeled a comprehensive **Star Schema DW layer**, created specialized **SLA & Order Analytics Marts**, and integrated an **R-based predictive pipeline** that scores live orders and pipes results back to database views for Customer Service (CS) action.

## Tech Stack

* **Database & DW:** PostgreSQL (Docker)
* **Data Transformation:** SQL (Raw → DW → Multi-layered Marts)
* **Data Science / Modeling:** R (Cross-validated Ridge Logistic Regression via `glmnet`, `rmarkdown`)
* **Business Intelligence:** Tableau / BI Dashboard (Fulfillment funnel tracking & tactical WBR reports)

---

## Project Structure & Pipeline Flow

The repository is structured to mirror a professional data engineering and data science workflow:

```text
.
├── docker-compose.yml
├── data_raw/                          # Git-ignored directory for Olist raw CSVs
│
├── sql/                               # Comprehensive SQL Pipeline
│   ├── 00_create_schemas.sql          # Initializes raw, dw, and mart schemas
│   ├── 01_create_raw_tables.sql       # Sets up DDL for staging tables
│   ├── 01_reset_raw_tables.sql        # Clean tear-down script
│   ├── 02_copy_raw_data.sql           # Bulk copies CSV data into RAW layer
│   ├── 10_create_dw_tables.sql        # Creates Fact & Dimension tables
│   ├── 11_load_dw_dim_tables.sql      # Populates dim_customer, dim_products, etc.
│   ├── 12_load_dw_facts_items.sql     # Populates core fact_order_items table
│   ├── 13_dw_indexes_and_qa.sql       # Enforces constraints and indexing for speed
│   ├── 21_mart_order_facts.sql        # Order-grain fundamental summary mart
│   ├── 21_b_mart_order_facts_indexes.sql
│   ├── 22_mart_rfm.sql                # Marketing-focused customer RFM segments
│   ├── 23_mart_sla_orders.sql         # Delivery SLA tracking mart
│   ├── 24_mart_item_facts.sql         # Item-grain analytical mart
│   ├── 24b_mart_item_facts_indexes.sql
│   ├── 25_mart_delivery_review.sql    # Conflates delivery performance and reviews
│   ├── 25b_mart_delivery_review_indexes.sql
│   ├── 26_mart_sla_enriched_view.sql  # Flat wide view optimized for BI tools
│   ├── 27_mart_sla_model_cohort.sql   # Generates historical training cohort for ML
│   ├── 28_create_sla_risk_scoring.sql # Table schema to store model outputs (scores)
│   ├── 29_view_sla_order_scored.sql   # Dynamic view prioritizing high-risk cases for CS
│   ├── 30_mart_sla_wbr_weekly.sql     # Weekly Business Review metrics aggregation
│   ├── 90_qa_customer_rfm.sql         # Quality assurance test cases for RFM
│   ├── 91_qa_sla_marts.sql            # Quality assurance test cases for SLAs
│   └── 99_run_all.sql                 # Master execution script for orchestration
│
└── r_model/                            # Predictive Machine Learning Pipeline
    ├── cvfit_ridge_logit_v1.rds       # Saved Cross-Validated Ridge Logistic Regression model object
    ├── late_review_logit.Rmd          # R Markdown notebook for EDA, feature selection, and modeling
    ├── late_review_logit.R            # Pure R extraction of the modeling process
    ├── late_review_logit.pdf          # Knitted summary report of model performance and coefficients
    └── batch_score_sla_risk.R         # Production script for batch scoring live orders into Postgres

```

---

## Data Pipeline Execution

### 1) Spin Up Database & Setup Warehouse Layer

Run the initial setup scripts to provision PostgreSQL, ingest raw source files, build the star schema dimensions/facts, and apply database optimizations:

```bash
docker compose up -d

# Execute core infrastructure sequentially or use the master script:
docker exec -i olist_postgres psql -U olist -d olist_dw -f sql/99_run_all.sql

```

### 2) Machine Learning & Proactive Risk Pipeline

Once the analytical cohorts are generated in the database via `27_mart_sla_model_cohort.sql`, the R workflow handles risk forecasting:

1. **Model Training (`late_review_logit.Rmd`):** Trailed on past fulfillment data. A regularized **Ridge Logistic Regression** model is utilized to handle correlated logistics parameters (e.g., freight value, purchase-to-carrier speed, item counts).
2. **Model Persistence (`cvfit_ridge_logit_v1.rds`):** The final tuned, cross-validated model artifact is saved to disk.
3. **Batch Scoring Engine (`batch_score_sla_risk.R`):** Pulls currently active, undelivered, or early-delayed orders from the database, applies the `.rds` model file to compute the probability of a low review score ($>0.70$), and logs the results back into `mart.create_sla_risk_scoring`.

---

## Multi-Layered Analytics Engineering Architecture

### 📊 Core Data Warehouse

* **`dw.fact_order_items`**: Main fact table holding price metrics, items count, and exact shipping/delivery/estimated timestamps.
* **Dimensions**: Cleaned master attributes for customers (`dim_customer`), sellers (`dim_sellers`), products with translated English names (`dim_products`), and a central calendar matrix (`dim_date`).

### 📈 Business-Driven Data Marts

* **Fulfillment SLA (`mart.23_mart_sla_orders` & `26_mart_sla_enriched_view`):** Segments delivery delay into logical risk buckets (`0`, `1-3`, `4-7`, `8-14`, `15-30` days). This acts as the direct data layer feeding into a Tableau operational dashboard.
* **Predictive Wind-back (`mart.28_create_sla_risk_scoring` & `29_view_sla_order_scored`):** Holds the real-time or batch-inserted prediction outputs. The downstream view explicitly surfaces `order_id`s with `risk_flag = 'red'` (risk scores $>0.70$) that fall heavily into the critical 4-7 or 8-14 day delay brackets.

---

## Key Business Insights & Deliverables

1. **The 8-Day Sentiment Cliff:** Analysis through `25_mart_delivery_review.sql` proves that customer dissatisfaction scales non-linearly. Minor delays of 1-3 days maintain manageable satisfaction levels (~20% low review rate), but crossing the **8-day delay mark triggers an abrupt collapse in user experience, pushing the low-review rate past 60-70%.**
2. **Proactive Operations Dashboard:**
Transitions customer service teams from reactive firefighters to proactive retention managers. Using the live view `29_view_sla_order_scored.sql`, agents get an automated daily follow-up list of high-risk customers, allowing them to initiate outreach (e.g., goodwill credits, priority support re-routing) before the customer receives their order and posts a negative rating.

---

## Next Steps / Future Work

* Integrate batch_score_sla_risk.R into an Airflow DAG to achieve fully automated daily batch scoring and seamless database updates.
