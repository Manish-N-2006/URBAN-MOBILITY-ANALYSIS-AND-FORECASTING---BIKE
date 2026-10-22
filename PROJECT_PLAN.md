# Urban Bike Taxi Demand Analysis and Forecasting: Project Plan

## Architecture Overview
The application is a pure R and Shiny modular intelligence platform designed for urban mobility analytics, bike taxi demand forecasting, risk scoring, and interactive scenario simulation ("What-If Driver Allocation"). It uses `bslib` for a theme with clean typography and KPI cards.

## Technology Stack
- **Language**: R (version 4.6.1)
- **Data Engineering**: `dplyr`, `tidyr`, `readr`, `janitor`, `lubridate`, `stringr`, `scales`
- **Analytics & Forecasting**: `forecast` (ARIMA / ETS / Baseline models with chronological train/test splits, MAE & RMSE)
- **Simulation**: Custom vectorized What-If allocation engine enforcing supply conservation and boundary constraints
- **UI & Dashboard**: R `shiny` + `bslib` (responsive dashboard layout, cards, value boxes, navbars)
- **Visualizations & Tables**: `plotly`, `ggplot2`, `DT` (interactive DataTables), `leaflet` (for map rendering with cached verified geolocations)
- **Testing**: `testthat` suite covering cleaning, feature extraction, forecasting, risk scoring, and simulator invariants

---

## Directory Structure
```
URBAN-MOBILITY-ANALYSIS-AND-FORECASTING---BIKE/
  app.R                        # Main Shiny dashboard application (modular UI & Server)
  R/
    config.R                   # Global configurations, file paths, parameters, themes
    data_loader.R              # Robust CSV ingestion, schema validation, missing data alerts
    data_cleaning.R            # Data normalization, type coercion, cleaning audit trail
    feature_engineering.R      # Temporal feature extraction, zone standardization, metric aggregations
    demand_analysis.R          # Service-wise demand, temporal patterns, cancellations, routes
    hotspot_analysis.R         # Zone concentration (Gini/top-N), pickup-dropoff matrix, spatial caching
    forecasting.R              # Daily time-series generation, baseline vs. ARIMA/ETS, chrono validation, MAE/RMSE
    risk_scoring.R             # Zone Demand Risk Score calculation (0-100), explainable components
    what_if_simulator.R        # Conservation-preserving driver redistribution simulator & before/after evaluation
    dashboard_helpers.R        # bslib card generators, KPI formatters, plot themes, custom alerts
  data/
    raw/
      rapido_rides.csv         # Raw Bangalore Rapido dataset (50,000 records)
    processed/
      cleaned_rides.rds        # Optimized cleaned dataset with engineered features
      zone_daily_demand.rds    # Pre-aggregated zone x date demand for instant reactive queries
    reference/
      bangalore_zone_coords.csv# Real OpenStreetMap geocoded coordinates for Bangalore localities
  scripts/
    install_packages.R         # Dependency check & installation from CRAN
    inspect_data.R             # Deep schema audit and data quality report
    prepare_data.R             # End-to-end data processing pipeline CLI
  tests/
    testthat.R                 # Test runner script
    testthat/
      test-data-cleaning.R     # Tests for NA handling, types, cancellations preservation
      test-feature-engineering.R # Tests for temporal features and zone normalization
      test-risk-score.R        # Tests for risk formula boundaries [0, 100], weights, components
      test-simulator.R         # Tests for driver conservation, non-negativity, capacity delta
      test-forecasting.R       # Tests for chronological train/test split, MAE/RMSE calculation
  PROJECT_PLAN.md              # Project architectural roadmap and specifications
  README.md                    # Comprehensive user guide, reproduction steps, methodology
  .gitignore                   # Standard R and IDE ignore rules
```

---

## Phased Implementation Roadmap

### Phase 0: Workspace & Data Inspection (DONE)
- [x] Verified R environment (R 4.6.1 at `E:\Program Files\R\R-4.6.1`).
- [x] Downloaded official Bangalore Rapido Ride Services dataset (50,000 rows, 13 columns).
- [x] Checked missing values (5,036 cancelled rides lack fares/payment methods; 0 missing values in completed rides).
- [x] Created `PROJECT_PLAN.md` and `scripts/inspect_data.R`.

### Phase 1: Environment & Data Pipeline
- [x] Write `scripts/install_packages.R` and install all required packages (`shiny`, `bslib`, `janitor`, `plotly`, `DT`, `forecast`, `testthat`, `leaflet`).
- [ ] Implement `R/config.R` with paths, colors, risk weights, and model parameters.
- [ ] Implement `R/data_loader.R` with strict schema validation and graceful fallback.
- [ ] Implement `R/data_cleaning.R` with explicit audit trail and column typing.
- [ ] Create `scripts/prepare_data.R` to run the ETL and generate `data/processed/cleaned_rides.rds`.

