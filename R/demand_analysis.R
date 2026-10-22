# R/demand_analysis.R
# Core Ride Demand Analytics, Temporal Aggregations, and Route Metrics

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(plotly)
  library(scales)
})

#' Compute overall high-level KPI summary cards
#' @param df Enriched rides data frame
#' @return Named list of key metrics
compute_overall_kpis <- function(df) {
  total_reqs <- nrow(df)
  completed_trips <- sum(df$is_completed)
  cancelled_trips <- sum(df$is_cancelled)
  cancellation_pct <- if (total_reqs > 0) (cancelled_trips / total_reqs) * 100 else 0
  
  bike_reqs <- sum(df$is_bike_service)
  bike_pct <- if (total_reqs > 0) (bike_reqs / total_reqs) * 100 else 0
  
  avg_dist <- mean(df$distance, na.rm = TRUE)
  avg_dur <- mean(df$duration, na.rm = TRUE)
  avg_fare <- mean(df$total_fare[df$is_completed], na.rm = TRUE)
  total_revenue <- sum(df$total_fare[df$is_completed], na.rm = TRUE)
  
  list(
    total_requests = total_reqs,
    completed_trips = completed_trips,
    cancelled_trips = cancelled_trips,
    cancellation_rate_pct = round(cancellation_pct, 1),
    bike_requests = bike_reqs,
    bike_share_pct = round(bike_pct, 1),
    avg_distance_km = round(avg_dist, 1),
    avg_duration_min = round(avg_dur, 1),
    avg_fare_inr = round(avg_fare, 1),
    total_revenue_inr = round(total_revenue, 0),
    unique_zones = length(unique(df$pickup_zone)),
    date_range = c(min(df$ride_date), max(df$ride_date))
  )
}

#' Compute service-wise demand breakdown
#' @param df Enriched rides data frame
#' @return Data frame of demand and completion rates per service
compute_service_breakdown <- function(df) {
  df %>%
    group_by(services) %>%
    summarise(
      requests = n(),
      completed = sum(is_completed),
      cancelled = sum(is_cancelled),
      cancellation_rate_pct = round(mean(is_cancelled) * 100, 2),
      avg_distance_km = round(mean(distance, na.rm = TRUE), 2),
      avg_duration_min = round(mean(duration, na.rm = TRUE), 2),
      avg_fare_inr = round(mean(total_fare[is_completed], na.rm = TRUE), 2),
      fare_per_km = round(mean(fare_per_km[is_completed], na.rm = TRUE), 2),
      .groups = "drop"
    ) %>%
    mutate(
      share_pct = round(requests / sum(requests) * 100, 2)
    ) %>%
    arrange(desc(requests))
}

#' Compute hourly demand profile across weekdays vs weekends
#' @param df Enriched rides data frame
#' @return Aggregated data frame by hour and day_type
compute_hourly_profile <- function(df) {
  df %>%
    group_by(ride_hour, day_type) %>%
    summarise(
      total_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate = round(mean(is_cancelled) * 100, 2),
      avg_speed_kmh = round(mean(speed_kmh, na.rm = TRUE), 2),
      .groups = "drop"
    ) %>%
    arrange(day_type, ride_hour)
}

#' Compute daily demand time series with rolling averages
#' @param df Enriched rides data frame
#' @return Daily aggregated data frame
compute_daily_timeline <- function(df) {
  df %>%
    group_by(ride_date) %>%
    summarise(
      total_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate = round(mean(is_cancelled) * 100, 2),
      total_revenue = sum(total_fare[is_completed], na.rm = TRUE),
      avg_distance = mean(distance, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(ride_date) %>%
    mutate(
      rolling_7d_requests = stats::filter(total_requests, rep(1/7, 7), sides = 1)
    )
}

#' Compute top zone-to-zone Origin-Destination (OD) pairs
#' @param df Enriched rides data frame
#' @param top_n Number of top routes to return
#' @return Top route data frame
compute_top_routes <- function(df, top_n = 15) {
  df %>%
    filter(pickup_zone != dropoff_zone) %>% # Inter-zone trips
    group_by(pickup_zone, dropoff_zone, route_pair) %>%
    summarise(
      total_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate = round(mean(is_cancelled) * 100, 1),
      avg_distance_km = round(mean(distance, na.rm = TRUE), 1),
      avg_duration_min = round(mean(duration, na.rm = TRUE), 1),
      avg_fare = round(mean(total_fare[is_completed], na.rm = TRUE), 1),
      .groups = "drop"
    ) %>%
    arrange(desc(total_requests)) %>%
    slice_head(n = top_n)
}
