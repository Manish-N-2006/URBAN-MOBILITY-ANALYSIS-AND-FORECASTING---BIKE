# R/mod_methodology.R
# Data Quality, Methodology, Schema Audit, and Transparency Documentation Module

methodology_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Provenance Header Card
    card(
      class = "mb-3 border-0 shadow-sm",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Dataset Provenance & Verification Audit", class = "fw-bold"),
        span(class = "badge bg-primary", "Kaggle Open Data")
      ),
      card_body(
        layout_column_wrap(
          width = 1/2,
          div(
            h6("Source Repository Information", class = "fw-bold text-info"),
            p("Dataset: ", strong("Bangalore Rapido Ride Services Dataset")),
            p("Source: ", a(href = "https://www.kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset",
                            "kaggle.com/datasets/vishaldeoprasad/bangalore-rapido-ride-services-dataset", target = "_blank")),
            p("Temporal Coverage: ", strong("June 17, 2024 to August 16, 2024 (61 consecutive calendar days)")),
            p("Total Observed Ingestion: ", strong("50,000 ride booking records across 13 raw attributes"))
          ),
          div(
            callout_card(
              title = "Operational Disclaimer",
              message = "This platform is an independent analytical study and decision-support prototype. It is not an official Rapido corporate telemetry feed. Driver counts, fleet supplies, and reallocation outcomes are scenario simulations for decision engineering.",
              type = "warning"
            )
          )
        )
      )
    ),
    
    # Schema Audit Table Card
    card(
      class = "shadow-sm border-0 mb-3",
      card_header("Raw Ingestion Schema & Quality Audit", class = "fw-bold"),
      card_body(
        tableOutput(ns("schema_audit_table"))
      )
    ),
    
    # Methodology Deep Dives Row
    layout_column_wrap(
      width = 1/2,
      card(
        class = "shadow-sm border-0",
        card_header("Data Engineering Decisions", class = "fw-bold"),
        card_body(
          h6("1. Missing Value Treatment", class = "fw-bold text-primary"),
          p("Exactly 5,036 records exhibit NA values in ride_charge, misc_charge, total_fare, and payment_method. This matches the 5,036 cancelled ride requests (10.07%). Cancelled rides are preserved to accurately assess unmet demand pressure."),
          h6("2. Urban Zone Standardization", class = "fw-bold text-primary"),
          p("The raw dataset contained 12,982 micro-street names with development suffixes (e.g., 'Basavanagudi 3rd Block', 'Kothanur Landing'). To make continuous daily time-series forecasting feasible, suffixes were stripped to reveal parent Bangalore zones while retaining original raw strings."),
          h6("3. Physical Bounds Validation", class = "fw-bold text-primary"),
          p("Records are validated for positive physical distance (>0 km) and duration (>0 min). Calculated speeds average 24-28 km/h, consistent with Bangalore urban traffic.")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header("Statistical & Simulation Rationale", class = "fw-bold"),
        card_body(
          h6("1. Chronological vs. Random Splitting", class = "fw-bold text-primary"),
          p("Time series data possesses autocorrelation. Random cross-validation leaks future information into training. We enforce a strictly chronological split (first 54 days training, final 7 days holdout validation)."),
          h6("2. Baseline vs. Predictive Model Benchmark", class = "fw-bold text-primary"),
          p("Every ARIMA model is benchmarked against a Seasonal Naive baseline on identical holdout windows. Real-world evaluation metrics (MAE and RMSE) quantify predictive lift."),
          h6("3. Supply Conservation Invariant", class = "fw-bold text-primary"),
          p("In the What-If Simulator, virtual driver supply is mathematically conserved: Donor Drivers (After) + Recipient Drivers (After) == Donor Drivers (Before) + Recipient Drivers (Before). Negative driver counts are physically prevented.")
        )
      )
    )
  )
}

methodology_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    output$schema_audit_table <- renderTable({
      data.frame(
        Field = c("services", "date", "time", "ride_status", "source", "destination", "duration", "ride_id", "distance", "ride_charge", "misc_charge", "total_fare", "payment_method"),
        Data_Type = c("Character", "Date (YYYY-MM-DD)", "Time (HH:MM:SS)", "Character", "Character", "Character", "Numeric", "Character", "Numeric", "Numeric", "Numeric", "Numeric", "Character"),
        Missing_Rate = c("0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "10.07%", "10.07%", "10.07%", "10.07%"),
        Analytical_Role = c(
          "Service modality: bike, bike lite, auto, cab economy, parcel",
          "Calendar date for daily time series panel construction",
          "Timestamp for hourly diurnal demand curve extraction",
          "Observed outcome: completed (89.9%) vs cancelled (10.1%)",
          "Pickup location string; standardized into pickup_zone",
          "Dropoff location string; standardized into dropoff_zone",
          "Trip duration in minutes (completed and cancelled attempts)",
          "Unique ride tracking identifier (50,000 distinct values)",
          "Trip road distance in kilometers",
          "Base fare charge in Indian Rupees (NA for cancelled rides)",
          "Tolls, surge, or platform charges (NA for cancelled)",
          "Gross trip fare in INR (NA for cancelled rides)",
          "Payment gateway / mode (GPay, Paytm, Amazon Pay, QR scan)"
        ),
        stringsAsFactors = FALSE
      )
    }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")
    
  })
}
