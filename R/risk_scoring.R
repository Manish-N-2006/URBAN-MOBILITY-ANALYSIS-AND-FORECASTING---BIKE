# R/risk_scoring.R
# Interpretable Zone Demand Risk Scoring Engine (0 to 100)

suppressPackageStartupMessages({
  library(dplyr)
})

#' Calculate Interpretable Scenario-Based Zone Demand Risk Score
#' @param forecast_demand Forecast daily demand requests (numeric)
#' @param virtual_driver_count Assumed number of virtual drivers active in zone
#' @param rides_per_driver Assumed capacity of completed rides per driver per day
#' @param recent_growth_rate Demand growth rate (e.g. +0.20 for +20%)
#' @param historical_cv Historical coefficient of variation (sd / mean)
#' @param weights List of weights for shortage, growth, volatility (default 0.70, 0.20, 0.10)
#' @return Named list with final risk_score, tier, components, and narrative explanation
calculate_zone_risk_score <- function(
  forecast_demand,
  virtual_driver_count,
  rides_per_driver = CONFIG$sim_defaults$rides_per_driver_daily,
  recent_growth_rate = 0.0,
  historical_cv = 0.25,
  weights = CONFIG$risk_weights
) {
  # 1. Validation & Availability check
  if (is.na(forecast_demand) || is.null(forecast_demand) || forecast_demand < 0) {
    return(list(
      is_available = FALSE,
      reason = "Forecast demand is unavailable or invalid",
      risk_score = NA_real_,
      risk_tier = "Unavailable",
      badge_color = "#94a3b8"
    ))
  }
  
  if (is.na(virtual_driver_count) || virtual_driver_count < 0) {
    virtual_driver_count <- 0
  }
  
  if (is.na(rides_per_driver) || rides_per_driver <= 0) {
    rides_per_driver <- 1
  }
  
  # 2. Virtual Capacity & Shortage Calculation
  estimated_capacity <- as.numeric(virtual_driver_count) * as.numeric(rides_per_driver)
  shortage <- max(forecast_demand - estimated_capacity, 0)
  shortage_ratio <- shortage / max(forecast_demand, 1)
  shortage_ratio <- max(0, min(1, shortage_ratio))
  
  # 3. Normalized Growth Component (bounded [0, 1])
  # Assumes typical growth rate between -50% (-0.5) and +100% (+1.0)
  clamped_growth <- max(-0.5, min(1.0, as.numeric(recent_growth_rate)))
  normalized_growth <- (clamped_growth + 0.5) / 1.5
  normalized_growth <- max(0, min(1, normalized_growth))
  
  # 4. Normalized Volatility Component (bounded [0, 1])
  # Coefficient of Variation (sd / mean), typically 0.05 to 1.0 in daily demand
  clamped_cv <- max(0.0, min(1.2, as.numeric(historical_cv)))
  normalized_volatility <- clamped_cv / 1.2
  normalized_volatility <- max(0, min(1, normalized_volatility))
  
  # 5. Composite Weighted Score (0 to 100)
  w_shortage <- weights$shortage
  w_growth <- weights$growth
  w_volatility <- weights$volatility
  
  # Ensure weights normalize to 1.0
  total_w <- w_shortage + w_growth + w_volatility
  w_shortage <- w_shortage / total_w
  w_growth <- w_growth / total_w
  w_volatility <- w_volatility / total_w
  
  raw_score <- 100 * (
    w_shortage * shortage_ratio +
    w_growth * normalized_growth +
    w_volatility * normalized_volatility
  )
  
  # Strict boundary enforcement: [0, 100]
  final_score <- round(max(0, min(100, raw_score)), 1)
  
  # Component point contributions
  contrib_shortage <- round(100 * w_shortage * shortage_ratio, 1)
  contrib_growth <- round(100 * w_growth * normalized_growth, 1)
  contrib_volatility <- round(100 * w_volatility * normalized_volatility, 1)
  
  # 6. Risk Tier Assignment
  tier_info <- if (final_score <= 30) {
    list(name = "Low Risk", color = "#22c55e", desc = "Capacity is sufficient to absorb predicted demand with low operational pressure.")
  } else if (final_score <= 60) {
    list(name = "Moderate Risk", color = "#eab308", desc = "Moderate strain detected; capacity buffers are narrow during peak intervals.")
  } else if (final_score <= 80) {
    list(name = "High Risk", color = "#f97316", desc = "Significant driver shortage expected; high surge pricing or cancellations likely.")
  } else {
    list(name = "Critical Shortage", color = "#ef4444", desc = "Severe capacity deficit; acute unmet demand requiring driver rebalancing.")
  }
  
  # Demand pressure ratio: forecast / capacity
  demand_pressure <- if (estimated_capacity > 0) round(forecast_demand / estimated_capacity, 2) else 999.0
  
  list(
    is_available = TRUE,
    risk_score = final_score,
    risk_tier = tier_info$name,
    badge_color = tier_info$color,
    tier_description = tier_info$desc,
    forecast_demand = round(forecast_demand, 1),
    virtual_driver_count = virtual_driver_count,
    estimated_capacity = round(estimated_capacity, 1),
    capacity_shortage = round(shortage, 1),
    demand_pressure = demand_pressure,
    shortage_ratio = round(shortage_ratio, 3),
    normalized_growth = round(normalized_growth, 3),
    normalized_volatility = round(normalized_volatility, 3),
    contributions = list(
      shortage_points = contrib_shortage,
      growth_points = contrib_growth,
      volatility_points = contrib_volatility
    ),
    disclaimer = "Prototype analytical scenario risk score based on synthetic driver assumptions, not an official Rapido measure."
  )
}

