# scripts/inspect_data.R
# Inspects raw dataset and outputs a comprehensive data health & schema audit

suppressPackageStartupMessages({
  if (requireNamespace("readr", quietly = TRUE)) library(readr)
  if (requireNamespace("dplyr", quietly = TRUE)) library(dplyr)
})

cat("==================================================\n")
cat("RAPIDO BANGALORE DATASET SCHEMA & QUALITY AUDIT\n")
cat("==================================================\n\n")

raw_paths <- c("data/raw/rapido_rides.csv", "data/raw/rides_data.csv")
dataset_path <- NULL
for (p in raw_paths) {
  if (file.exists(p)) {
    dataset_path <- p
    break
  }
}

if (is.null(dataset_path)) {
  cat("[ERROR] No raw dataset found in data/raw/.\n")
  cat("Please place 'rapido_rides.csv' or 'rides_data.csv' inside data/raw/\n")
  cat("Download source: https://www.kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset\n")
  quit(status = 1)
}

cat("[INFO] Reading dataset from:", dataset_path, "\n")
df <- read.csv(dataset_path, stringsAsFactors = FALSE, na.strings = c("", "NA", "nan", "NaN", "null", "NULL"))

cat(sprintf("\n[1] DIMENSIONS:\n    Rows:    %s\n    Columns: %s\n", format(nrow(df), big.mark=","), ncol(df)))

cat("\n[2] COLUMNS & DATA TYPES:\n")
col_summary <- data.frame(
  Column = names(df),
  Class = sapply(df, class),
  Missing_Count = sapply(df, function(x) sum(is.na(x))),
  Missing_Pct = sprintf("%.2f%%", sapply(df, function(x) mean(is.na(x)) * 100)),
  Unique_Values = sapply(df, function(x) length(unique(na.omit(x)))),
  Sample_Value = sapply(df, function(x) {
    vals <- na.omit(x)
    if (length(vals) > 0) as.character(vals[1]) else "<all NA>"
  }),
  stringsAsFactors = FALSE
)
print(col_summary, row.names = FALSE)

cat("\n[3] CATEGORICAL LEVELS:\n")
cat("  - Services:\n")
print(table(df$services, useNA = "always"))

cat("\n  - Ride Status:\n")
print(table(df$ride_status, useNA = "always"))

cat("\n  - Payment Method:\n")
print(table(df$payment_method, useNA = "always"))

cat("\n[4] TEMPORAL COVERAGE:\n")
dates <- tryCatch(as.Date(df$date), error = function(e) NULL)
if (!is.null(dates) && sum(!is.na(dates)) > 0) {
  cat(sprintf("  - Valid Dates: %s to %s (%d distinct days)\n",
              min(dates, na.rm = TRUE), max(dates, na.rm = TRUE), length(unique(na.omit(dates)))))
} else {
  cat("  - Could not parse dates directly as standard YYYY-MM-DD\n")
}

cat("\n[5] NUMERICAL ATTRIBUTES SUMMARY:\n")
num_cols <- names(df)[sapply(df, is.numeric)]
if (length(num_cols) > 0) {
  print(summary(df[, num_cols, drop = FALSE]))
}

cat("\n[6] GEOGRAPHIC / ZONE SUMMARY:\n")
if ("source" %in% names(df)) {
  cat("  - Distinct Pickup Locations (source):", length(unique(na.omit(df$source))), "\n")
  cat("  - Top 5 Pickup Locations:\n")
  print(head(sort(table(df$source), decreasing = TRUE), 5))
}
if ("destination" %in% names(df)) {
  cat("  - Distinct Drop-off Locations (destination):", length(unique(na.omit(df$destination))), "\n")
  cat("  - Top 5 Drop-off Locations:\n")
  print(head(sort(table(df$destination), decreasing = TRUE), 5))
}

cat("\n==================================================\n")
cat("AUDIT COMPLETE.\n")
cat("==================================================\n")
