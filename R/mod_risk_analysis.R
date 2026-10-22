# R/mod_risk_analysis.R
# Zone Demand Risk Scoring Module: Formula Explanation, Sensitivity & Rankings

risk_analysis_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Formula & Rationale Callout
    card(
      class = "mb-3 border-0 shadow-sm",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Zone Demand Risk Score Architecture & Formula", class = "fw-bold"),
        span(class = "badge bg-warning text-dark", "Analytical Metric")
      ),
      card_body(
        callout_card(
          title = "Risk Score Formulation (0 to 100 Scale)",
          message = "The Zone Demand Risk Score measures potential urban operational imbalance on a transparent 0-100 scale. It integrates three orthogonal components: (1) Capacity Shortage (70% weight): the proportion of forecast demand exceeding virtual driver service capacity; (2) Recent Demand Growth (20% weight): trend acceleration over the last 14 days; and (3) Historical Demand Volatility (10% weight): coefficient of variation across historical daily observations.",
          type = "info"
        ),
        div(
          style = "background: rgba(15, 23, 42, 0.6); padding: 14px 18px; border-radius: 6px; font-family: monospace; font-size: 0.95rem; color: #38bdf8; margin-bottom: 15px;",
          "shortage_ratio = max(forecast_demand - estimated_capacity, 0) / max(forecast_demand, 1)",
          br(),
          "estimated_capacity = virtual_driver_count * rides_per_driver_per_interval",
          br(),
          "risk_score = 100 * (0.70 * shortage_ratio + 0.20 * normalized_growth + 0.10 * normalized_volatility)"
        ),
        layout_column_wrap(
          width = 1/2,
          sliderInput(
            ns("drivers_per_zone"),
            "Baseline Virtual Drivers per Zone:",
            min = 1, max = 150, value = 30, step = 1
          ),
          sliderInput(
            ns("rides_per_driver"),
            "Assumed Rides Completed / Driver / Day:",
            min = 2, max = 20, value = 8, step = 1
          )
        )
      )
    ),
    
    # Tier Summary KPIs
    uiOutput(ns("tier_kpi_cards")),
    
    # Visualizations: Stacked Decomposition
    card(
      class = "shadow-sm border-0 mb-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Risk Score Component Decomposition (Top 15 Most Strained Zones)", class = "fw-bold"),
        span(class = "badge bg-primary", "Explainable Contributions")
      ),
      card_body(
        plotlyOutput(ns("risk_decomposition_plot"), height = "360px")
      )
    ),
    
    # Comprehensive Risk Ranking Table
    card(
      class = "shadow-sm border-0",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Bangalore Urban Zones Risk Scoreboard", class = "fw-bold"),
        span(class = "badge bg-secondary", "All Active Zones")
      ),
      card_body(
        DTOutput(ns("risk_table"))
      )
    )
  )
}

risk_analysis_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive Multi-zone Risk Score Computation
    risk_table_data <- reactive({
      req(shared_data$daily_panel)
      panel <- shared_data$daily_panel
      
      # Compute average daily forecast demand per zone from recent 14-day history
      zones <- unique(panel$pickup_zone)
      zone_forecasts <- list()
      for (z in zones) {
        z_hist <- panel %>% filter(pickup_zone == z) %>% pull(demand_requests)
        # Recent 7-day average as indicative forecast
        zone_forecasts[[z]] <- max(1, round(mean(tail(z_hist, 7)), 1))
      }
      
      compute_multi_zone_risk_table(
        panel = panel,
        zone_forecasts = zone_forecasts,
        default_drivers = input$drivers_per_zone,
        rides_per_driver = input$rides_per_driver
      )
    })
    
    # Tier KPI Cards
    output$tier_kpi_cards <- renderUI({
      df <- risk_table_data()
      if (nrow(df) == 0) return(NULL)
      
      n_critical <- sum(df$Risk_Tier == "Critical Shortage")
      n_high <- sum(df$Risk_Tier == "High Risk")
      n_moderate <- sum(df$Risk_Tier == "Moderate Risk")
      n_low <- sum(df$Risk_Tier == "Low Risk")
      
      layout_column_wrap(
        width = 1/4,
        class = "mb-4",
        saas_kpi_card(
          title = "Critical Shortage",
          value = as.character(n_critical),
          subtitle = "Score > 80 (Severe deficit)",
          icon_name = "triangle-exclamation",
          accent_color = "#f43f5e",
          badge_text = "Action Required",
          badge_type = "danger"
        ),
        saas_kpi_card(
          title = "High Strain Zones",
          value = as.character(n_high),
          subtitle = "Score 60 - 80 (Shortage likely)",
          icon_name = "circle-exclamation",
          accent_color = "#f97316",
          badge_text = "Monitor",
          badge_type = "warning"
        ),
        saas_kpi_card(
          title = "Moderate Risk",
          value = as.character(n_moderate),
          subtitle = "Score 30 - 60 (Narrow buffer)",
          icon_name = "circle-info",
          accent_color = "#eab308",
          badge_text = "Adequate",
          badge_type = "warning"
        ),
        saas_kpi_card(
          title = "Low Risk Hubs",
          value = as.character(n_low),
          subtitle = "Score < 30 (Sufficient supply)",
          icon_name = "circle-check",
          accent_color = "#10b981",
          badge_text = "Stable",
          badge_type = "success"
        )
      )
    })
    
    # Risk Decomposition Plot
    output$risk_decomposition_plot <- renderPlotly({
      df <- risk_table_data()
      req(nrow(df) > 0)
      
      top_strained <- head(df, 15)
      
      p <- plot_ly(top_strained, x = ~reorder(Zone, Risk_Score)) %>%
        add_bars(
          y = ~Shortage_Contrib,
          name = "Capacity Shortage (70% weight)",
          marker = list(color = "#ef4444")
        ) %>%
        add_bars(
          y = ~Growth_Contrib,
          name = "Demand Growth (20% weight)",
          marker = list(color = "#f59e0b")
        ) %>%
        add_bars(
          y = ~Volatility_Contrib,
          name = "Demand Volatility (10% weight)",
          marker = list(color = "#0284c7")
        ) %>%
        layout(
          barmode = "stack",
          xaxis = list(title = "Urban Zone", tickangle = -35),
          yaxis = list(title = "Risk Score Points (0 - 100)", range = c(0, 100))
        )
      
      style_plotly(p)
    })
    
    # Risk Score Table
    output$risk_table <- renderDT({
      df <- risk_table_data()
      req(nrow(df) > 0)
      
      datatable(
        df %>% select(
          Zone,
          `Risk Score` = Risk_Score,
          `Risk Tier` = Risk_Tier,
          `Forecast Demand` = Forecast_Demand,
          `Virtual Drivers` = Virtual_Drivers,
          `Capacity (Rides)` = Estimated_Capacity,
          `Unmet Shortage` = Shortage,
          `Demand Pressure` = Demand_Pressure,
          `Shortage Pts` = Shortage_Contrib,
          `Growth Pts` = Growth_Contrib,
          `Volatility Pts` = Volatility_Contrib
        ),
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "frtip",
          order = list(list(1, "desc"))
        ),
        rownames = FALSE,
        class = "table-hover compact stripe"
      ) %>%
        formatRound(c("Risk Score", "Demand Pressure", "Shortage Pts", "Growth Pts", "Volatility Pts"), digits = 1)
    })
    
  })
}
