# tests/testthat/test-risk-score.R
library(testthat)

source("../../R/config.R")
source("../../R/risk_scoring.R")

test_that("calculate_zone_risk_score adheres to bounds [0, 100]", {
  # Extreme high demand, zero drivers -> max shortage
  crit_res <- calculate_zone_risk_score(
    forecast_demand = 500,
    virtual_driver_count = 0,
    rides_per_driver = 8,
    recent_growth_rate = 1.0,
    historical_cv = 1.0
  )
  expect_true(crit_res$risk_score >= 0 && crit_res$risk_score <= 100)
  expect_equal(crit_res$risk_tier, "Critical Shortage")
  
  # Zero demand, plenty of drivers -> min risk
  zero_res <- calculate_zone_risk_score(
    forecast_demand = 0,
    virtual_driver_count = 50,
    rides_per_driver = 8,
    recent_growth_rate = -0.5,
    historical_cv = 0.0
  )
  expect_true(zero_res$risk_score >= 0 && zero_res$risk_score <= 100)
  expect_equal(zero_res$risk_tier, "Low Risk")
})

test_that("calculate_zone_risk_score correctly computes shortage ratio and component contributions", {
  # Forecast = 100, Capacity = 50 (10 drivers * 5 rides/driver) -> Shortage = 50 -> shortage_ratio = 0.5
  # Growth = 0 (clamped 0 -> norm = 0.5 / 1.5 = 0.3333)
  # Volatility CV = 0.3 (norm = 0.3 / 1.2 = 0.25)
  res <- calculate_zone_risk_score(
    forecast_demand = 100,
    virtual_driver_count = 10,
    rides_per_driver = 5,
    recent_growth_rate = 0.0,
    historical_cv = 0.30
  )
  
  expect_equal(res$estimated_capacity, 50)
  expect_equal(res$capacity_shortage, 50)
  expect_equal(res$shortage_ratio, 0.5)
  
  # Shortage contribution = 100 * 0.70 * 0.5 = 35.0
  expect_equal(res$contributions$shortage_points, 35.0)
  
  # Total score equals sum of components
  expected_sum <- res$contributions$shortage_points + res$contributions$growth_points + res$contributions$volatility_points
  expect_equal(res$risk_score, round(expected_sum, 1))
})

test_that("calculate_zone_risk_score gracefully handles missing or invalid inputs", {
  na_res <- calculate_zone_risk_score(forecast_demand = NA, virtual_driver_count = 10)
  expect_false(na_res$is_available)
  expect_true(is.na(na_res$risk_score))
  expect_equal(na_res$risk_tier, "Unavailable")
  
  neg_res <- calculate_zone_risk_score(forecast_demand = -10, virtual_driver_count = 10)
  expect_false(neg_res$is_available)
})
