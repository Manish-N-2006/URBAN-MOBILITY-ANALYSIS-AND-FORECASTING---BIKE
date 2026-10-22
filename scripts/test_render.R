# scripts/test_render.R
source("R/config.R")
source("R/data_loader.R")
source("R/data_cleaning.R")
source("R/feature_engineering.R")
source("R/demand_analysis.R")
source("R/dashboard_helpers.R")
source("R/mod_overview.R")

cat("Reading cleaned_rides.rds...\n")
df <- readRDS(CONFIG$processed_rides_rds)
cat("Cleaned rides rows:", nrow(df), "\n")

kpis <- compute_overall_kpis(df)
cat("KPIs computed successfully:\n")
str(kpis)

cat("Testing saas_kpi_card...\n")
card1 <- saas_kpi_card("Total Ride Requests", format_count(kpis$total_requests), "completed", "route", "#06b6d4")
cat("Card 1 generated successfully:\n", as.character(card1), "\n\n")

cat("Testing layout_column_wrap with cards...\n")
kpi_wrap <- bslib::layout_column_wrap(
  width = 1/4,
  saas_kpi_card("Total", "50,000", "sub", "route", "#06b6d4"),
  saas_kpi_card("Completion", "89.9%", "sub", "circle-check", "#10b981")
)
cat("layout_column_wrap success!\n")

cat("Testing compute_service_breakdown...\n")
svc <- compute_service_breakdown(df)
print(svc)

cat("Testing compute_daily_timeline...\n")
daily <- compute_daily_timeline(df)
print(head(daily, 3))

cat("ALL TESTS PASSED CLEANLY!\n")
