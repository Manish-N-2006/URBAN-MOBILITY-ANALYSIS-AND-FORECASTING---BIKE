# scripts/prepare_data.R
# End-to-End ETL Pipeline: Clean, Engineer Features, and Pre-aggregate

cat("==================================================\n")
cat("URBAN MOBILITY DATA PIPELINE: RAPIDO BANGALORE\n")
cat("==================================================\n\n")

source("R/config.R")
source("R/data_loader.R")
source("R/data_cleaning.R")
source("R/feature_engineering.R")

# 1. Load raw data
raw_df <- load_raw_rides()

# 2. Clean data
cleaned_df <- clean_rides_data(raw_df)

# 3. Engineer features
enriched_df <- engineer_ride_features(cleaned_df)

# 4. Save processed rides dataset
if (!dir.exists("data/processed")) {
  dir.create("data/processed", recursive = TRUE)
}
saveRDS(enriched_df, CONFIG$processed_rides_rds)
cat(sprintf("[SUCCESS] Saved enriched rides dataset (%d rows) to %s\n", nrow(enriched_df), CONFIG$processed_rides_rds))

# 5. Build and save continuous daily panel
daily_panel <- build_zone_daily_panel(enriched_df, min_zone_total_rides = 20)
saveRDS(daily_panel, CONFIG$zone_daily_demand_rds)
cat(sprintf("[SUCCESS] Saved continuous daily panel (%d rows across %d zones) to %s\n",
            nrow(daily_panel), length(unique(daily_panel$pickup_zone)), CONFIG$zone_daily_demand_rds))

cat("\n==================================================\n")
cat("ETL PIPELINE COMPLETED SUCCESSFULLY!\n")
cat("==================================================\n")
