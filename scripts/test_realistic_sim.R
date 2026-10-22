# scripts/test_realistic_sim.R
source("R/config.R")
source("R/risk_scoring.R")
source("R/what_if_simulator.R")

# Scenario: Koramangala (Recipient, demand ~ 19 rides/day)
# Gottigere (Donor, demand ~ 8 rides/day)

# Realistic driver supply:
# Recipient: 1 driver * 8 rides/driver = 8 capacity (Shortage = 11 rides!)
# Donor: 4 drivers * 8 rides/driver = 32 capacity (Surplus = 24 rides!)
# Reallocate: 2 drivers from Donor to Recipient

sim <- run_what_if_simulation(
  donor_zone = "Gottigere",
  recipient_zone = "Koramangala",
  donor_forecast = 8.1,
  recipient_forecast = 19.0,
  donor_drivers = 4,
  recipient_drivers = 1,
  transfer = 2,
  rides_per_driver = 8
)

cat("==================================================\n")
cat("REALISTIC WHAT-IF SIMULATION RESULTS\n")
cat("==================================================\n")
cat("Recipient Risk Before :", sim$recipient$before$risk_score, "(Tier:", sim$recipient$before$risk_tier, ")\n")
cat("Recipient Risk After  :", sim$recipient$after$risk_score, "(Tier:", sim$recipient$after$risk_tier, ")\n")
cat("Recipient Risk Delta  :", sprintf("-%.1f pts", sim$recip_risk_reduction), "\n")
cat("Donor Risk Delta      :", sprintf("+%.1f pts", sim$donor_risk_increase), "\n")
cat("Net Shortage Cut      :", sim$net_shortage_reduction, "rides eliminated!\n")
cat("Conserved Drivers     :", sim$total_drivers_conserved, "\n\n")

print(sim$comparison_table)
