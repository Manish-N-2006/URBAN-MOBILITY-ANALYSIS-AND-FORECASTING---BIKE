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

---

### 1. Zone Demand Risk Scoring Engine (0 to 100)

#### Intuition & Purpose
Fleet managers need a single, explainable metric to answer: *"Which urban zones face the most dangerous supply-demand imbalance tomorrow?"* Rather than using an uninterpretable machine-learning score, the platform calculates a deterministic, composite risk score bounded strictly within $[0, 100]$.

#### The Master Risk Equation

$$
\text{Risk Score} = 100 \times \left( 0.70 \cdot \text{Shortage Ratio} + 0.20 \cdot \text{Normalized Growth} + 0.10 \cdot \text{Normalized Volatility} \right)
$$

The final score is strictly clamped to ensure physical validity:

$$
\text{Final Risk Score} = \min\left(100, \, \max\left(0, \, \text{Round}(\text{Risk Score}, \, 1)\right)\right)
$$

---

#### Component 1: Capacity Shortage Ratio (70% Weight)
Quantifies what percentage of passenger ride demand cannot be fulfilled by the active driver fleet:

$$
\text{Estimated Capacity} = \text{Virtual Drivers} \times \text{Rides Served per Driver per Day}
$$

$$
\text{Capacity Shortage} = \max\left( \text{Forecast Demand} - \text{Estimated Capacity}, \; 0 \right)
$$

$$
\text{Shortage Ratio} = \frac{\text{Capacity Shortage}}{\max\left( \text{Forecast Demand}, \; 1 \right)} \in [0, 1]
$$

> **Why the max terms?**
> * $\max(\dots, 0)$ prevents surplus capacity from creating negative shortage.
> * $\max(\dots, 1)$ prevents division-by-zero errors when forecast demand is zero.

---

#### Component 2: Normalized Recent Growth (20% Weight)
Captures demand surge momentum over the preceding 14-day window. Growth is clamped between $-50\%$ and $+100\%$ and mapped linearly into $[0, 1]$:

$$
\text{Clamped Growth} = \max\left( -0.50, \; \min\left( 1.00, \; \text{Observed Growth Rate} \right) \right)
$$

$$
\text{Normalized Growth} = \frac{\text{Clamped Growth} + 0.50}{1.50} \in [0, 1]
$$

* If demand contracted by $\ge 50\%$: $\text{Normalized Growth} = 0.0$ (lowest growth strain).
* If demand remained static ($0\%$ growth): $\text{Normalized Growth} = \frac{0 + 0.5}{1.5} \approx 0.333$.
* If demand surged by $\ge 100\%$: $\text{Normalized Growth} = 1.0$ (maximum growth strain).

---

#### Component 3: Normalized Historical Volatility (10% Weight)
Measures dispatch unpredictability using the Coefficient of Variation ($CV = \frac{\sigma}{\mu}$), where higher variance demands higher contingency buffers:

$$
CV = \frac{\sigma_{\text{historical}}}{\mu_{\text{historical}}} = \frac{\text{Standard Deviation of Daily Demand}}{\text{Mean Daily Demand}}
$$

$$
\text{Clamped } CV = \max\left( 0.0, \; \min\left( 1.20, \; CV \right) \right)
$$

$$
\text{Normalized Volatility} = \frac{\text{Clamped } CV}{1.20} \in [0, 1]
$$

---

#### Complete Variable Dictionary

| Symbol / Parameter | Code Variable | Default | Valid Range | Physical Description |
| :--- | :--- | :---: | :---: | :--- |
| $\hat{Y}_z$ | `forecast_demand` | *Zone Forecast* | $[0, \infty)$ rides/day | Projected daily ride booking requests for zone $z$. |
| $D_z$ | `virtual_driver_count` | 5 drivers | $[0, \infty)$ drivers | Active bike-taxi drivers assigned to zone $z$. |
| $\kappa$ | `rides_per_driver` | 6 rides/day | $(0, 24]$ rides | Realistic completed trips a single driver serves daily. |
| $C_z = D_z \cdot \kappa$ | `estimated_capacity` | $5 \times 6 = 30$ | $[0, \infty)$ rides/day | Total ride serving capacity in zone $z$. |
| $S_z$ | `capacity_shortage` | $\max(\hat{Y}_z - C_z, 0)$ | $[0, \infty)$ rides | Unmet passenger requests facing cancellation or delays. |
| $SR_z$ | `shortage_ratio` | $S_z / \max(\hat{Y}_z, 1)$ | $[0, 1]$ ratio | Proportion of total demand that goes unserved. |
| $g_z$ | `recent_growth_rate` | 0.00 (flat) | $[-0.5, +1.0]$ | 14-day demand acceleration: $\frac{\bar{y}_{\text{recent}} - \bar{y}_{\text{prior}}}{\bar{y}_{\text{prior}}}$. |
| $CV_z$ | `historical_cv` | 0.25 | $[0.0, 1.2]$ | Ratio of demand standard deviation to mean ($\sigma / \mu$). |

