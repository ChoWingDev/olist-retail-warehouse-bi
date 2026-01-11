# ============================================================
# Predict low review using delivery features (Ridge Logistic)
# ============================================================

# 1) Packages ------------------------------------------------
library(DBI)
library(RPostgres)
library(dplyr)
library(glmnet)
library(pROC)

# 2) Load data from Postgres ---------------------------------
con <- dbConnect(
  RPostgres::Postgres(),
  host = "localhost",
  port = 5432,
  dbname = "olist_dw",
  user = "olist",
  password = "olistpw"
)

delivery_review_df <- dbGetQuery(con, "SELECT * FROM mart.delivery_review;")
dbDisconnect(con)

# Quick sanity checks
dim(delivery_review_df)
head(delivery_review_df)

# 3) Data cleaning + feature engineering ---------------------
# Goal:
# - Keep complete cases for modeling
# - Cap extreme delays (reduce outlier impact)
# - Log-transform skewed monetary variables
# - Bucket delay to make the relationship more stable and reduce separation risk

delivery_review_clean_df <- delivery_review_df %>%
  filter(
    !is.na(is_low_review),
    !is.na(delivery_delay_days),
    !is.na(price),
    !is.na(freight_value),
    !is.na(items_count),
    !is.na(month)
  ) %>%
  mutate(
    # Convert target to 0/1 for modeling
    is_low_review = as.integer(is_low_review),
    
    # Treat month as categorical (seasonality)
    month = factor(month),
    
    # Cap delivery delay at 30 days (winsorize)
    delay_cap = pmin(delivery_delay_days, 30),
    
    # Log transforms for heavy-tailed distributions
    log_price = log1p(price),
    log_freight = log1p(freight_value),
    
    # Delay buckets (more interpretable + more robust than raw days)
    delay_bucket = cut(
      delay_cap,
      breaks = c(-Inf, 0, 3, 7, 14, 30),
      labels = c("0", "1-3", "4-7", "8-14", "15-30"),
      right = TRUE
    )
  )

# Sanity checks on engineered features
table(delivery_review_clean_df$delay_bucket, useNA = "ifany")
summary(delivery_review_clean_df$delay_cap)

# 4) Train / test split --------------------------------------
set.seed(42)
idx <- sample(seq_len(nrow(delivery_review_clean_df)),
              size = floor(0.8 * nrow(delivery_review_clean_df)))

train_df <- delivery_review_clean_df[idx, ]
test_df  <- delivery_review_clean_df[-idx, ]

# 5) Design matrix for glmnet --------------------------------
# glmnet expects an X matrix (numeric) and y vector (0/1)
x_train <- model.matrix(
  is_low_review ~ delay_bucket + log_price + log_freight + items_count + month,
  data = train_df
)[, -1]  # drop intercept column

y_train <- train_df$is_low_review

# 6) Ridge logistic with k-fold CV to pick lambda -------------
# Why ridge (L2)?
# - Logistic regression may fail to converge under (quasi-)separation
# - Ridge shrinks coefficients, stabilizes estimation, and improves generalization

set.seed(42)
cvfit <- cv.glmnet(
  x_train, y_train,
  family = "binomial",
  alpha = 0,      # alpha=0 => ridge (L2)
  nfolds = 5
)

cvfit$lambda.min   # best CV score (more flexible)
cvfit$lambda.1se   # within 1 SE (more regularized / more stable)

# 7) Evaluate on test set using AUC ---------------------------
x_test <- model.matrix(
  is_low_review ~ delay_bucket + log_price + log_freight + items_count + month,
  data = test_df
)[, -1]

y_test <- test_df$is_low_review

# Predicted probabilities
p_min <- as.numeric(predict(cvfit, newx = x_test, s = "lambda.min", type = "response"))
p_1se <- as.numeric(predict(cvfit, newx = x_test, s = "lambda.1se", type = "response"))

# AUC: probability the model ranks a random positive higher than a random negative
auc_min <- pROC::auc(pROC::roc(y_test, p_min))
auc_1se <- pROC::auc(pROC::roc(y_test, p_1se))

auc_min
auc_1se

# 8) Choose a decision threshold (turn prob -> 0/1) -----------
# Threshold controls the precision/recall trade-off.
# - Higher threshold: fewer false positives, but more false negatives
# - Lower threshold: more true positives, but more false positives

# Baseline thresholds for comparison
pred_05 <- as.integer(p_1se >= 0.5)
table(pred_05, y_test)

pred_03 <- as.integer(p_1se >= 0.3)
table(pred_03, y_test)

# ROC-based threshold (Youden's J: sensitivity + specificity - 1)
roc_obj <- pROC::roc(y_test, p_1se)
best <- pROC::coords(
  roc_obj,
  x = "best",
  best.method = "youden",
  ret = c("threshold", "sensitivity", "specificity")
)
best

thr_youden <- as.numeric(best$threshold[1])
pred_youden <- as.integer(p_1se >= thr_youden)
table(pred_youden, y_test)

# A more balanced, practical threshold example
thr_mid <- 0.2
pred_02 <- as.integer(p_1se >= thr_mid)
table(pred_02, y_test)

#Coefficients at lambda.1se
beta_1se <- coef(cvfit, s="lambda.1se")

#Convert sparse matrix -> tidy table
coef_df <- data.frame(
  term = rownames(beta_1se),
  beta = as.numeric(beta_1se)
)

# Add odds ratio for interpretability
coef_df$odds_ratio <- exp(coef_df$beta)

#Show key terms first (delay buckets + month + numeric vars)
subset_df <- coef_df[grep("^delay_bucket|^month|log_price|log_freight|items_count|\\(Intercept\\)", coef_df$term), ]
subset_df[order(subset_df$term), ]

#top 10 strongest effects by absolute beta (excluding intercept)
coef_no_intercept <- coef_df[coef_df$term != "(Intercept)", ]
coef_no_intercept[order(-abs(coef_no_intercept$beta)), ][1:10, ]

# convert to probability 
p0 <- mean(train_df$is_low_review[train_df$delay_bucket == "0"])
odds0 <- p0/(1-p0)

or_bucket <- subset_df[grep("^delay_bucket", subset_df$term), c("term", "odds_ratio")]
prob <- (odds0 * or_bucket$odds_ratio)/ (1+odds0*or_bucket$odds_ratio)

out <- rbind(
  data.frame(term="delay_bucket0 (baseline)", odds_ratio=1, prob=p0),
  data.frame(term=or_bucket$term, odds_ratio=or_bucket$odds_ratio, prob=prob)
)

out
