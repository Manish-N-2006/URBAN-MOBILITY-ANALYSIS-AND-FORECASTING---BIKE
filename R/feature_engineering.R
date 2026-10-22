# R/feature_engineering.R
# Feature Engineering and Analytical Aggregations for Ride Demand

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

#' Enrich cleaned rides dataset with advanced behavioral and temporal features
#' @param df Cleaned rides dataset
#' @return Enriched data frame
engineer_ride_features <- function(df) {
  df <- df %>%
    mutate(
      # Day of week (ordered factor starting Monday)
      ride_weekday = factor(
        weekdays(ride_date),
        levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
      ),
      is_weekend = ride_weekday %in% c("Saturday", "Sunday"),
      day_type = ifelse(is_weekend, "Weekend", "Weekday"),
      
      # Peak / Off-peak temporal segmentation
      time_period = case_when(
        ride_hour >= 0 & ride_hour < 6   ~ "Late Night (00-06)",
        ride_hour >= 6 & ride_hour < 10  ~ "Morning Peak (06-10)",
        ride_hour >= 10 & ride_hour < 16 ~ "Midday Off-Peak (10-16)",
        ride_hour >= 16 & ride_hour < 21 ~ "Evening Peak (16-21)",
        TRUE                             ~ "Night (21-24)"
      ),
      time_period = factor(
        time_period,
        levels = c("Morning Peak (06-10)", "Midday Off-Peak (10-16)", "Evening Peak (16-21)", "Night (21-24)", "Late Night (00-06)")
      ),
      
      # Route key (Origin -> Destination)
      route_pair = paste0(pickup_zone, " -> ", dropoff_zone),
      
      # Unit economics (only valid for completed trips with positive fares)
      fare_per_km = ifelse(is_completed & !is.na(total_fare) & distance > 0, round(total_fare / distance, 2), NA_real_),
      duration_per_km = ifelse(distance > 0, round(duration / distance, 2), NA_real_)
    )
  
  return(df)
}

#' Generate a complete, continuous daily panel of demand by zone
#' Ensures every zone has an uninterrupted time sequence with 0s filled for missing dates
#' @param df Enriched rides data frame
#' @param service_filter Character vector of services to filter, or NULL for all
#' @param min_zone_total_rides Minimum total rides in historical window for zone inclusion
#' @return Continuous panel data frame: zone, ride_date, demand_requests, completed_rides, cancelled_rides
build_zone_daily_panel <- function(df, service_filter = NULL, min_zone_total_rides = 30) {
  # Apply service filtering if specified
  df_sub <- df
  if (!is.null(service_filter) && length(service_filter) > 0) {
    df_sub <- df_sub %>% filter(services %in% service_filter)
  }
  
  # Determine top zones that meet minimum volume threshold
  top_zones <- df_sub %>%
    count(pickup_zone, sort = TRUE) %>%
    filter(n >= min_zone_total_rides) %>%
    pull(pickup_zone)
  
  if (length(top_zones) == 0) {
    top_zones <- unique(df_sub$pickup_zone)
  }
  
  # Generate full Cartesian grid of (all dates x selected zones)
  all_dates <- seq.Date(min(df$ride_date), max(df$ride_date), by = "day")
  full_grid <- tidyr::crossing(
    pickup_zone = top_zones,
    ride_date = all_dates
  )
  
  # Aggregate observed demand
  daily_obs <- df_sub %>%
    filter(pickup_zone %in% top_zones) %>%
    group_by(pickup_zone, ride_date) %>%
    summarise(
      demand_requests = n(),
      completed_rides = sum(is_completed),
      cancelled_rides = sum(is_cancelled),
      total_fare = sum(total_fare, na.rm = TRUE),
      avg_distance = mean(distance, na.rm = TRUE),
      avg_duration = mean(duration, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Merge with full grid and impute 0 for missing days
  panel <- full_grid %>%
    left_join(daily_obs, by = c("pickup_zone", "ride_date")) %>%
    mutate(
      demand_requests = coalesce(demand_requests, 0L),
      completed_rides = coalesce(completed_rides, 0L),
      cancelled_rides = coalesce(cancelled_rides, 0L),
      total_fare = coalesce(total_fare, 0.0),
      avg_distance = coalesce(avg_distance, 0.0),
      avg_duration = coalesce(avg_duration, 0.0),
      weekday = factor(weekdays(ride_date), levels = levels(df$ride_weekday))
    ) %>%
    arrange(pickup_zone, ride_date)
  
  return(panel)
}

#' Calculate zone-level summary metrics
#' @param df Enriched rides data frame
#' @param service_filter Optional service filter
#' @return Summary data frame per zone
summarize_zone_metrics <- function(df, service_filter = NULL) {
  df_sub <- df
  if (!is.null(service_filter) && length(service_filter) > 0) {
    df_sub <- df_sub %>% filter(services %in% service_filter)
  }
  
  df_sub %>%
    group_by(pickup_zone) %>%
    summarise(
      total_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate = round(mean(is_cancelled) * 100, 2),
      avg_fare = round(mean(total_fare[is_completed], na.rm = TRUE), 2),
      avg_distance_km = round(mean(distance, na.rm = TRUE), 2),
      avg_duration_min = round(mean(duration, na.rm = TRUE), 2),
      avg_speed_kmh = round(mean(speed_kmh, na.rm = TRUE), 2),
      .groups = "drop"
    ) %>%
    arrange(desc(total_requests))
}
