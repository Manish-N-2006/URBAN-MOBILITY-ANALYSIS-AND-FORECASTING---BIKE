# scripts/install_packages.R
# Automated dependency installer for Urban Bike Taxi Demand Analysis and Forecasting

required_packages <- c(
  "shiny",
  "bslib",
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "janitor",
  "lubridate",
  "ggplot2",
  "plotly",
  "DT",
  "scales",
  "forecast",
  "testthat",
  "leaflet"
)

cat("==================================================\n")
cat("Checking and Installing Project R Dependencies\n")
cat("==================================================\n\n")

installed <- rownames(installed.packages())
missing <- setdiff(required_packages, installed)

if (length(missing) == 0) {
  cat("[OK] All required packages are already installed.\n")
} else {
  cat("[INFO] Found", length(missing), "missing package(s):\n")
  cat(paste(" -", missing), sep = "\n")
  cat("\nInstalling missing packages from CRAN...\n")
  install.packages(missing, repos = "https://cloud.r-project.org")
  
  # Verify installation
  installed_now <- rownames(installed.packages())
  still_missing <- setdiff(required_packages, installed_now)
  if (length(still_missing) == 0) {
    cat("\n[SUCCESS] All packages successfully installed and verified!\n")
  } else {
    cat("\n[WARNING] Could not install:", paste(still_missing, collapse = ", "), "\n")
  }
}