---

#### Step-by-Step Calculation Example with Real Numbers

Consider **Koramangala** during an evening peak deficit scenario:
* **Forecast Demand**: $\hat{Y} = 19.0 \text{ rides/day}$
* **Virtual Drivers**: $D = 1 \text{ driver}$
* **Rides per Driver**: $\kappa = 6 \text{ rides/driver/day}$
* **Recent Growth**: $g = +0.10 \text{ (+10% growth)}$
* **Volatility**: $CV = 0.30$

$$\begin{aligned}
\text{1. Estimated Capacity} &= 1 \times 6 = \mathbf{6.0 \text{ rides}} \\
\text{2. Shortage} &= \max(19.0 - 6.0, \; 0) = \mathbf{13.0 \text{ unserved rides}} \\
\text{3. Shortage Ratio} &= \frac{13.0}{\max(19.0, 1)} = \mathbf{0.6842} \\
\text{4. Normalized Growth} &= \frac{0.10 + 0.50}{1.50} = \frac{0.60}{1.50} = \mathbf{0.4000} \\
\text{5. Normalized Volatility} &= \frac{0.30}{1.20} = \mathbf{0.2500}
\end{aligned}$$

Now, compute the weighted point contributions:

$$\begin{aligned}
\text{Shortage Points} &= 100 \times 0.70 \times 0.6842 = \mathbf{47.9 \text{ pts}} \\
\text{Growth Points} &= 100 \times 0.20 \times 0.4000 = \mathbf{8.0 \text{ pts}} \\
\text{Volatility Points} &= 100 \times 0.10 \times 0.2500 = \mathbf{2.5 \text{ pts}} \\
\hline
\mathbf{\text{Total Risk Score}} &= 47.9 + 8.0 + 2.5 = \mathbf{58.4 \text{ pts}} \quad \text{(Tier: Moderate Risk / Elevated Strain)}
\end{aligned}$$

---

#### Risk Tier Classifications & Operational Protocols

| Tier Name | Score Range | Badge Color | Operational Diagnosis | Prescribed Fleet Action |
| :--- | :---: | :---: | :--- | :--- |
| **Low Risk** | $0 \le \text{Score} \le 30$ | `#22c55e` (Green) | Capacity comfortably absorbs demand; surplus driver buffer exists. | Eligible to serve as **Donor Zone** in reallocation. |
| **Moderate Risk** | $30 < \text{Score} \le 60$ | `#eab308` (Yellow) | Capacity buffer is narrow; minor dispatch delays during peak hours. | Monitor dispatch queues; maintain assigned drivers. |
| **High Risk** | $60 < \text{Score} \le 80$ | `#f97316` (Orange) | Significant driver deficit; surge pricing & cancellations elevated. | Primary candidate for driver transfers from low-risk zones. |
| **Critical Shortage** | $80 < \text{Score} \le 100$ | `#ef4444` (Red) | Severe capacity shortfall; acute unserved passenger volume. | Urgent: Dispatch virtual fleet reallocations immediately. |

---

### 2. Time-Series Forecasting & Chronological Validation

#### Continuous Daily Panel Formulation
For each canonical zone $z \in \{1, \dots, 145\}$, daily request counts are aggregated into an unbroken temporal sequence:

$$
Y_z = \left[ y_{z, 1}, \, y_{z, 2}, \, \dots, \, y_{z, T} \right] \quad \text{for } t = 1, \dots, 61 \quad (\text{June 17 to August 16, 2024})
$$

Days with zero ride requests are explicitly imputed with $y_{z, t} = 0$ rather than dropped, preserving the strict 61-day temporal continuity required by ARIMA difference operators.

---

#### Chronological Validation Split (Leak-Free Protocol)
To ensure honest out-of-sample benchmarking, the platform strictly enforces chronological time-series splitting:

```
Full Historical Time-Series (T = 61 Calendar Days):
[===================== Training Set (54 Days) =====================][=== Holdout Test Set (7 Days) ===]
 June 17, 2024 ──────────────────────────────────────── August 9, 2024 │ August 10, 2024 ───── August 16, 2024
                                                                       ▲ Evaluated Here (Zero Data Leakage)
```

$$\text{Training Set: } t \in \{1, \dots, T - H\} \quad \text{where } T = 61, \; H = 7$$

$$\text{Test Holdout: } t \in \{T - H + 1, \dots, T\} \quad (\text{final 7 consecutive days})$$

---

#### Models Evaluated

