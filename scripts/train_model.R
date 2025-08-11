# scripts/train_model.R
library(parsnip)
library(workflows)
library(recipes)
library(rsample)
library(yardstick)
library(dplyr)
library(digest)
library(readr)

train_model <- function(df, target, model_type = 'logistic', cache_dir = 'models', seed = 123) {
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  fp <- digest::digest(readr::format_csv(df), algo = 'md5')
  model_tag <- paste0(model_type, '_', fp)
  outdir <- file.path(cache_dir, model_tag)
  if(dir.exists(outdir) && file.exists(file.path(outdir, 'workflow.rds'))) {
    wf <- readRDS(file.path(outdir, 'workflow.rds'))
    metrics <- readRDS(file.path(outdir, 'metrics.rds'))
    return(list(path = outdir, workflow = wf, metrics = metrics, cached = TRUE))
  }

  rec <- recipe(as.formula(paste(target, '~ .')), data = df) %>%
    step_nzv(all_predictors()) %>%
    step_impute_median(all_numeric_predictors()) %>%
    step_impute_mode(all_nominal_predictors()) %>%
    step_dummy(all_nominal_predictors(), one_hot = TRUE) %>%
    step_normalize(all_numeric_predictors())

  if(model_type == 'logistic') {
    spec <- logistic_reg() %>% set_engine('glm') %>% set_mode('classification')
  } else if(model_type == 'rf') {
    spec <- rand_forest(trees = 500) %>% set_engine('ranger') %>% set_mode('classification')
  } else if(model_type == 'xgb') {
    spec <- boost_tree(trees = 200, tree_depth = 6, learn_rate = 0.1) %>% set_engine('xgboost') %>% set_mode('classification')
  } else if(model_type == 'lgbm') {
    spec <- boost_tree(trees = 200, tree_depth = 6, learn_rate = 0.1) %>% set_engine('lightgbm') %>% set_mode('classification')
  } else {
    stop('Unknown model_type')
  }

  wf <- workflow() %>% add_recipe(rec) %>% add_model(spec)

  set.seed(seed)
  split <- initial_split(df, strata = target, prop = 0.8)
  train <- training(split)
  test <- testing(split)

  fitted <- fit(wf, data = train)
  preds <- predict(fitted, test, type = 'prob') %>% bind_cols(test %>% select(all_of(target)))
  auc_val <- tryCatch({ yardstick::roc_auc_vec(truth = preds[[target]], estimate = preds[['.pred_1']]) }, error = function(e) NA)
  tmp <- preds %>% arrange(desc(.pred_1)) %>% mutate(good = 1 - as.numeric(.data[[target]]), bad = as.numeric(.data[[target]])) %>%
    mutate(cum_good = cumsum(good)/sum(good), cum_bad = cumsum(bad)/sum(bad), ks = abs(cum_bad - cum_good))
  ks_val <- max(tmp$ks, na.rm = TRUE)
  metrics <- list(auc = as.numeric(auc_val), ks = ks_val)

  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(fitted, file.path(outdir, 'workflow.rds'))
  saveRDS(metrics, file.path(outdir, 'metrics.rds'))

  list(path = outdir, workflow = fitted, metrics = metrics, cached = FALSE)
}
