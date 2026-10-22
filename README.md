# Urban Bike Taxi Demand Analysis and Forecasting Platform
### *An Enterprise Decision-Support & Spatial Policy Simulation Engine for Urban Mobility*

[![R Version](https://img.shields.io/badge/R-4.6.1-276DC3.svg?logo=R&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-v1.14-0284c7.svg?logo=rstudio&logoColor=white)](https://shiny.posit.co/)
[![bslib UI](https://img.shields.io/badge/Theme-bslib%20Darkly%20Glassmorphism-06b6d4.svg)](https://rstudio.github.io/bslib/)
[![Forecast](https://img.shields.io/badge/Forecasting-Auto--ARIMA%20%7C%20ETS-10b981.svg)](https://pkg.robjhyndman.com/forecast/)
[![Tests](https://img.shields.io/badge/Unit%20Tests-66%20Passed%20%7C%200%20Failed-success.svg)](https://testthat.r-lib.org/)
[![Leaflet](https://img.shields.io/badge/Mapping-Leaflet%20OSM-f59e0b.svg)](https://rstudio.github.io/leaflet/)
[![License](https://img.shields.io/badge/License-MIT-6366f1.svg)](LICENSE)

---

## 🌟 Executive Overview

Urban on-demand transit systems (bike taxis, autos, cabs) face extreme spatial and temporal supply-demand friction. In metropolitan tech hubs like **Bangalore, India**, localized demand spikes during peak commute hours lead to driver shortages, skyrocketing cancellation rates, and unfulfilled passenger demand.

This project delivers a **full-stack, presentation-ready intelligence platform** built entirely in **pure R and Shiny** (powered by `bslib`, `plotly`, `leaflet`, `DT`, and `forecast`). Leveraging the authentic **Bangalore Rapido Ride Services Dataset** (50,000 ride booking records across 61 calendar days), the platform translates raw telematics into predictive demand forecasts, operational risk scores, and **interactive what-if driver reallocation simulations**.

---

## 🚀 What's New in this Project?

Unlike standard data science notebooks or descriptive BI dashboards, this platform introduces several algorithmic, architectural, and analytical innovations:

### 1. Invariant-Preserving "What-If" Driver Allocation Simulator
* **The Problem in Conventional BI**: Dashboards display where demand was yesterday, but provide no mechanism to simulate how redistributing fleets will alter operational outcomes tomorrow.
* **The Innovation**: A policy cockpit that models transferring virtual drivers from a low-strain **Donor Zone** to a high-demand **Recipient Zone**. Crucially, it mathematically enforces a **Conservation of Supply Invariant**:
  $$\sum \text{Drivers}_{\text{Before}} \equiv \sum \text{Drivers}_{\text{After}}$$
  It physically prevents negative driver fleets, forbids donor over-allocation, provides a **Live Heads-Up Display (HUD)** of real-time deficits/surpluses, and measures **unserved passenger rides eliminated** and **risk points mitigated**.

### 2. Explainable 0–100 Zone Demand Risk Scoring Engine
* **The Innovation**: Rather than black-box machine learning outputs, the system generates an interpretable composite operational risk metric bounded strictly in $[0, 100]$. The score combines **Capacity Shortage Ratio (70% weight)**, **Normalized Recent Growth (20% weight)**, and **Demand Volatility CV (10% weight)**. Every single zone's score can be decomposed into exact point contributions.

### 3. Leakage-Free Chronological Time-Series Validation
* **The Innovation**: Many ride-hailing forecasting projects improperly use random train/test splits, leaking future autocorrelation into the past. This platform strictly enforces **chronological splitting** (first ~54 days training, final 7 days unseen holdout) to evaluate **Auto-ARIMA** against a **Seasonal Naive (`snaive`) baseline** reporting empirical **MAE, RMSE, and MAPE** alongside 80% and 95% confidence intervals.

### 4. Canonical Urban Zone Disentanglement Engine
* **The Innovation**: The raw dataset recorded 12,982 hyper-granular micro-street variations (e.g., *"Basavanagudi 3rd Block"*, *"Kothanur Landing"*), which makes continuous time-series modeling impossible due to sparsity. A regex parsing engine strips development suffixes into **145 canonical Bangalore urban zones** while maintaining the granular point strings intact.

### 5. Ethical Spatial Intelligence (Zero Hallucinated Coordinates)
* **The Innovation**: The application strictly refuses to synthesize fake or randomized latitude/longitude coordinates. Instead, verified **OpenStreetMap Nominatim centroid coordinates** are mapped into a reference catalog. Only verified localities are mapped onto the dark-canvas **Leaflet interactive geospatial heatmap**.

### 6. Modern Glassmorphism SaaS Interface (Pure R & bslib)
* **The Innovation**: Built without single-page JavaScript frameworks (React/Vue/Node). Using custom CSS design tokens on top of `bslib`, the interface delivers an enterprise look: pulsing live telemetry indicators, radial-glow KPI cards, hover micro-interactions, dark-mode tables, and responsive cards.

---

## 📍 Where Each Chart is Located: Complete Visual Directory

The dashboard is structured into **7 dedicated tabs**. Below is the complete catalog of every visual asset, its exact title in the UI, chart type, data metrics, and analytical purpose:

```
┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   PAGE NAVIGATION ARCHITECTURE                                        │
├─────────────┬─────────────────┬─────────────────┬──────────────┬──────────────┬─────────────┬─────────┤
│ 1. Overview │ 2. Demand Expl. │ 3. Hotspots/Map │ 4. Forecast  │ 5. Zone Risk │ 6. What-If  │ 7. Docs │
└─────────────┴─────────────────┴─────────────────┴──────────────┴──────────────┴─────────────┴─────────┘
```

### Page 1: Overview (`mod_overview.R`)
*Mission Control: High-level macro metrics, fleet mix, temporal trends, and top zone rankings.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Hero Telemetry Banner** | Live Status HUD | Status indicator, observed days (61), active zones (145), bike share (40.0%) | Quick operational telemetry verification. |
| **SaaS KPI Cards (4 Cards)** | Value Cards with Radial Glow | • Total Requests (50,000)<br>• Completion Rate (89.9%)<br>• Bike Taxi Share (40.0%)<br>• Gross Volume (₹24.6M) | Macro health metrics; reflects observed request volume vs. fulfilled rides. |
| **Service Modality Breakdown & Cancellation Rates** | Categorical Bar Chart (Plotly) | X: Service category (`bike`, `auto`, `cab economy`, `parcel`, `bike lite`)<br>Y: Request volume & share % | Compares modal share. Shows bike taxi dominance (40% combined) in Bangalore transit. |
| **Daily Demand Trajectory & 7-Day Moving Trend** | Area + Spline Line Hybrid (Plotly) | X: Calendar date (June 17 – Aug 16)<br>Y: Daily requests<br>Overlay: 7-day rolling average | Highlights weekend vs. weekday volume cycles and macro platform growth over 2 months. |
| **Highest-Demand Bangalore Zones (Observed Requests)** | Horizontal Bar Chart (Plotly) | X: Request count<br>Y: Top 8 urban zones (Koramangala, Gottigere, Banaswadi, etc.) | Immediate identification of primary transit origin points across the city. |

---

### Page 2: Demand Explorer (`mod_demand_explorer.R`)
*Deep Dive: Diurnal commuting cycles, route economics, and trip physics.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Diurnal Demand Curve: Weekday vs. Weekend** | 24-Hour Dual Line Profile (Plotly) | X: Hour of day (0–23)<br>Y: Request count<br>Lines: Weekdays (solid cyan) vs. Weekends (amber dash) | Visualizes peak rush windows: morning peak (08:00–10:00) and evening peak (17:00–20:00). |
| **Demand Heatmap: Day of Week × Hour of Day** | 2D Density Heatmap (Plotly) | X: Hour of day (0–23)<br>Y: Day of week (Mon–Sun)<br>Z: Request density | Identifies the highest-pressure urban commute slots (e.g., Friday 18:00–20:00). |
| **Trip Distance & Duration Distributions** | Bimodal Histogram (Plotly) | X: Trip road distance (km)<br>Y: Frequency count of trips | Validates physics: mean road distance of 25.5 km, typical trip duration 30–90 min. |
| **Unit Economics: Fare per Kilometer by Service** | Box & Whisker Plot (Plotly) | X: Service modality<br>Y: Fare per road km (₹/km) | Reveals pricing tiers: Bike taxi has highest trip velocity and lower unit cost than cabs. |
| **Most Frequent Zone-to-Zone Routes & Service Quality** | Interactive DataTable (DT) | Origin, Destination, Requests, Completed Trips, Cancellation Rate %, Distance, Fare | Searchable corridor analysis for route-level supply planning and surge management. |

---

### Page 3: Hotspots & Zones (`mod_hotspots.R`)
*Spatial Analysis: Geographic distribution, spatial concentration, and origin-destination flow.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Spatial Concentration KPI Cards (4 Cards)** | Value Cards with Radial Glow | • Spatial Gini Index (0.748)<br>• Top 10% Zones Share (74.1%)<br>• Peak Hotspot (Koramangala)<br>• Urban Hubs Audited (4,265) | Quantifies extreme spatial inequality in ride requests across Bangalore. |
| **Bangalore Urban Mobility Geographic Heatmap** | Interactive Leaflet Geospatial Map | Lat/Lon: Real OSM centroids<br>Circle Radius: Demand volume<br>Color: Cancellation rate % (Green $\rightarrow$ Red) | Hover/click to inspect zone health cards. Identifies high-cancellation supply bottleneck areas. |
| **Top 15 Pickup Hotspot Zones** | Horizontal Bar with Gradient (Plotly) | X: Requests<br>Y: Top 15 zones<br>Fill: Cancellation rate % | Ranks origins driving urban demand; flags zones where high cancellations indicate shortages. |
| **Top 15 Destination Zones** | Horizontal Bar Chart (Plotly) | X: Drop-off count<br>Y: Top 15 destination hubs | Evaluates urban inflow terminals (tech parks, transit hubs, business districts). |
| **Origin-to-Destination (OD) Zone Interaction Heatmap** | 12×12 Cross-Flow Heatmap (Plotly) | X: Destination zone<br>Y: Origin zone<br>Z: Inter-zone passenger volume | Displays spatial interaction density between major commercial and residential hubs. |

---

### Page 4: Demand Forecasting (`mod_forecasting.R`)
*Predictive Intelligence: Chronological holdout evaluation and 7-day out-of-sample forecasting.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Model Performance Benchmark Table** | Comparative Metrics Table | Model, Out-of-Sample MAE, Out-of-Sample RMSE, Out-of-Sample MAPE % | Directly compares Auto-ARIMA against Seasonal Naive on unseen historical test days. |
| **Chronological Validation Holdout Plot** | Multi-Line Comparison Chart (Plotly) | X: Holdout test dates (final 7 days)<br>Y: Actual demand vs. Baseline vs. ARIMA | Visually reveals how closely Auto-ARIMA tracks day-to-day fluctuations vs. baseline. |
| **Near-Term Demand Forecast: Next 7 Days** | Projected Line with Confidence Ribbons (Plotly) | X: Date (historical + 7 days future)<br>Y: Daily demand<br>Bands: 80% and 95% Prediction Intervals | Out-of-sample forward forecast showing expected demand and bounded uncertainty cones. |
| **Forecast Values & Prediction Intervals Table** | Tabular Data Grid | Date, Point Forecast, Lower 80%, Upper 80%, Lower 95%, Upper 95% | Numerical planning values for fleet managers scheduling next week's capacity. |

---

### Page 5: Zone Risk Analysis (`mod_risk_analysis.R`)
*Operational Risk: Formula-based vulnerability assessment and scoreboard.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Risk Tier Summary KPI Cards (4 Cards)** | Status Badge Cards | Counts in: Critical Shortage (>80), High Strain (60–80), Moderate (30–60), Low (<30) | Executive snapshot of citywide fleet adequacy under configured driver assumptions. |
| **Risk Score Component Decomposition** | Stacked Bar Chart (Plotly) | X: Top 15 strained zones<br>Y: Points (0–100)<br>Segments: Shortage (70%), Growth (20%), Volatility (10%) | Complete transparency: explains exactly *why* a zone is risky (capacity deficit vs. surge). |
| **Bangalore Urban Zones Risk Scoreboard** | Searchable Interactive DataTable (DT) | Zone, Risk Score, Tier, Forecast Demand, Virtual Drivers, Capacity, Shortage, Pressure | Sortable operational matrix enabling targeted fleet interventions. |

---

### Page 6: What-If Driver Allocation Simulator (`mod_simulator.R`)
*Interactive Policy Lab: Rebalancing virtual driver supply across Bangalore hubs.*

| Chart / Component Name in UI | Visual Type | Data Metrics Plotted | How to Interpret It |
| :--- | :--- | :--- | :--- |
| **Live Heads-Up Display (HUD)** | Dynamic Real-Time Badges | Real-time demand, configured capacity, surplus/deficit indicator | Instant visual feedback on whether a zone has unmet shortage or capacity surplus. |
| **Simulation Delta KPI Cards (4 Cards)** | Value Cards with Radial Glow | • Recipient Risk Reduction ($\Delta$ pts)<br>• Donor Risk Tradeoff ($\Delta$ pts)<br>• System Shortage Cut (rides)<br>• Conserved Drivers (100%) | Quantifies net systemic benefit: unserved rides eliminated and risk mitigated. |
| **Demand vs. Service Capacity (Before vs. After)** | 4-Bar Grouped Bar Chart (Plotly) | X: Donor & Recipient (Before/After)<br>Y: Rides/day<br>Bars: Forecast Demand vs. Service Capacity | Visual proof of deficit elimination in the recipient zone. |
| **Risk Score Trajectory (Before vs. After)** | Slopegraph Line Chart (Plotly) | X: Policy Stage (Before $\rightarrow$ After)<br>Y: Risk Score (0–100)<br>Lines: Donor (amber) vs. Recipient (cyan) | Demonstrates the operational tradeoff: recipient risk plummets while donor risk is managed. |
| **Scenario Audit: Full Before vs. After Comparison** | Complete Comparative Balance Sheet | Supply, Capacity, Demand, Shortage, Pressure, Risk Score, Risk Tier | Detailed audit table verifying the supply conservation invariant. |

---

### Page 7: Data Quality & Methods (`mod_methodology.R`)
*Transparency & Governance: Schema audit, engineering choices, and operational disclaimers.*

| Component Name in UI | Visual Type | Content |
| :--- | :--- | :--- |
| **Dataset Provenance & Verification Audit** | Metadata Card | Dataset source, Kaggle URL, ingestion path, record count, and temporal bounds. |
| **Raw Ingestion Schema & Quality Audit** | Tabular Data Dictionary | All 13 raw attributes, classes, missingness %, and analytical roles. |
| **Data Engineering Decisions** | Technical Callout Cards | Rationale for preserving cancelled rides, zone standardization regex, physical bounds. |
| **Statistical & Simulation Rationale** | Technical Callout Cards | Chronological validation justification, baseline benchmarks, supply conservation. |

---

## 🔬 Mathematical Formulations & Methodologies

### 1. Zone Demand Risk Scoring Engine

The platform implements an interpretable, scenario-based composite operational risk score bounded strictly within $[0, 100]$:

$$\text{Shortage Ratio} = \frac{\max(\text{Forecast Demand} - \text{Estimated Capacity}, 0)}{\max(\text{Forecast Demand}, 1)}$$

$$\text{Risk Score} = 100 \times \left(0.70 \times \text{Shortage Ratio} + 0.20 \times \text{Normalized Growth} + 0.10 \times \text{Normalized Volatility}\right)$$

Where:
* **Estimated Capacity**:
  $$\text{Estimated Capacity} = \text{Virtual Driver Count} \times \text{Rides Served per Driver per Interval}$$
* **Normalized Recent Growth**: Mapped smoothly into $[0, 1]$ over historical 14-day trends:
  $$\text{Normalized Growth} = \frac{\min(1.0, \max(-0.5, \text{Growth Rate})) + 0.5}{1.5} \in [0, 1]$$
* **Normalized Historical Volatility**: Coefficient of variation ($CV = \frac{\sigma}{\mu}$) mapped into $[0, 1]$:
  $$\text{Normalized Volatility} = \frac{\min(1.2, \max(0.0, CV))}{1.2} \in [0, 1]$$

#### Risk Tier Classifications
* **Low Risk ($0 \le \text{Score} \le 30$)**: Capacity easily absorbs demand; surplus driver buffer exists.
* **Moderate Risk ($30 < \text{Score} \le 60$)**: Capacity buffer is narrow; peak intervals may experience minor dispatch delays.
* **High Risk ($60 < \text{Score} \le 80$)**: Significant capacity deficit; elevated surge pricing and cancellations expected.
* **Critical Shortage ($80 < \text{Score} \le 100$)**: Acute driver shortfall; severe unserved passenger demand requiring fleet reallocation.

---

### 2. Time-Series Forecasting & Evaluation

#### Continuous Daily Panel Generation
Raw ride timestamps are aggregated into a daily time series for each urban zone:
$$Y_z = \{y_{z, t}\}_{t=1}^T \quad \text{for } t \in [2024\text{-}06\text{-}17, 2024\text{-}08\text{-}16]$$
Days with zero observed requests are imputed with $0$ rather than dropped, preserving the strict 61-day temporal continuity required by ARIMA models.

#### Chronological Split vs. Random Split
```
Chronological Validation (Strictly Preserves Temporal Ordering):
[================== Training Set (~54 Days) ==================][=== Test Set (7 Days) ===]
                                                                ▲ Evaluated here (Zero Leakage)

Random Splitting (BANNED — Causes Future-to-Past Leakage):
[== Train ==][ Test ][== Train ==][ Test ][======= Train =======][ Test ][== Train ==]
```

#### Evaluation Metrics
Out-of-sample performance is quantified on the 7-day unseen historical holdout window:
* **Mean Absolute Error (MAE)**:
  $$\text{MAE} = \frac{1}{H} \sum_{h=1}^H |y_{T-H+h} - \hat{y}_{T-H+h}|$$
* **Root Mean Squared Error (RMSE)**:
  $$\text{RMSE} = \sqrt{\frac{1}{H} \sum_{h=1}^H (y_{T-H+h} - \hat{y}_{T-H+h})^2}$$
* **Mean Absolute Percentage Error (MAPE)**:
  $$\text{MAPE} = \frac{100}{H} \sum_{h=1}^H \left|\frac{y_{T-H+h} - \hat{y}_{T-H+h}}{y_{T-H+h}}\right| \quad (\text{evaluated on } y > 0)$$

#### Predictive Modeling & Uncertainty Intervals
Full historical series are fit using Seasonal Auto-ARIMA ($(p,d,q)(P,D,Q)_7$) or Exponential Smoothing (ETS). Predictions are bounded physically by non-negativity:
$$\hat{y}_{T+h} = \max(0, \text{Point Forecast})$$
$$\text{Lower Band}_{80/95} = \max(0, \text{Lower CI})$$

---

### 3. What-If Driver Allocation Simulator: Step-by-Step Guide

The simulator allows fleet managers and urban planners to test reallocation interventions before executing them in the field.

```
┌─────────────────────────────────┐                 ┌─────────────────────────────────┐
│        DONOR ZONE               │                 │       RECIPIENT ZONE            │
│  (e.g., Gottigere)              │                 │  (e.g., Koramangala)            │
│  • Demand: ~8.1 rides/day       │                 │  • Demand: ~19.0 rides/day      │
│  • Drivers: 5                   │                 │  • Drivers: 1                   │
│  • Capacity: 30 rides           │                 │  • Capacity: 6 rides            │
│  • Balance: +21.9 (SURPLUS)     │                 │  • Balance: -13.0 (DEFICIT)     │
└────────────────┬────────────────┘                 └────────────────▲────────────────┘
                 │                                                   │
                 └──────────── Transfer 2 Drivers ───────────────────┘
                               (Supply Conserved: 5 + 1 = 3 + 3 = 6)
                               Net Result: 12 Unserved Rides Eliminated!
```

#### Step-by-Step Tutorial
1. **Navigate** to the **What-If Simulator** tab in the top navigation bar.
2. **Select Zones**:
   * Pick a high-demand target in **Recipient Zone** (e.g., `Koramangala` or `Indiranagar`).
   * Pick a supply source in **Donor Zone** (e.g., `Gottigere` or `Begur`).
3. **Inspect the Live HUD**:
   * Notice the real-time feedback badges displaying daily demand vs. initial capacity.
   * If recipient capacity exceeds demand, no shortage exists (delta will be 0).
4. **Configure Drivers or Use Presets**:
   * *Instant Option*: Click **"Acute Peak Deficit (High Impact)"** to load a realistic bottleneck scenario.
   * *Custom Option*: Set Recipient drivers to `1` (creates a ~13-ride deficit) and Donor drivers to `5` (surplus buffer).
5. **Set Reallocation Amount**:
   * Move the slider **"Drivers to Reallocate"** to `2`.
6. **Click "Run What-If Simulation"**:
   * Inspect the KPI cards: Recipient risk plummets by **$-44.2 \text{ pts}$**, net shortage cuts by **$12 \text{ rides}$**, and total drivers are **100% conserved**.
   * Compare the **Demand vs. Capacity Bar Chart** and the **Risk Trajectory Slopegraph**.

---

## 📊 Dataset Ingestion & Schema Audit

* **Source**: [Kaggle: Bangalore Rapido Ride Services Dataset](https://www.kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset)
* **Local Location**: `data/raw/rapido_rides.csv`
* **Cohort Dimensions**: **50,000 rows** $\times$ **13 columns**
* **Temporal Coverage**: **June 17, 2024 to August 16, 2024** (61 consecutive days)

### Schema Table & Data Dictionary

| Column Name | Class | Missing % | Valid Range / Unique | Description & Analytical Role |
| :--- | :--- | :---: | :---: | :--- |
| `services` | character | 0.00% | 5 categories | Modality: `bike` (15,128), `auto` (12,327), `cab economy` (10,202), `parcel` (7,459), `bike lite` (4,884). |
| `date` | character | 0.00% | 61 distinct dates | Calendar date (`YYYY-MM-DD`). Used for daily time-series panel construction. |
| `time` | character | 0.00% | 49,363 distinct | Timestamp (`HH:MM:SS.fraction`). Parsed into hour of day (0–23) and rush windows. |
| `ride_status` | character | 0.00% | 2 levels | Outcome: `completed` (44,964; 89.93%) vs. `cancelled` (5,036; 10.07%). |
| `source` | character | 0.00% | 12,982 points | Granular pickup point. Cleaned via regex into 145 canonical urban zones. |
| `destination` | character | 0.00% | 12,977 points | Granular drop-off point. Cleaned into canonical destination zones. |
| `duration` | integer | 0.00% | 10 to 119 min | Trip duration in minutes. Average completed trip duration is 64.3 min. |
| `ride_id` | character | 0.00% | 50,000 distinct | Unique ride booking tracking identifier (100% unique, zero duplicates). |
| `distance` | numeric | 0.00% | 1.0 to 50.0 km | Road trip distance in kilometers. Mean distance is 25.5 km. |
| `ride_charge` | numeric | 10.07% | ₹50.0 to ₹1,000.0 | Base trip road fare. Exactly 5,036 NAs (matches cancelled rides with no transaction). |
| `misc_charge` | numeric | 10.07% | ₹0.0 to ₹50.0 | Tolls, surge, or platform fee. Exactly 5,036 NAs for cancelled rides. |
| `total_fare` | numeric | 10.07% | ₹50.6 to ₹1,048.8 | Gross passenger fare in INR. Mean completed trip fare is ₹547.4. |
| `payment_method`| character | 10.07% | 4 gateways | Payment gateway: `Paytm` (25.2%), `GPay` (25.1%), `Amazon Pay` (25.0%), `QR scan` (24.8%). |

---

## 🛠️ Installation & Setup Guide

### System Requirements
* **R (v4.2.0 or higher)** — Verified on R 4.6.1 for Windows.
* **CRAN Packages**: `shiny`, `bslib`, `bsicons`, `dplyr`, `tidyr`, `readr`, `janitor`, `lubridate`, `ggplot2`, `plotly`, `DT`, `scales`, `forecast`, `testthat`, `leaflet`.

### Step 1: Clone the Repository
```bash
git clone https://github.com/Manish-N-2006/URBAN-MOBILITY-ANALYSIS-AND-FORECASTING---BIKE.git
cd URBAN-MOBILITY-ANALYSIS-AND-FORECASTING---BIKE
```

### Step 2: Install Package Dependencies
Execute the automated CRAN package installation script:
```bash
Rscript scripts/install_packages.R
```

### Step 3: Run the Data Processing Pipeline
Execute the ETL pipeline to clean the raw CSV and generate optimized `.rds` binaries:
```bash
Rscript scripts/prepare_data.R
```
*Output*:
```
[INFO] Loading raw rides data from: data/raw/rapido_rides.csv
[CLEANING COMPLETE] Input: 50000 rows -> Cleaned: 50000 rows (44964 completed, 5036 cancelled).
[SUCCESS] Saved enriched rides dataset (50000 rows) to data/processed/cleaned_rides.rds
[SUCCESS] Saved continuous daily panel (8845 rows across 145 zones) to data/processed/zone_daily_demand.rds
```

### Step 4: Execute Automated Unit Tests
Verify all 66 unit tests across the 5 test suites:
```bash
Rscript tests/testthat.R
```
*Output*:
```
✔ | F W  S  OK | Context
✔ |         14 | data-cleaning
✔ |          9 | feature-engineering
✔ |         17 | forecasting
✔ |         13 | risk-score
✔ |         13 | simulator

══ Results ═════════════════════════════════════════════════════════════════════
Duration: 2.4 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 66 ]
```

### Step 5: Launch the Shiny Application
Launch the Shiny dashboard on local port 8888:
```bash
Rscript -e "shiny::runApp(appDir = '.', port = 8888, launch.browser = TRUE)"
```
Open your browser to: **`http://127.0.0.1:8888/`**

---

## 🧪 Automated Test Suite Architecture

All core algorithms are covered by unit tests in `tests/testthat/`:

| Test Suite File | Test Count | Key Invariants Verified |
| :--- | :---: | :--- |
| `test-data-cleaning.R` | 14 | Suffix regex stripping, duplicate `ride_id` removal, date/time parsing, status preservation, physics bounds validation ($d > 0, t > 0$). |
| `test-feature-engineering.R` | 9 | Weekday factors, time-of-day bucketing, unit economics, continuous Cartesian grid zero-imputation. |
| `test-forecasting.R` | 17 | Chronological holdout splitting (no random sampling), Seasonal Naive baseline vs. ARIMA, non-negative prediction intervals, sparse series fallback. |
| `test-risk-score.R` | 13 | Score boundedness ($0 \le \text{Score} \le 100$), shortage ratio formula, component weight summation to 1.0, NA input handling. |
| `test-simulator.R` | 13 | **Supply conservation invariant** ($\text{Total}_{\text{Before}} \equiv \text{Total}_{\text{After}}$), donor/recipient inequality constraint, transfer $\le$ donor supply rule, non-negative capacity delta. |
| **Total** | **66** | **100% Pass Rate (0 Failures, 0 Warnings)** |

---

## ⚖️ Governance, Ethics & Operational Disclaimers

1. **Independent Analytical Prototype**: This platform is an independent academic and industrial data science study. It is not an official corporate telemetry feed of Rapido.
2. **Simulation Boundaries**: Virtual driver counts, rides-per-driver assumptions, and reallocation transfers are synthetic scenario inputs for policy testing. They do not represent observed live driver GPS positions.
3. **Spatial Integrity**: In strict adherence to spatial research ethics, no fake GPS coordinates are generated. Only verified OpenStreetMap Nominatim centroids are used.
4. **Predictive Uncertainty**: Forecast models reflect historical patterns under normal operating conditions. Sudden weather anomalies, local transit strikes, or unobserved app outages are outside the model's scope.

---

## 👨‍💻 Author & Attribution

* **Author**: Manish N
* **Repository**: [Manish-N-2006/URBAN-MOBILITY-ANALYSIS-AND-FORECASTING---BIKE](https://github.com/Manish-N-2006/URBAN-MOBILITY-ANALYSIS-AND-FORECASTING---BIKE)
* **Dataset Attribution**: [Vishal Deo Prasad (Kaggle Bangalore Rapido Ride Services Dataset)](https://www.kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset)
* **License**: MIT Open Source License
