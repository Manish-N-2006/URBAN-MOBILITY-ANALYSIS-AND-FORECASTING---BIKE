# tests/testthat/test-feature-engineering.R
library(testthat)

source("../../R/config.R")
source("../../R/data_cleaning.R")
source("../../R/feature_engineering.R")

test_that("engineer_ride_features correctly generates temporal and economic attributes", {
  df_sample <- data.frame(
    services = c("bike", "auto"),
    date = c("2024-07-06", "2024-07-08"), # 2024-07-06 is Saturday, 2024-07-08 is Monday
    time = c("08:30:00.000", "18:45:00.000"),
    ride_status = c("completed", "completed"),
    source = c("Indiranagar", "Koramangala"),
    destination = c("Whitefield", "HSR Layout"),
    duration = c(30, 40),
    ride_id = c("R1", "R2"),
    distance = c(15.0, 10.0),
    ride_charge = c(150, 120),
    misc_charge = c(10, 10),
    total_fare = c(160, 130),
    payment_method = c("GPay", "Cash"),
    ride_date = as.Date(c("2024-07-06", "2024-07-08")),
    ride_hour = c(8L, 18L),
    is_completed = c(TRUE, TRUE),
    is_cancelled = c(FALSE, FALSE),
    speed_kmh = c(30.0, 15.0),
    pickup_zone = c("Indiranagar", "Koramangala"),
    dropoff_zone = c("Whitefield", "HSR Layout"),
    is_bike_service = c(TRUE, FALSE),
    service_group = c("Bike Taxi", "Auto"),
    stringsAsFactors = FALSE
  )
  
  res <- engineer_ride_features(df_sample)
  
  expect_equal(as.character(res$ride_weekday), c("Saturday", "Monday"))
  expect_equal(res$is_weekend, c(TRUE, FALSE))
  expect_equal(res$day_type, c("Weekend", "Weekday"))
  expect_equal(as.character(res$time_period), c("Morning Peak (06-10)", "Evening Peak (16-21)"))
  expect_equal(res$route_pair, c("Indiranagar -> Whitefield", "Koramangala -> HSR Layout"))
  expect_equal(res$fare_per_km, c(10.67, 13.00))
})

test_that("build_zone_daily_panel generates continuous sequences with zero imputation", {
  # Two days of data with missing day in between for Zone B
  df_mock <- data.frame(
    ride_date = as.Date(c("2024-07-01", "2024-07-02", "2024-07-01")),
    pickup_zone = c("Zone A", "Zone A", "Zone B"),
    is_completed = c(TRUE, TRUE, TRUE),
    is_cancelled = c(FALSE, FALSE, FALSE),
    total_fare = c(100, 150, 200),
    distance = c(10, 12, 15),
    duration = c(20, 25, 30),
    ride_weekday = factor(c("Monday", "Tuesday", "Monday"), levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")),
    services = c("bike", "bike", "bike"),
    stringsAsFactors = FALSE
  )
  
  panel <- build_zone_daily_panel(df_mock, min_zone_total_rides = 1)
  
  # Both Zone A and Zone B should have rows for both 2024-07-01 and 2024-07-02
  expect_equal(nrow(panel), 4) # 2 zones x 2 dates
  
  # Zone B on 2024-07-02 should be imputed 0
  zone_b_day2 <- panel %>% filter(pickup_zone == "Zone B", ride_date == as.Date("2024-07-02"))
  expect_equal(zone_b_day2$demand_requests, 0L)
  expect_equal(zone_b_day2$completed_rides, 0L)
})
