# app.R
# Urban Bike Taxi Demand Analysis and Forecasting Intelligence Dashboard
# Powered by R, Shiny, and bslib

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(lubridate)
  library(ggplot2)
  library(plotly)
  library(DT)
  library(scales)
  library(forecast)
  library(leaflet)
})

# Source core logic modules
source("R/config.R")
source("R/data_loader.R")
source("R/data_cleaning.R")
source("R/feature_engineering.R")
source("R/demand_analysis.R")
source("R/hotspot_analysis.R")
source("R/forecasting.R")
source("R/risk_scoring.R")
source("R/what_if_simulator.R")
source("R/dashboard_helpers.R")

# Source UI module components
source("R/mod_overview.R")
source("R/mod_demand_explorer.R")
source("R/mod_hotspots.R")
source("R/mod_forecasting.R")
source("R/mod_risk_analysis.R")
source("R/mod_simulator.R")
source("R/mod_methodology.R")

# Modern Dark Theme Specification via bslib
app_theme <- bs_theme(
  version = 5,
  bootswatch = "darkly",
  primary = CONFIG$theme$primary,
  secondary = CONFIG$theme$secondary,
  success = CONFIG$theme$success,
  warning = CONFIG$theme$warning,
  danger = CONFIG$theme$danger,
  bg = CONFIG$theme$dark_bg,
  fg = CONFIG$theme$text,
  base_font = font_google("Inter")
)

# Main Dashboard UI Layout
ui <- page_navbar(
  title = div(
    class = "d-flex align-items-center",
    icon("bicycle", class = "me-2 text-info fs-4"),
    span("Urban Mobility Intelligence", class = "fw-bold fs-5"),
    span(" | Bangalore Bike Taxi Analytics", class = "text-muted small ms-2 d-none d-md-inline")
  ),
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css")
  ),
  theme = app_theme,
  fillable = FALSE,
  id = "nav_tabs",
  
  # Page 1: Overview
  nav_panel(
    title = "Overview",
    icon = icon("gauge-high"),
    overview_ui("overview")
  ),
  
  # Page 2: Demand Explorer
  nav_panel(
    title = "Demand Explorer",
    icon = icon("magnifying-glass-chart"),
    demand_explorer_ui("demand_explorer")
  ),
  
  # Page 3: Hotspots and Zones
  nav_panel(
    title = "Hotspots & Zones",
    icon = icon("map-location-dot"),
    hotspots_ui("hotspots")
  ),
  
  # Page 4: Demand Forecasting
  nav_panel(
    title = "Forecasting",
    icon = icon("chart-line"),
    forecasting_ui("forecasting")
  ),
  
  # Page 5: Zone Risk Analysis
  nav_panel(
    title = "Zone Risk Analysis",
    icon = icon("triangle-exclamation"),
    risk_analysis_ui("risk_analysis")
  ),
  
  # Page 6: What-If Driver Allocation Simulator
  nav_panel(
    title = "What-If Simulator",
    icon = icon("sliders"),
    simulator_ui("simulator")
  ),
  
  # Page 7: Data Quality & Methodology
  nav_panel(
    title = "Data Quality & Methods",
    icon = icon("book-open"),
    methodology_ui("methodology")
  ),
  
  # Header info & status badge
  nav_spacer(),
  nav_item(
    span(
      class = "badge rounded-pill bg-dark border border-secondary text-info px-3 py-2 my-auto",
      icon("database", class = "me-1"),
      "Bangalore Rapido (50k Rides)"
    )
  )
)

# Pre-load datasets globally for instantaneous UI initialization
INITIAL_RIDES_DF <- NULL
INITIAL_PANEL_DF <- NULL

if (file.exists(CONFIG$processed_rides_rds) && file.exists(CONFIG$zone_daily_demand_rds)) {
  INITIAL_RIDES_DF <- readRDS(CONFIG$processed_rides_rds)
  INITIAL_PANEL_DF <- readRDS(CONFIG$zone_daily_demand_rds)
}

# Main Application Server Logic
server <- function(input, output, session) {
  
  # Shared data reactive storage (instantly populated from global cache)
  shared_data <- reactiveValues(
    rides_df = INITIAL_RIDES_DF,
    daily_panel = INITIAL_PANEL_DF,
    data_loaded = !is.null(INITIAL_RIDES_DF),
    error_message = NULL
  )
  
  # Fallback ingestion if not yet preloaded
  observe({
    if (is.null(shared_data$rides_df)) {
      status <- check_raw_data_available()
      if (!status$available) {
        shared_data$error_message <- status$message
        showModal(modalDialog(
          title = div(icon("triangle-exclamation", class = "text-danger me-2"), "Raw Dataset Required"),
          p("The Bangalore Rapido Ride Services dataset was not detected in ", code("data/raw/rapido_rides.csv")),
          p("Please place the downloaded CSV in ", code("data/raw/rapido_rides.csv"), " and restart the application."),
          easyClose = TRUE,
          footer = modalButton("Close")
        ))
        return()
      }
      
      tryCatch({
        raw_df <- load_raw_rides()
        cleaned_df <- clean_rides_data(raw_df)
        enriched_df <- engineer_ride_features(cleaned_df)
        saveRDS(enriched_df, CONFIG$processed_rides_rds)
        panel <- build_zone_daily_panel(enriched_df, min_zone_total_rides = 20)
        saveRDS(panel, CONFIG$zone_daily_demand_rds)
        
        shared_data$rides_df <- enriched_df
        shared_data$daily_panel <- panel
        shared_data$data_loaded <- TRUE
      }, error = function(e) {
        showNotification(paste("ETL Error:", e$message), type = "error")
      })
    }
  })
  
  # Instantiate Server Modules
  overview_server("overview", shared_data)
  demand_explorer_server("demand_explorer", shared_data)
  hotspots_server("hotspots", shared_data)
  forecasting_server("forecasting", shared_data)
  risk_analysis_server("risk_analysis", shared_data)
  simulator_server("simulator", shared_data)
  methodology_server("methodology", shared_data)
}

# Run Shiny Application
shinyApp(ui = ui, server = server)
