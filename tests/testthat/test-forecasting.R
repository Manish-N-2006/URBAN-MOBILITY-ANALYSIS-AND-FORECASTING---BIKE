# tests/testthat/test-forecasting.R
library(testthat)

source("../../R/config.R")
source("../../R/forecasting.R")

test_that("prepare_zone_timeseries formats valid ts object", {
  dates <- seq.Date(as.Date("2024-06-01"), by = "day", length.out = 30)
  panel_mock <- data.frame(
    pickup_zone = "Zone A",
    ride_date = dates,
    demand_requests = rpois(30, lambda = 25),
    stringsAsFactors = FALSE
  )
  
  ts_info <- prepare_zone_timeseries(panel_mock, "Zone A")
  expect_equal(ts_info$zone, "Zone A")
  expect_equal(ts_info$total_days, 30)
  expect_equal(stats::frequency(ts_info$ts_data), 7)
})

test_that("evaluate_models_chronological evaluates models on held-out test data", {
  # 40 days of synthetic data
  dates <- seq.Date(as.Date("2024-06-01"), by = "day", length.out = 40)
  # Simple weekly pattern + noise
  y <- round(20 + 10 * sin(2 * pi * seq_along(dates) / 7) + rnorm(40, sd = 2))
  y <- pmax(1, y)
  
  panel_mock <- data.frame(
    pickup_zone = "Zone Eval",
    ride_date = dates,
    demand_requests = y,
    stringsAsFactors = FALSE
  )
  
  ts_info <- prepare_zone_timeseries(panel_mock, "Zone Eval")
  eval_res <- evaluate_models_chronological(ts_info, test_days = 7)
  
  expect_true(eval_res$is_valid)
  expect_equal(nrow(eval_res$eval_data), 7)
  expect_true(eval_res$metrics_baseline$MAE >= 0)
  expect_true(eval_res$metrics_arima$RMSE >= 0)
  expect_equal(nrow(eval_res$comparison_table), 2)
})

test_that("generate_zone_forecast produces non-negative 7-day intervals", {
  dates <- seq.Date(as.Date("2024-06-01"), by = "day", length.out = 35)
  y <- round(15 + 5 * cos(2 * pi * seq_along(dates) / 7))
  
  panel_mock <- data.frame(
    pickup_zone = "Zone FC",
    ride_date = dates,
    demand_requests = y,
    stringsAsFactors = FALSE
  )
  
  ts_info <- prepare_zone_timeseries(panel_mock, "Zone FC")
  fc <- generate_zone_forecast(ts_info, horizon = 7)
  
  expect_true(fc$is_valid)
  expect_equal(nrow(fc$forecast_table), 7)
  
  # All forecasts and lower bounds must be non-negative
  expect_true(all(fc$forecast_table$Forecast >= 0))
  expect_true(all(fc$forecast_table$Lower_80 >= 0))
  expect_true(all(fc$forecast_table$Lower_95 >= 0))
  
  # Upper bound must be >= lower bound
  expect_true(all(fc$forecast_table$Upper_95 >= fc$forecast_table$Lower_95))
})

test_that("generate_zone_forecast triggers fallback on sparse series", {
  dates <- seq.Date(as.Date("2024-06-01"), by = "day", length.out = 10) # under 14 days
  panel_sparse <- data.frame(
    pickup_zone = "Zone Sparse",
    ride_date = dates,
    demand_requests = rep(1, 10),
    stringsAsFactors = FALSE
  )
  
  ts_info <- prepare_zone_timeseries(panel_sparse, "Zone Sparse")
  fc <- generate_zone_forecast(ts_info, horizon = 7)
  
  expect_true(fc$is_valid)
  expect_true(fc$is_fallback)
  expect_equal(nrow(fc$forecast_table), 7)
})
