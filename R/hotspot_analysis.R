# R/hotspot_analysis.R
# Hotspot Discovery, Spatial Concentration, and Geographic Mapping

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(leaflet)
  library(readr)
})

#' Load reference geocoded coordinates for Bangalore zones
#' @param ref_file Path to coordinates CSV
#' @return Data frame of zone coordinates
load_zone_coordinates <- function(ref_file = CONFIG$geocoded_coords_csv) {
  if (file.exists(ref_file)) {
    coords <- suppressMessages(readr::read_csv(ref_file, show_col_types = FALSE))
    return(coords)
  }
  return(data.frame(zone_name = character(0), latitude = numeric(0), longitude = numeric(0), osm_source = character(0)))
}

#' Rank highest and lowest demand zones
#' @param df Enriched rides data frame
#' @param top_n Number of top/bottom zones
#' @return Named list with top_pickups, bottom_pickups, top_dropoffs
compute_zone_rankings <- function(df, top_n = 15) {
  total_rides <- nrow(df)
  
  pickup_rank <- df %>%
    group_by(pickup_zone) %>%
    summarise(
      demand_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate_pct = round(mean(is_cancelled) * 100, 2),
      avg_fare_inr = round(mean(total_fare[is_completed], na.rm = TRUE), 1),
      avg_dist_km = round(mean(distance, na.rm = TRUE), 1),
      .groups = "drop"
    ) %>%
    arrange(desc(demand_requests)) %>%
    mutate(
      rank = row_number(),
      demand_share_pct = round((demand_requests / total_rides) * 100, 2),
      cumulative_share_pct = round(cumsum(demand_requests) / total_rides * 100, 2)
    )
  
  dropoff_rank <- df %>%
    group_by(dropoff_zone) %>%
    summarise(
      dropoffs = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      .groups = "drop"
    ) %>%
    arrange(desc(dropoffs)) %>%
    mutate(
      rank = row_number(),
      share_pct = round((dropoffs / total_rides) * 100, 2)
    )
  
  list(
    top_pickups = head(pickup_rank, top_n),
    bottom_pickups = tail(pickup_rank, top_n) %>% arrange(demand_requests),
    top_dropoffs = head(dropoff_rank, top_n),
    all_pickup_rankings = pickup_rank
  )
}

#' Calculate demand concentration metrics (Gini Coefficient & Pareto distribution)
#' @param df Enriched rides data frame
#' @return List of concentration statistics
compute_demand_concentration <- function(df) {
  zone_counts <- df %>%
    count(pickup_zone, sort = TRUE) %>%
    pull(n)
  
  n_zones <- length(zone_counts)
  total_demand <- sum(zone_counts)
  
  if (n_zones == 0 || total_demand == 0) {
    return(list(gini = 0, top_10_pct_share = 0, top_20_pct_share = 0, n_zones = 0))
  }
  
  # Standard Gini coefficient calculation for discrete distributions
  sorted_counts <- sort(zone_counts)
  index <- seq_along(sorted_counts)
  gini <- (2 * sum(index * sorted_counts)) / (n_zones * sum(sorted_counts)) - (n_zones + 1) / n_zones
  gini <- round(max(0, min(1, gini)), 3)
  
  # Pareto Top shares
  top_10_count <- max(1, round(0.10 * n_zones))
  top_20_count <- max(1, round(0.20 * n_zones))
  
  top_10_share <- round(sum(head(zone_counts, top_10_count)) / total_demand * 100, 1)
  top_20_share <- round(sum(head(zone_counts, top_20_count)) / total_demand * 100, 1)
  
  list(
    gini_coefficient = gini,
    total_zones = n_zones,
    top_10_pct_share = top_10_share,
    top_20_pct_share = top_20_share,
    concentration_category = case_when(
      gini >= 0.60 ~ "Extreme Spatial Concentration",
      gini >= 0.45 ~ "High Spatial Concentration",
      gini >= 0.30 ~ "Moderate Spatial Concentration",
      TRUE         ~ "Dispersed Demand"
    )
  )
}

#' Build Pickup-to-Dropoff Origin-Destination Matrix for Top Zones
#' @param df Enriched rides data frame
#' @param top_n Number of highest volume zones to include
#' @return Formatted matrix data frame suitable for heatmap visualization
build_od_heatmap_data <- function(df, top_n = 12) {
  top_zones <- df %>%
    count(pickup_zone, sort = TRUE) %>%
    slice_head(n = top_n) %>%
    pull(pickup_zone)
  
  grid <- tidyr::crossing(
    pickup_zone = top_zones,
    dropoff_zone = top_zones
  )
  
  obs <- df %>%
    filter(pickup_zone %in% top_zones, dropoff_zone %in% top_zones) %>%
    count(pickup_zone, dropoff_zone, name = "trips")
  
  heatmap_df <- grid %>%
    left_join(obs, by = c("pickup_zone", "dropoff_zone")) %>%
    mutate(trips = coalesce(trips, 0L))
  
  return(heatmap_df)
}

