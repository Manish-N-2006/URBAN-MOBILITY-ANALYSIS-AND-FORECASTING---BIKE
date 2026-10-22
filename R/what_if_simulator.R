# R/what_if_simulator.R
# What-If Driver Allocation Simulator & Optimization Engine
# Implements conservation-preserving redistribution between donor and recipient zones

suppressPackageStartupMessages({
  library(dplyr)
})

#' Validate simulator inputs and constraints
#' @return List with is_valid logical and error message if invalid
validate_simulator_inputs <- function(
  donor_zone,
  recipient_zone,
  donor_drivers_initial,
  recipient_drivers_initial,
  transfer_drivers,
  rides_per_driver
) {
  if (is.null(donor_zone) || is.null(recipient_zone) || donor_zone == "" || recipient_zone == "") {
    return(list(is_valid = FALSE, message = "Please select both a donor zone and a recipient zone."))
  }
  
  if (identical(donor_zone, recipient_zone)) {
    return(list(is_valid = FALSE, message = "Donor and Recipient zones must be different. A zone cannot transfer drivers to itself."))
  }
  
  if (is.na(donor_drivers_initial) || donor_drivers_initial < 0) {
    return(list(is_valid = FALSE, message = "Donor virtual driver count cannot be negative."))
  }
  
  if (is.na(recipient_drivers_initial) || recipient_drivers_initial < 0) {
    return(list(is_valid = FALSE, message = "Recipient virtual driver count cannot be negative."))
  }
  
  if (is.na(transfer_drivers) || transfer_drivers < 0) {
    return(list(is_valid = FALSE, message = "Transfer driver count cannot be negative."))
  }
  
  if (transfer_drivers > donor_drivers_initial) {
    return(list(
      is_valid = FALSE,
      message = sprintf(
        "Cannot transfer %d drivers: donor zone only has %d virtual drivers available.",
        as.integer(transfer_drivers), as.integer(donor_drivers_initial)
      )
    ))
  }
  
  if (is.na(rides_per_driver) || rides_per_driver <= 0) {
    return(list(is_valid = FALSE, message = "Rides served per driver must be greater than zero."))
  }
  
  return(list(is_valid = TRUE, message = "Inputs valid"))
}

