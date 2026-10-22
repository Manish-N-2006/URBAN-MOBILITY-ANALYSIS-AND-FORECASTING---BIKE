# R/data_loader.R
# Safe dataset discovery, schema validation, and loader functions

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(janitor)
})

#' Find dataset path from configured candidates
#' @param candidate_paths Vector of potential file paths
#' @return First existing path or NULL
find_raw_dataset_path <- function(candidate_paths = CONFIG$raw_data_candidates) {
  for (p in candidate_paths) {
    if (file.exists(p)) {
      return(p)
    }
  }
  return(NULL)
}

#' Validate presence of raw dataset and give helpful guidance
#' @return Logical TRUE if found, otherwise stops or warns
check_raw_data_available <- function() {
  p <- find_raw_dataset_path()
  if (is.null(p)) {
    msg <- paste0(
      "[DATASET MISSING] Raw ride dataset not found!\n",
      "Expected location: 'data/raw/rapido_rides.csv'\n",
      "Please download the dataset from:\n",
      "https://www.kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset\n",
      "and place the CSV file in 'data/raw/rapido_rides.csv'."
    )
    return(list(available = FALSE, message = msg, path = NULL))
  }
  return(list(available = TRUE, message = paste("Found raw dataset at:", p), path = p))
}

#' Load raw dataset with column normalization and validation
#' @param file_path Optional override path
#' @return Clean data frame with original data and validation attributes
load_raw_rides <- function(file_path = NULL) {
  if (is.null(file_path)) {
    status <- check_raw_data_available()
    if (!status$available) {
      stop(status$message)
    }
    file_path <- status$path
  }
  
  message("[INFO] Loading raw rides data from: ", file_path)
  
  # Read raw CSV
  df_raw <- readr::read_csv(
    file_path,
    col_types = readr::cols(
      services = readr::col_character(),
      date = readr::col_character(),
      time = readr::col_character(),
      ride_status = readr::col_character(),
      source = readr::col_character(),
      destination = readr::col_character(),
      duration = readr::col_double(),
      ride_id = readr::col_character(),
      distance = readr::col_double(),
      ride_charge = readr::col_double(),
      misc_charge = readr::col_double(),
      total_fare = readr::col_double(),
      payment_method = readr::col_character()
    ),
    na = c("", "NA", "nan", "NaN", "null", "NULL"),
    show_col_types = FALSE
  )
  
  # Normalize column names with janitor
  df_raw <- janitor::clean_names(df_raw)
  
  # Validate minimal schema
  required_cols <- c("services", "date", "time", "ride_status", "source", "destination", "duration", "distance")
  missing_cols <- setdiff(required_cols, names(df_raw))
  if (length(missing_cols) > 0) {
    warning("[SCHEMA WARNING] The dataset is missing expected column(s): ", paste(missing_cols, collapse = ", "))
  }
  
  attr(df_raw, "source_path") <- file_path
  attr(df_raw, "raw_rows") <- nrow(df_raw)
  attr(df_raw, "raw_cols") <- ncol(df_raw)
  attr(df_raw, "loaded_at") <- Sys.time()
  
  return(df_raw)
}

#' Load processed data if available, or process raw on the fly
#' @return Processed rides data frame
load_processed_rides <- function() {
  if (file.exists(CONFIG$processed_rides_rds)) {
    return(readRDS(CONFIG$processed_rides_rds))
  }
  
  # If not yet processed, load raw and clean
  message("[INFO] Processed dataset not found. Running ETL on raw dataset...")
  raw_df <- load_raw_rides()
  cleaned_df <- clean_rides_data(raw_df)
  saveRDS(cleaned_df, CONFIG$processed_rides_rds)
  return(cleaned_df)
}