#' Merge zone demand summaries with verified geographic coordinates
#' @param df Enriched rides data frame
#' @return Data frame with lat, lon, demand, and mapping status
get_geocoded_zone_demand <- function(df) {
  coords <- load_zone_coordinates()
  
  zone_agg <- df %>%
    group_by(pickup_zone) %>%
    summarise(
      total_requests = n(),
      completed_trips = sum(is_completed),
      cancellations = sum(is_cancelled),
      cancellation_rate_pct = round(mean(is_cancelled) * 100, 1),
      avg_fare_inr = round(mean(total_fare[is_completed], na.rm = TRUE), 1),
      avg_distance_km = round(mean(distance, na.rm = TRUE), 1),
      .groups = "drop"
    )
  
  merged <- zone_agg %>%
    left_join(coords, by = c("pickup_zone" = "zone_name")) %>%
    mutate(
      has_coords = !is.na(latitude) & !is.na(longitude)
    ) %>%
    arrange(desc(total_requests))
  
  return(merged)
}

#' Create Leaflet Interactive Map for Geocoded Zones
#' Only plots zones with verified coordinates; never invents positions
#' @param geocoded_df Data frame from get_geocoded_zone_demand()
#' @return Leaflet htmlwidget or NULL if no coordinates available
render_hotspot_leaflet_map <- function(geocoded_df) {
  valid_pts <- geocoded_df %>% filter(has_coords)
  
  if (nrow(valid_pts) == 0) {
    return(NULL)
  }
  
  # Calculate radius scale
  max_demand <- max(valid_pts$total_requests, na.rm = TRUE)
  
  pal <- colorNumeric(
    palette = c("#22c55e", "#eab308", "#ef4444"),
    domain = valid_pts$cancellation_rate_pct
  )
  
  m <- leaflet(valid_pts) %>%
    addProviderTiles(providers$Esri.WorldGrayCanvas) %>%
    setView(lng = 77.62, lat = 12.98, zoom = 11)
  
  # Add circle markers for verified locations
  m <- m %>%
    addCircleMarkers(
      lng = ~longitude,
      lat = ~latitude,
      radius = ~scales::rescale(total_requests, to = c(8, 30), from = c(1, max_demand)),
      fillColor = ~pal(cancellation_rate_pct),
      color = "#06b6d4",
      weight = 1.5,
      opacity = 0.9,
      fillOpacity = 0.8,
      label = ~sprintf("%s: %s requests (Cancel: %.1f%%)", pickup_zone, format(total_requests, big.mark = ","), cancellation_rate_pct),
      popup = ~sprintf(
        "<div style='font-family:Inter, sans-serif; min-width:200px; background:#0f172a; color:#f8fafc; padding:12px; border-radius:10px; border:1px solid rgba(6,182,212,0.3);'>
          <h5 style='margin:0 0 8px 0; color:#38bdf8; font-weight:800; font-family:Outfit, sans-serif;'>%s</h5>
          <div style='display:flex; justify-content:space-between; margin-bottom:4px;'><span style='color:#94a3b8;'>Total Requests:</span> <b style='color:#fff;'>%s</b></div>
          <div style='display:flex; justify-content:space-between; margin-bottom:4px;'><span style='color:#94a3b8;'>Completed Trips:</span> <b style='color:#34d399;'>%s</b></div>
          <div style='display:flex; justify-content:space-between; margin-bottom:4px;'><span style='color:#94a3b8;'>Cancellation:</span> <b style='color:#fbbf24;'>%.1f%%</b></div>
          <div style='display:flex; justify-content:space-between; margin-bottom:4px;'><span style='color:#94a3b8;'>Avg Completed Fare:</span> <b style='color:#fff;'>₹%.1f</b></div>
          <div style='display:flex; justify-content:space-between; margin-bottom:6px;'><span style='color:#94a3b8;'>Avg Distance:</span> <b style='color:#fff;'>%.1f km</b></div>
          <div style='font-size:10px; color:#64748b; border-top:1px solid rgba(255,255,255,0.1); padding-top:4px;'>Source: %s</div>
        </div>",
        pickup_zone, format(total_requests, big.mark = ","), format(completed_trips, big.mark = ","),
        cancellation_rate_pct, avg_fare_inr, avg_distance_km, osm_source
      )
    ) %>%
    addLegend(
      position = "bottomright",
      pal = pal,
      values = ~cancellation_rate_pct,
      title = "Cancellation Rate (%)",
      opacity = 0.85
    )
  
  return(m)
}
