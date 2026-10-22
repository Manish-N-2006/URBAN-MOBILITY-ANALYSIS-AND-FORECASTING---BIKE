# tests/testthat/test-simulator.R
library(testthat)

source("../../R/config.R")
source("../../R/risk_scoring.R")
source("../../R/what_if_simulator.R")

test_that("validate_simulator_inputs prevents illegal configurations", {
  # Donor same as recipient
  res_same <- validate_simulator_inputs("Zone A", "Zone A", 40, 20, 10, 8)
  expect_false(res_same$is_valid)
  
  # Transfer exceeds donor supply
  res_excess <- validate_simulator_inputs("Donor", "Recipient", 15, 20, 20, 8)
  expect_false(res_excess$is_valid)
  
  # Negative drivers
  res_neg <- validate_simulator_inputs("Donor", "Recipient", -5, 20, 5, 8)
  expect_false(res_neg$is_valid)
  
  # Non-positive rides per driver
  res_bad_cap <- validate_simulator_inputs("Donor", "Recipient", 30, 20, 5, 0)
  expect_false(res_bad_cap$is_valid)
})

test_that("run_what_if_simulation strictly preserves total virtual driver supply", {
  donor_initial <- 45
  recipient_initial <- 20
  transfer_amount <- 15
  
  sim <- run_what_if_simulation(
    donor_zone = "Koramangala",
    recipient_zone = "Indiranagar",
    donor_forecast = 120,
    recipient_forecast = 280,
    donor_drivers = donor_initial,
    recipient_drivers = recipient_initial,
    transfer = transfer_amount,
    rides_per_driver = 8
  )
  
  expect_true(sim$is_valid)
  
  # Invariant: Total drivers before == Total drivers after
  total_before <- donor_initial + recipient_initial
  total_after <- sim$donor$after$virtual_driver_count + sim$recipient$after$virtual_driver_count
  expect_equal(total_before, total_after)
  expect_equal(total_after, sim$total_drivers_conserved)
  
  # Check individual balances
  expect_equal(sim$donor$after$virtual_driver_count, donor_initial - transfer_amount)
  expect_equal(sim$recipient$after$virtual_driver_count, recipient_initial + transfer_amount)
})

test_that("run_what_if_simulation reduces recipient risk and increases recipient capacity", {
  sim <- run_what_if_simulation(
    donor_zone = "Begur",
    recipient_zone = "Whitefield",
    donor_forecast = 80,
    recipient_forecast = 350,
    donor_drivers = 50,
    recipient_drivers = 10,
    transfer = 20,
    rides_per_driver = 8
  )
  
  # Recipient gets 20 more drivers -> 160 more ride capacity
  expect_equal(sim$recipient$delta_capacity, 160)
  
  # Recipient risk should decrease
  expect_true(sim$recipient$after$risk_score < sim$recipient$before$risk_score)
  expect_true(sim$recip_risk_reduction > 0)
  
  # Recipient shortage should decrease
  expect_true(sim$recipient$after$capacity_shortage < sim$recipient$before$capacity_shortage)
})