### Phase 2: Feature Engineering & Demand Analytics
- [ ] Implement `R/feature_engineering.R`:
  - Date & time extraction: `hour`, `weekday`, `is_weekend`, `day_of_month`, `week_of_year`, `time_of_day_bucket`.
  - Service filtering: `bike`, `bike lite`, and all-service modes.
  - Robust zone extraction: Clean raw point strings into standard Bangalore urban zones.
  - Distinction between total requests (observed records) and completed rides.
- [ ] Implement `R/demand_analysis.R`:
  - Temporal aggregations (hourly curves, weekday vs. weekend profiles).
  - Cancellation analysis by service, time, and distance.
  - Fare, duration, and speed (km/h) analysis.
  - Route matrix and OD (Origin-Destination) pair frequencies.

### Phase 3: Hotspot & Spatial Analysis
- [ ] Implement `R/hotspot_analysis.R`:
  - Zone demand rankings (top pickups, top drop-offs).
  - Demand concentration (Pareto / Top 10% share / Gini coefficient).
  - Zone-to-zone flow matrix and heatmap.
  - Verified OpenStreetMap geocoding integration for major Bangalore localities, with cached coordinates and clear fallback when coordinates are unresolved.

### Phase 4: Demand Forecasting
- [ ] Implement `R/forecasting.R`:
  - Daily time series creation by zone and service type.
  - Chronological train/validation split (e.g. 80/20 train/validation, final 12-14 days evaluation).
  - Baseline model: 7-day Seasonal Naive (`snaive`) or Historical Mean / Naive.
  - Predictive model: Auto ARIMA / Exponential Smoothing (`ets`).
  - Strict performance reporting: MAE, RMSE, and MAPE on held-out test data.
  - 7-day future forecast with 80% and 95% confidence intervals.
  - Graceful fallback for short, sparse, or zero-demand series.

### Phase 5: Zone Demand Risk Score
- [ ] Implement `R/risk_scoring.R`:
  - Formula:
    $$\text{shortage\_ratio} = \frac{\max(\text{forecast\_demand} - \text{estimated\_capacity}, 0)}{\max(\text{forecast\_demand}, 1)}$$
    $$\text{risk\_score} = 100 \times \left(0.70 \times \text{shortage\_ratio} + 0.20 \times \text{norm\_growth} + 0.10 \times \text{norm\_volatility}\right)$$
  - Capacity calculation: $\text{estimated\_capacity} = \text{virtual\_driver\_count} \times \text{rides\_per\_driver\_per\_interval}$.
  - Strict bounding: $0 \le \text{risk\_score} \le 100$.
  - Explainable breakdown: contribution of shortage, growth, and volatility.
  - Risk tiers: Low (<30), Moderate (30-60), High (60-80), Critical (>80).

### Phase 6: What-If Driver Allocation Simulator
- [ ] Implement `R/what_if_simulator.R`:
  - Inputs: Donor Zone, Recipient Zone, Initial Virtual Drivers per zone, Transfer Drivers, Rides/Driver capacity.
  - Strict validation:
    - Donor $\neq$ Recipient.
    - Transfer $\le$ Donor Supply.
    - Non-negative supply.
  - Conservation of supply invariant: $\text{Supply}_{\text{total, before}} = \text{Supply}_{\text{total, after}}$.
  - Outputs: Before vs After cards, delta calculations, shortage mitigation, risk score delta.

### Phase 7: R Shiny Dashboard Implementation
- [ ] Implement `R/dashboard_helpers.R` (reusable UI cards, plot formatters, KPI widgets).
- [ ] Build `app.R` with `bslib` theme:
  - Page 1: **Executive Overview** (KPIs, service distribution, trend summary, quick risk view).
  - Page 2: **Demand Explorer** (Interactive temporal filters, hourly & daily profiles, cancellations, fares).
  - Page 3: **Hotspots & Zones** (Rankings, OD heatmap, spatial map with verified coordinates).
  - Page 4: **Demand Forecasting** (Zone selection, historical vs forecast, prediction intervals, model vs baseline comparison, MAE/RMSE tables).
  - Page 5: **Zone Risk Analysis** (Risk radar/table, shortage vs growth vs volatility decomposition).
  - Page 6: **What-If Driver Allocation Simulator** (Interactive redistribution controls, Before/After comparison, supply preservation meters).
  - Page 7: **Data Quality & Methodology** (Schema audit, cleaning notes, forecasting methodology, assumptions).

### Phase 8: Unit Testing, Validation & Documentation
- [ ] Write and run testthat suites:
  - `test-data-cleaning.R`
  - `test-feature-engineering.R`
  - `test-risk-score.R`
  - `test-simulator.R`
  - `test-forecasting.R`
- [ ] Create comprehensive `README.md` with full reproduction steps, methodology, and limitations.
- [ ] Verify reactive dashboard execution and provide concise completion report.
