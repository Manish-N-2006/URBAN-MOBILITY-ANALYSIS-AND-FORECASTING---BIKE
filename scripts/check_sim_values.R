# scripts/check_sim_values.R
panel <- readRDS("data/processed/zone_daily_demand.rds")
for (z in c("Koramangala", "Gottigere", "Whitefield", "Indiranagar", "HSR Layout", "Banaswadi", "Begur")) {
  sub_df <- subset(panel, pickup_zone == z)
  zh <- sub_df$demand_requests
  cat(sprintf("%-15s : Total = %4d | Mean Daily = %5.1f | Last 7d Mean = %5.1f\n",
              z, sum(zh), mean(zh), mean(tail(zh, 7))))
}
