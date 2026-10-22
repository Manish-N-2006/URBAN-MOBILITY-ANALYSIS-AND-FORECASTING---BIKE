# R/forecasting.R
# Time-Series Demand Forecasting with Chronological Validation and Baselines

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(forecast)
  library(lubridate)
})

#' Extract a continuous daily time series for a specific zone
#' @param panel Complete daily panel from build_zone_daily_panel()
#' @param target_zone Selected pickup zone name
#' @return Named list with date vector and ts object (freq = 7)
prepare_zone_timeseries <- function(panel, target_zone) {
  zone_df <- panel %>%
    filter(pickup_zone == target_zone) %>%
    arrange(ride_date)
  
  if (nrow(zone_df) == 0) {
    return(NULL)
  }
  
  start_date <- min(zone_df$ride_date)
  y <- zone_df$demand_requests
  
  # Frequency 7 for weekly seasonality
  ts_obj <- stats::ts(y, frequency = 7)
  
  list(
    zone = target_zone,
    dates = zone_df$ride_date,
    demand = y,
    ts_data = ts_obj,
    total_days = length(y),
    total_rides = sum(y),
    mean_daily_demand = round(mean(y), 2)
  )
}

#' Perform Chronological Train/Validation Split and Model Evaluation
#' Compares a Baseline model (Seasonal Naive / Mean) with Auto ARIMA
#' @param ts_info List returned by prepare_zone_timeseries()
#' @param test_days Number of holdout days for validation (default 7 days)
#' @return List with fitted models, predictions, and evaluation metrics (MAE, RMSE)
evaluate_models_chronological <- function(ts_info, test_days = 7) {
  if (is.null(ts_info) || ts_info$total_days <= (test_days + 7)) {
    return(list(
      is_valid = FALSE,
      reason = "Insufficient historical observations for chronological splitting"
    ))
  }
  
  n <- ts_info$total_days
  train_len <- n - test_days
  
  y <- ts_info$demand
  train_y <- y[1:train_len]
  test_y <- y[(train_len + 1):n]
  test_dates <- ts_info$dates[(train_len + 1):n]
  
  train_ts <- stats::ts(train_y, frequency = 7)
  
  # 1. Baseline Model (Seasonal Naive or Naive fallback)
  baseline_fit <- tryCatch({
    forecast::snaive(train_ts, h = test_days)
  }, error = function(e) {
    forecast::naive(train_ts, h = test_days)
  })
  
  baseline_pred <- pmax(0, as.numeric(baseline_fit$mean))
  
  # 2. Advanced Predictive Model (Auto ARIMA with weekly seasonality)
  arima_fit <- tryCatch({
    fit <- forecast::auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE, approximation = FALSE)
    forecast::forecast(fit, h = test_days)
  }, error = function(e) {
    # Fallback to ETS if ARIMA fails
    fit <- forecast::ets(train_ts)
    forecast::forecast(fit, h = test_days)
  })
  
  arima_pred <- pmax(0, as.numeric(arima_fit$mean))
  
  # Metrics function
  calc_metrics <- function(actual, predicted) {
    errors <- actual - predicted
    mae <- mean(abs(errors))
    rmse <- sqrt(mean(errors^2))
    
    # Non-zero actuals for MAPE
    non_zero <- actual > 0
    mape <- if (sum(non_zero) > 0) mean(abs(errors[non_zero] / actual[non_zero])) * 100 else NA_real_
    
    list(
      MAE = round(mae, 2),
      RMSE = round(rmse, 2),
      MAPE_pct = if (is.na(mape)) NA_real_ else round(mape, 1)
    )
  }
  
  metrics_baseline <- calc_metrics(test_y, baseline_pred)
  metrics_arima <- calc_metrics(test_y, arima_pred)
  
  comparison_table <- data.frame(
    Model = c("Seasonal Naive (Baseline)", "Auto-ARIMA (Adaptive)"),
    MAE = c(metrics_baseline$MAE, metrics_arima$MAE),
    RMSE = c(metrics_baseline$RMSE, metrics_arima$RMSE),
    MAPE_Pct = c(metrics_baseline$MAPE_pct, metrics_arima$MAPE_pct),
    stringsAsFactors = FALSE
  )
  
  eval_data <- data.frame(
    Date = test_dates,
    Actual = test_y,
    Baseline_Forecast = round(baseline_pred, 1),
    Model_Forecast = round(arima_pred, 1),
    stringsAsFactors = FALSE
  )
  
  list(
    is_valid = TRUE,
    test_days = test_days,
    train_days = train_len,
    eval_data = eval_data,
    metrics_baseline = metrics_baseline,
    metrics_arima = metrics_arima,
    comparison_table = comparison_table,
    arima_order = if (!is.null(arima_fit$model)) arimaorder(arima_fit$model) else "ETS"
  )
}