#' Compute zone risk scores across multiple zones for comparative table
#' @param panel Daily panel data frame
#' @param zone_forecasts Named list of forecast daily demand by zone
#' @param default_drivers Default driver supply per zone
#' @param rides_per_driver Rides per driver per day
#' @return Formatted ranking data frame of zone risks
compute_multi_zone_risk_table <- function(
  panel,
  zone_forecasts,
  default_drivers = 30,
  rides_per_driver = 8
) {
  zones <- names(zone_forecasts)
  if (length(zones) == 0) return(data.frame())
  
  rows <- list()
  for (z in zones) {
    fc_val <- zone_forecasts[[z]]
    
    # Historical volatility and growth
    z_hist <- panel %>% filter(pickup_zone == z) %>% pull(demand_requests)
    cv <- if (length(z_hist) > 1 && mean(z_hist) > 0) sd(z_hist) / mean(z_hist) else 0.25
    
    # Recent growth rate (last 7 days vs previous 7 days)
    if (length(z_hist) >= 14) {
      last7 <- mean(tail(z_hist, 7))
      prev7 <- mean(head(tail(z_hist, 14), 7))
      growth <- if (prev7 > 0) (last7 - prev7) / prev7 else 0.0
    } else {
      growth <- 0.0
    }
    
    res <- calculate_zone_risk_score(
      forecast_demand = fc_val,
      virtual_driver_count = default_drivers,
      rides_per_driver = rides_per_driver,
      recent_growth_rate = growth,
      historical_cv = cv
    )
    
    if (res$is_available) {
      rows[[length(rows) + 1]] <- data.frame(
        Zone = z,
        Forecast_Demand = res$forecast_demand,
        Virtual_Drivers = res$virtual_driver_count,
        Estimated_Capacity = res$estimated_capacity,
        Shortage = res$capacity_shortage,
        Demand_Pressure = res$demand_pressure,
        Risk_Score = res$risk_score,
        Risk_Tier = res$risk_tier,
        Shortage_Contrib = res$contributions$shortage_points,
        Growth_Contrib = res$contributions$growth_points,
        Volatility_Contrib = res$contributions$volatility_points,
        stringsAsFactors = FALSE
      )
    }
  }
  
  if (length(rows) == 0) return(data.frame())
  
  res_df <- do.call(rbind, rows)
  res_df %>% arrange(desc(Risk_Score))
}
