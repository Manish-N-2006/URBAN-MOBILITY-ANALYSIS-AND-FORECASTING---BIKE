# tests/testthat/test-data-cleaning.R
library(testthat)

source("../../R/config.R")
source("../../R/data_cleaning.R")

test_that("standardize_zone_name cleans street suffixes cleanly", {
  expect_equal(standardize_zone_name("Basavanagudi 3rd Block"), "Basavanagudi")
  expect_equal(standardize_zone_name("Balagere 1st Stage"), "Balagere")
  expect_equal(standardize_zone_name("Kothanur Landing"), "Kothanur")
  expect_equal(standardize_zone_name("HSR Layout Area"), "HSR Layout")
  expect_equal(standardize_zone_name("Banaswadi Square"), "Banaswadi")
  expect_equal(standardize_zone_name(""), "Unknown Zone")
  expect_equal(standardize_zone_name(NULL), character(0))
})

test_that("clean_rides_data handles duplicates and invalid records", {
  raw_mock <- data.frame(
    services = c("bike", "auto", "bike", "bike"),
    date = c("2024-07-01", "2024-07-01", "2024-07-01", "invalid_date"),
    time = c("09:15:00.000", "14:30:00.000", "09:15:00.000", "09:15:00.000"),
    ride_status = c("completed", "cancelled", "completed", "completed"),
    source = c("Indiranagar 1st Stage", "Koramangala 4th Block", "Indiranagar 1st Stage", "HSR Layout"),
    destination = c("Whitefield Hub", "BTM Layout", "Whitefield Hub", "Whitefield"),
    duration = c(30, 45, 30, 20),
    ride_id = c("R001", "R002", "R001", "R003"), # R001 is duplicated
    distance = c(12.5, 8.0, 12.5, 5.0),
    ride_charge = c(150, NA, 150, 80),
    misc_charge = c(10, NA, 10, 5),
    total_fare = c(160, NA, 160, 85),
    payment_method = c("GPay", NA, "GPay", "Cash"),
    stringsAsFactors = FALSE
  )
  
  res <- clean_rides_data(raw_mock)
  
  # Duplicated R001 should be removed
  expect_false("R003" %in% res$ride_id) # invalid date dropped
  expect_equal(nrow(res), 2)
  expect_equal(res$ride_id, c("R001", "R002"))
  
  # Status preserved
  expect_equal(res$is_completed, c(TRUE, FALSE))
  expect_equal(res$is_cancelled, c(FALSE, TRUE))
  
  # Check zone standardization
  expect_equal(res$pickup_zone, c("Indiranagar", "Koramangala"))
})

test_that("clean_rides_data validates non-positive distance and duration", {
  bad_physics <- data.frame(
    services = c("bike", "bike"),
    date = c("2024-07-01", "2024-07-01"),
    time = c("10:00:00.000", "10:00:00.000"),
    ride_status = c("completed", "completed"),
    source = c("Zone A", "Zone B"),
    destination = c("Zone C", "Zone D"),
    duration = c(0, 25), # 0 duration invalid
    ride_id = c("R1", "R2"),
    distance = c(10, -5), # negative distance invalid
    ride_charge = c(100, 100),
    misc_charge = c(10, 10),
    total_fare = c(110, 110),
    payment_method = c("Cash", "Cash"),
    stringsAsFactors = FALSE
  )
  
  res <- clean_rides_data(bad_physics)
  expect_equal(nrow(res), 0)
})