#' Run What-If Driver Reallocation Simulation
#' Strictly preserves total virtual driver count across zones
#' @param donor_zone Name of donor zone
#' @param recipient_zone Name of recipient zone
#' @param donor_forecast Forecast demand for donor zone
#' @param recipient_forecast Forecast demand for recipient zone
#' @param donor_drivers Initial driver supply in donor zone
#' @param recipient_drivers Initial driver supply in recipient zone
#' @param transfer Number of drivers to reallocate from donor to recipient
#' @param rides_per_driver Number of rides a driver can serve in interval
#' @param donor_growth Historical growth rate for donor
#' @param recipient_growth Historical growth rate for recipient
#' @param donor_cv Historical volatility for donor
#' @param recipient_cv Historical volatility for recipient
#' @return Comprehensive simulation results list
run_what_if_simulation <- function(
  donor_zone,
  recipient_zone,
  donor_forecast,
  recipient_forecast,
  donor_drivers = CONFIG$sim_defaults$default_donor_drivers,
  recipient_drivers = CONFIG$sim_defaults$default_recipient_drivers,
  transfer = CONFIG$sim_defaults$default_transfer,
  rides_per_driver = CONFIG$sim_defaults$rides_per_driver_daily,
  donor_growth = 0.0,
  recipient_growth = 0.0,
  donor_cv = 0.25,
  recipient_cv = 0.25
) {
  # 1. Validate inputs
  val <- validate_simulator_inputs(
    donor_zone, recipient_zone, donor_drivers, recipient_drivers, transfer, rides_per_driver
  )
  if (!val$is_valid) {
    return(list(is_valid = FALSE, error_message = val$message))
  }
  
  # Ensure integer drivers
  donor_drivers_pre <- as.integer(donor_drivers)
  recipient_drivers_pre <- as.integer(recipient_drivers)
  transfer_qty <- as.integer(transfer)
  
  # 2. Reallocation calculation
  donor_drivers_post <- donor_drivers_pre - transfer_qty
  recipient_drivers_post <- recipient_drivers_pre + transfer_qty
  
  # 3. Supply Conservation Check
  total_before <- donor_drivers_pre + recipient_drivers_pre
  total_after <- donor_drivers_post + recipient_drivers_post
  stopifnot(total_before == total_after) # Invariant assertion
  
  # 4. Calculate Risk Scores - BEFORE
  risk_donor_pre <- calculate_zone_risk_score(
    forecast_demand = donor_forecast,
    virtual_driver_count = donor_drivers_pre,
    rides_per_driver = rides_per_driver,
    recent_growth_rate = donor_growth,
    historical_cv = donor_cv
  )
  
  risk_recip_pre <- calculate_zone_risk_score(
    forecast_demand = recipient_forecast,
    virtual_driver_count = recipient_drivers_pre,
    rides_per_driver = rides_per_driver,
    recent_growth_rate = recipient_growth,
    historical_cv = recipient_cv
  )
  
  # 5. Calculate Risk Scores - AFTER
  risk_donor_post <- calculate_zone_risk_score(
    forecast_demand = donor_forecast,
    virtual_driver_count = donor_drivers_post,
    rides_per_driver = rides_per_driver,
    recent_growth_rate = donor_growth,
    historical_cv = donor_cv
  )
  
  risk_recip_post <- calculate_zone_risk_score(
    forecast_demand = recipient_forecast,
    virtual_driver_count = recipient_drivers_post,
    rides_per_driver = rides_per_driver,
    recent_growth_rate = recipient_growth,
    historical_cv = recipient_cv
  )
  
  # 6. Comparative System Metrics
  total_shortage_pre <- risk_donor_pre$capacity_shortage + risk_recip_pre$capacity_shortage
  total_shortage_post <- risk_donor_post$capacity_shortage + risk_recip_post$capacity_shortage
  net_shortage_reduction <- total_shortage_pre - total_shortage_post
  
  recip_risk_reduction <- risk_recip_pre$risk_score - risk_recip_post$risk_score
  donor_risk_increase <- risk_donor_post$risk_score - risk_donor_pre$risk_score
  
  # 7. Comparison Table
  comparison_table <- data.frame(
    Metric = c(
      "Virtual Driver Supply",
      "Estimated Service Capacity (rides)",
      "Forecast Daily Demand (rides)",
      "Unmet Shortage (rides)",
      "Demand Pressure (Demand/Cap)",
      "Risk Score (0-100)",
      "Risk Tier"
    ),
    Donor_Before = c(
      as.character(donor_drivers_pre),
      as.character(round(risk_donor_pre$estimated_capacity, 1)),
      as.character(round(donor_forecast, 1)),
      as.character(round(risk_donor_pre$capacity_shortage, 1)),
      sprintf("%.2fx", risk_donor_pre$demand_pressure),
      sprintf("%.1f", risk_donor_pre$risk_score),
      risk_donor_pre$risk_tier
    ),
    Donor_After = c(
      as.character(donor_drivers_post),
      as.character(round(risk_donor_post$estimated_capacity, 1)),
      as.character(round(donor_forecast, 1)),
      as.character(round(risk_donor_post$capacity_shortage, 1)),
      sprintf("%.2fx", risk_donor_post$demand_pressure),
      sprintf("%.1f", risk_donor_post$risk_score),
      risk_donor_post$risk_tier
    ),
    Recipient_Before = c(
      as.character(recipient_drivers_pre),
      as.character(round(risk_recip_pre$estimated_capacity, 1)),
      as.character(round(recipient_forecast, 1)),
      as.character(round(risk_recip_pre$capacity_shortage, 1)),
      sprintf("%.2fx", risk_recip_pre$demand_pressure),
      sprintf("%.1f", risk_recip_pre$risk_score),
      risk_recip_pre$risk_tier
    ),
    Recipient_After = c(
      as.character(recipient_drivers_post),
      as.character(round(risk_recip_post$estimated_capacity, 1)),
      as.character(round(recipient_forecast, 1)),
      as.character(round(risk_recip_post$capacity_shortage, 1)),
      sprintf("%.2fx", risk_recip_post$demand_pressure),
      sprintf("%.1f", risk_recip_post$risk_score),
      risk_recip_post$risk_tier
    ),
    stringsAsFactors = FALSE
  )
  
  list(
    is_valid = TRUE,
    donor_zone = donor_zone,
    recipient_zone = recipient_zone,
    transfer_amount = transfer_qty,
    rides_per_driver = rides_per_driver,
    total_drivers_conserved = total_after,
    net_shortage_reduction = round(net_shortage_reduction, 1),
    recip_risk_reduction = round(recip_risk_reduction, 1),
    donor_risk_increase = round(donor_risk_increase, 1),
    donor = list(
      before = risk_donor_pre,
      after = risk_donor_post,
      delta_drivers = -transfer_qty,
      delta_capacity = -(transfer_qty * rides_per_driver),
      delta_risk = donor_risk_increase
    ),
    recipient = list(
      before = risk_recip_pre,
      after = risk_recip_post,
      delta_drivers = transfer_qty,
      delta_capacity = transfer_qty * rides_per_driver,
      delta_risk = -recip_risk_reduction
    ),
    comparison_table = comparison_table,
    disclaimer = "SIMULATION ONLY: Assumes perfect driver compliance and zero transit attrition. This does not represent observed Rapido fleet operations."
  )
}
