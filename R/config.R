# R/config.R
# Global Configuration, File Paths, Constants, and Analytical Parameters

CONFIG <- list(
  # File paths
  raw_data_candidates = c(
    "data/raw/rapido_rides.csv",
    "data/raw/rides_data.csv"
  ),
  processed_rides_rds = "data/processed/cleaned_rides.rds",
  zone_daily_demand_rds = "data/processed/zone_daily_demand.rds",
  geocoded_coords_csv = "data/reference/bangalore_zone_coords.csv",
  
  # Services taxonomy
  bike_services = c("bike", "bike lite"),
  all_services = c("bike", "bike lite", "auto", "cab economy", "parcel"),
  
  # Risk Score Weights (must sum to 1.0)
  risk_weights = list(
    shortage = 0.70,
    growth = 0.20,
    volatility = 0.10
  ),
  
  # Risk Score Thresholds
  risk_tiers = list(
    low = list(max = 30, label = "Low Risk", color = "#22c55e"),
    moderate = list(max = 60, label = "Moderate Risk", color = "#eab308"),
    high = list(max = 80, label = "High Risk", color = "#f97316"),
    critical = list(max = 100, label = "Critical Shortage", color = "#ef4444")
  ),
  
  # Simulator Defaults
  sim_defaults = list(
    rides_per_driver_daily = 6,
    default_donor_drivers = 5,
    default_recipient_drivers = 1,
    default_transfer = 2
  ),
  
  # Forecasting Parameters
  forecast = list(
    horizon_days = 7,
    train_split_ratio = 0.80,
    min_history_days = 14,
    confidence_levels = c(80, 95)
  ),
  
  # Dashboard UI Theme & Colors
  theme = list(
    primary = "#0284c7",    # Sky-600
    secondary = "#64748b",  # Slate-500
    success = "#10b981",    # Emerald-500
    warning = "#f59e0b",    # Amber-500
    danger = "#ef4444",     # Red-500
    info = "#6366f1",       # Indigo-500
    dark_bg = "#0f172a",    # Slate-900
    card_bg = "#1e293b",    # Slate-800
    text = "#f8fafc"
  )
)
