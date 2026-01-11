# R/batch_score_sla_risk.R
# Purpose: Load trained model -> score risk_score from mart.v_sla_model_cohort
#          -> percentile-based risk_flag (P90/P95) -> UPSERT into mart.sla_risk_scoring

library(DBI)
library(RPostgres)
library(dplyr)
library(glmnet)

MODEL_PATH <- "models/cvfit_ridge_logit_v1.rds"
LAMBDA_S   <- "lambda.1se"
MODEL_VERSION <- "late_review_logit_v1"

con <- dbConnect(
  RPostgres::Postgres(),
  host = "localhost",
  port = 5432,
  dbname = "olist_dw",
  user = "olist",
  password = "olistpw"
)

if (!file.exists(MODEL_PATH)) {
  stop("Model file not found: ", MODEL_PATH)
}
cvfit <- readRDS(MODEL_PATH)

# ✅ MUST exist (this is what your error is missing)
coef_names <- rownames(coef(cvfit, s = LAMBDA_S))
coef_names <- coef_names[coef_names != "(Intercept)"]

df <- dbGetQuery(con, "
  SELECT
    order_id,
    delay_bucket,
    log_price,
    log_freight_value,
    items_count,
    month
  FROM mart.v_sla_model_cohort;
")

df$delay_bucket <- factor(df$delay_bucket, levels = c('0','1-3','4-7','8-14','15-30'))
df$month <- factor(df$month, levels = as.character(1:12))

x <- model.matrix(~ delay_bucket + log_price + log_freight_value + items_count + month, data = df)
x <- x[, -1, drop = FALSE]

missing_cols <- setdiff(coef_names, colnames(x))
if (length(missing_cols) > 0) {
  add_mat <- matrix(0, nrow = nrow(x), ncol = length(missing_cols))
  colnames(add_mat) <- missing_cols
  x <- cbind(x, add_mat)
}

extra_cols <- setdiff(colnames(x), coef_names)
if (length(extra_cols) > 0) {
  x <- x[, setdiff(colnames(x), extra_cols), drop = FALSE]
}

x <- x[, coef_names, drop = FALSE]

risk_score <- as.numeric(predict(cvfit, newx = x, s = LAMBDA_S, type = "response"))

scored <- data.frame(
  score_date = as.Date(Sys.Date()),
  order_id = df$order_id,
  risk_score = risk_score,
  stringsAsFactors = FALSE
)

# P90/P95 flags
p95 <- as.numeric(quantile(scored$risk_score, 0.95, na.rm = TRUE))
p90 <- as.numeric(quantile(scored$risk_score, 0.90, na.rm = TRUE))

scored$risk_flag <- dplyr::case_when(
  scored$risk_score >= p95 ~ "red",
  scored$risk_score >= p90 ~ "amber",
  TRUE ~ "green"
)

scored$model_version <- MODEL_VERSION

dbWriteTable(con, "tmp_sla_risk_scoring", scored, temporary = TRUE, overwrite = TRUE)

dbExecute(con, "
  INSERT INTO mart.sla_risk_scoring (score_date, order_id, risk_score, risk_flag, model_version)
  SELECT score_date, order_id, risk_score, risk_flag, model_version
  FROM tmp_sla_risk_scoring
  ON CONFLICT (score_date, order_id)
  DO UPDATE SET
    risk_score = EXCLUDED.risk_score,
    risk_flag = EXCLUDED.risk_flag,
    model_version = EXCLUDED.model_version,
    created_at = now()
")

cat('✅ Scored rows:', nrow(scored),
    '| score_date:', as.character(Sys.Date()),
    '| P90:', round(p90, 6),
    '| P95:', round(p95, 6),
    '\n')

dbDisconnect(con)