1. **Seasonal Naive Benchmark (`snaive`)**:
   Projects demand forward based strictly on the matching day-of-week from 7 days prior:
   $$\hat{y}_{T-H+h}^{\text{snaive}} = y_{(T-H+h) - 7}$$

2. **Seasonal Auto-ARIMA Model ($(p, d, q) \times (P, D, Q)_7$)**:
   Selects optimal autoregressive, differencing, and moving average orders under weekly periodicity ($s = 7$):
   $$\Phi(B^7) \, \phi(B) \, (1 - B^7)^D \, (1 - B)^d \, y_t = \Theta(B^7) \, \theta(B) \, \epsilon_t$$
   Where $B$ is the backshift operator ($B^k y_t = y_{t-k}$), and $\epsilon_t \sim \mathcal{WN}(0, \sigma^2)$ is white noise error.

---

#### Out-of-Sample Evaluation Metrics

On the unseen 7-day holdout set, empirical error metrics are calculated as follows:

* **Mean Absolute Error (MAE)**:
  Measures the average error magnitude in exact daily ride units:
  $$\text{MAE} = \frac{1}{H} \sum_{h=1}^{H} \left| y_{T-H+h} - \hat{y}_{T-H+h} \right|$$

* **Root Mean Squared Error (RMSE)**:
  Penalizes large forecast spikes and outlier days heavily:
  $$\text{RMSE} = \sqrt{\frac{1}{H} \sum_{h=1}^{H} \left( y_{T-H+h} - \hat{y}_{T-H+h} \right)^2}$$

* **Mean Absolute Percentage Error (MAPE)**:
  Measures percentage error across days with non-zero observed demand:
  $$\text{MAPE} = \frac{100\%}{H^*} \sum_{\substack{h=1 \\ y_{T-H+h} > 0}}^{H} \left| \frac{y_{T-H+h} - \hat{y}_{T-H+h}}{y_{T-H+h}} \right| \quad \text{where } H^* = \sum_{h=1}^H \mathbf{1}_{\{y_{T-H+h} > 0\}}$$

---

#### Physical Non-Negativity Bounding
Because passenger demand and prediction interval lower bounds cannot be negative in the physical world, all model outputs are truncated at zero:

$$\hat{y}_{T+h}^{\text{physical}} = \max\left(0, \; \hat{y}_{T+h}\right)$$

$$\text{Lower Band}_{80/95}^{\text{physical}} = \max\left(0, \; \text{Lower CI}_{80/95}\right)$$

---

### 3. Invariant-Preserving "What-If" Simulator Formulation

The simulator models policy interventions where a fleet manager reallocates $\Delta D$ virtual drivers from a **Donor Zone** ($A$) to a **Recipient Zone** ($B$).

#### 1. Conservation of Fleet Supply Invariant
The total driver supply across both zones must remain strictly constant before and after the intervention:

$$
S_{\text{total}} = D_A^{\text{initial}} + D_B^{\text{initial}} \equiv D_A^{\text{post}} + D_B^{\text{post}}
$$

#### 2. Reallocation Transfer Rules & Physical Bounds

$$
D_A^{\text{post}} = D_A^{\text{initial}} - \Delta D \quad \text{subject to } 0 \le \Delta D \le D_A^{\text{initial}}
$$

$$
D_B^{\text{post}} = D_B^{\text{initial}} + \Delta D \quad \text{subject to } \Delta D \ge 0
$$

> **Physical Constraint**: The platform physically disallows transferring more drivers than the donor zone possesses ($\Delta D \le D_A^{\text{initial}}$), ensuring $D_A^{\text{post}} \ge 0$.

#### 3. Post-Transfer Capacity & Deficit Impact

$$\begin{aligned}
\text{Capacity}_A^{\text{post}} &= D_A^{\text{post}} \times \kappa \\
\text{Capacity}_B^{\text{post}} &= D_B^{\text{post}} \times \kappa \\
\text{Shortage}_B^{\text{post}} &= \max\left(\hat{Y}_B - \text{Capacity}_B^{\text{post}}, \; 0\right)
\end{aligned}$$

#### 4. Systemic Net Benefit Metrics

* **Unserved Rides Eliminated**:
  $$\Delta \text{Unserved Demand} = \text{Shortage}_B^{\text{initial}} - \text{Shortage}_B^{\text{post}} \ge 0$$

* **Recipient Risk Points Mitigated**:
  $$\Delta \text{Risk}_B = \text{Risk Score}_B^{\text{post}} - \text{Risk Score}_B^{\text{initial}} < 0 \quad (\text{Risk reduced})$$

* **Donor Risk Tradeoff**:
  $$\Delta \text{Risk}_A = \text{Risk Score}_A^{\text{post}} - \text{Risk Score}_A^{\text{initial}} \ge 0 \quad (\text{Tradeoff tracked})$$

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