#' Generate Out-of-Sample Near-Term Forecast (Next 7 Days)
#' Trains on the entire historical time series
#' @param ts_info Output from prepare_zone_timeseries()
#' @param horizon Number of days ahead (default 7)
#' @return Formatted forecast list with prediction intervals and dates
generate_zone_forecast <- function(ts_info, horizon = 7) {
  if (is.null(ts_info)) {
    return(list(is_valid = FALSE, reason = "No data available for selected zone"))
  }
  
  # Check if series is too short or sparse
  if (ts_info$total_days < CONFIG$forecast$min_history_days || ts_info$total_rides < 15) {
    # Fallback to simple historical mean
    mean_val <- max(1, round(ts_info$mean_daily_demand))
    future_dates <- seq.Date(max(ts_info$dates) + 1, by = "day", length.out = horizon)
    
    df_fc <- data.frame(
      Date = future_dates,
      Forecast = rep(mean_val, horizon),
      Lower_80 = pmax(0, round(mean_val * 0.7)),
      Upper_80 = round(mean_val * 1.3),
      Lower_95 = pmax(0, round(mean_val * 0.5)),
      Upper_95 = round(mean_val * 1.5),
      stringsAsFactors = FALSE
    )
    
    return(list(
      is_valid = TRUE,
      is_fallback = TRUE,
      model_type = "Historical Mean Baseline (Sparse Data Fallback)",
      horizon = horizon,
      forecast_table = df_fc,
      historical_data = data.frame(Date = ts_info$dates, Demand = ts_info$demand),
      total_predicted_demand = sum(df_fc$Forecast),
      avg_predicted_daily = mean(df_fc$Forecast)
    ))
  }
  
  # Fit full model
  ts_full <- ts_info$ts_data
  model_fit <- tryCatch({
    forecast::auto.arima(ts_full, seasonal = TRUE, stepwise = TRUE)
  }, error = function(e) {
    forecast::ets(ts_full)
  })
  
  fc_obj <- forecast::forecast(model_fit, h = horizon, level = c(80, 95))
  
  future_dates <- seq.Date(max(ts_info$dates) + 1, by = "day", length.out = horizon)
  
  df_fc <- data.frame(
    Date = future_dates,
    Forecast = pmax(0, round(as.numeric(fc_obj$mean), 1)),
    Lower_80 = pmax(0, round(as.numeric(fc_obj$lower[, 1]), 1)),
    Upper_80 = pmax(0, round(as.numeric(fc_obj$upper[, 1]), 1)),
    Lower_95 = pmax(0, round(as.numeric(fc_obj$lower[, 2]), 1)),
    Upper_95 = round(as.numeric(fc_obj$upper[, 2]), 1),
    stringsAsFactors = FALSE
  )
  
  model_desc <- if (inherits(model_fit, "Arima")) {
    paste0("Seasonal ARIMA", paste(arimaorder(model_fit), collapse = ","))
  } else {
    "Exponential Smoothing (ETS)"
  }
  
  list(
    is_valid = TRUE,
    is_fallback = FALSE,
    model_type = model_desc,
    horizon = horizon,
    forecast_table = df_fc,
    historical_data = data.frame(Date = ts_info$dates, Demand = ts_info$demand),
    total_predicted_demand = sum(df_fc$Forecast),
    avg_predicted_daily = round(mean(df_fc$Forecast), 1)
  )
}
