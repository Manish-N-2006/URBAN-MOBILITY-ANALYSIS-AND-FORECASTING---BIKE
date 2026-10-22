# R/data_cleaning.R
# Data Cleaning, Quality Auditing, and Transformation Pipeline

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(lubridate)
})

#' Normalize raw location strings to urban neighborhood zones
#' @param loc_vec Character vector of raw location strings
#' @return Cleaned zone names
standardize_zone_name <- function(loc_vec) {
  if (is.null(loc_vec)) return(character(0))
  
  # Strip leading and trailing whitespace
  zones <- str_trim(loc_vec)
  
  # Pattern to strip typical street / development suffixes:
  # e.g., "Basavanagudi 3rd Block", "Balagere 1st Stage", "Kothanur Landing", "HSR Layout Area"
  suffix_pattern <- paste0(
    " (Landing|Square|Harbor|Cove|Drive|Mews|Arc|Area|Viewpoint|Pointe|",
    "Village|Station|Lane|Terrace|Heights|Grove|Crossing|Plaza|Cross|",
    "Junction|Center|Centre|Park|Road|Colony|Enclave|Circle|Meadows|Summit|",
    "Ridge|Bridge|Fields|Alley|Close|Track|Vista|Works|Dam|Cutting|District|",
    "Hill|Hills|Place|Boulevard|Woods|Esplanade|Quadrant|Alcove|Pass|Promenade|",
    "Sector|Gate|Corner|Gardens|Estate|Hub|Bay|Tower|Towers|",
    "[0-9]+(st|nd|rd|th)? (Block|Stage|Cross|Main|Phase))$"
  )
  
  # Iteratively trim trailing modifiers (up to 2 passes for e.g. "4th Block Place")
  cleaned <- sub(suffix_pattern, "", zones, ignore.case = TRUE)
  cleaned <- sub(suffix_pattern, "", cleaned, ignore.case = TRUE)
  cleaned <- str_trim(cleaned)
  
  # Fallback for any empty results
  cleaned[cleaned == "" | is.na(cleaned)] <- "Unknown Zone"
  
  return(cleaned)
}

#' Perform comprehensive cleaning and validation on raw ride dataset
#' @param df Data frame of raw rides
#' @return Cleaned and validated data frame with audit attributes
clean_rides_data <- function(df) {
  audit <- list(
    start_time = Sys.time(),
    initial_rows = nrow(df),
    initial_cols = ncol(df)
  )
  
  # 1. Deduplication on ride_id
  initial_count <- nrow(df)
  df <- df %>% distinct(ride_id, .keep_all = TRUE)
  audit$duplicate_rides_removed <- initial_count - nrow(df)
  
  # 2. String standardization
  df <- df %>%
    mutate(
      services = str_to_lower(str_trim(services)),
      ride_status = str_to_lower(str_trim(ride_status)),
      source = str_trim(source),
      destination = str_trim(destination),
      payment_method = ifelse(is.na(payment_method), "Unpaid / Cancelled", str_trim(payment_method))
    )
  
  # 3. Robust Date & Time parsing
  df <- df %>%
    mutate(
      ride_date = as.Date(date),
      # Extract hour as integer (0-23)
      ride_hour = suppressWarnings(as.integer(substr(time, 1, 2))),
      # Parse full datetime
      ride_datetime = suppressWarnings(as.POSIXct(paste(date, time), format = "%Y-%m-%d %H:%M:%OS", tz = "Asia/Kolkata"))
    )
  
  # Drop records with invalid dates or hours
  valid_dates <- !is.na(df$ride_date) & !is.na(df$ride_hour) & df$ride_hour >= 0 & df$ride_hour <= 23
  audit$invalid_datetime_rows_dropped <- sum(!valid_dates)
  df <- df[valid_dates, ]
  
  # 4. Numerical validation
  # Distance and duration must be positive
  valid_physics <- (df$distance > 0) & (df$duration > 0) & (df$distance <= 100) & (df$duration <= 300)
  audit$unrealistic_physics_dropped <- sum(!valid_physics)
  df <- df[valid_physics, ]
  
  # 5. Logical status & completion flag
  df <- df %>%
    mutate(
      is_completed = (ride_status == "completed"),
      is_cancelled = (ride_status == "cancelled")
    )
  
  # Validate fares: cancelled rides naturally have NA fares
  # For completed rides, ensure non-negative fares
  df <- df %>%
    mutate(
      ride_charge = ifelse(is_completed & is.na(ride_charge), 0, ride_charge),
      misc_charge = ifelse(is_completed & is.na(misc_charge), 0, misc_charge),
      total_fare = ifelse(is_completed & is.na(total_fare), (ride_charge + misc_charge), total_fare)
    )
  
  # 6. Calculated speed (km/h) for completed trips
  df <- df %>%
    mutate(
      speed_kmh = round(distance / (duration / 60), 2)
    )
  
  # 7. Zone Standardization
  df <- df %>%
    mutate(
      pickup_location = source,
      dropoff_location = destination,
      pickup_zone = standardize_zone_name(source),
      dropoff_zone = standardize_zone_name(destination)
    )
  
  # 8. Service categorization flags
  df <- df %>%
    mutate(
      is_bike_service = services %in% c("bike", "bike lite"),
      service_group = case_when(
        services %in% c("bike", "bike lite") ~ "Bike Taxi",
        services == "auto" ~ "Auto",
        services == "cab economy" ~ "Cab Economy",
        services == "parcel" ~ "Parcel Delivery",
        TRUE ~ "Other"
      )
    )
  
  audit$final_rows <- nrow(df)
  audit$final_cols <- ncol(df)
  audit$distinct_pickup_zones <- if (nrow(df) > 0) length(unique(df$pickup_zone)) else 0L
  audit$distinct_dropoff_zones <- if (nrow(df) > 0) length(unique(df$dropoff_zone)) else 0L
  audit$date_range <- if (nrow(df) > 0) c(min(df$ride_date), max(df$ride_date)) else as.Date(c(NA, NA))
  audit$completed_count <- sum(df$is_completed)
  audit$cancelled_count <- sum(df$is_cancelled)
  audit$end_time <- Sys.time()
  
  attr(df, "audit_trail") <- audit
  
  message(sprintf(
    "[CLEANING COMPLETE] Input: %d rows -> Cleaned: %d rows (%d completed, %d cancelled). Extracted %d distinct zones.",
    audit$initial_rows, audit$final_rows, audit$completed_count, audit$cancelled_count, audit$distinct_pickup_zones
  ))
  
  return(df)
}
