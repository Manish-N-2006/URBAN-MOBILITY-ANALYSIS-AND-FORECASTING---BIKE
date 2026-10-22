# tests/testthat.R
# Test runner for Urban Bike Taxi Demand Analysis and Forecasting

library(testthat)

cat("==================================================\n")
cat("RUNNING AUTOMATED UNIT TESTS\n")
cat("==================================================\n\n")

testthat::test_dir("tests/testthat")
