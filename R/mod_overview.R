# R/mod_overview.R
# Overview Tab: Executive KPIs, Service Mix, Daily Timeline, and System Snapshot

overview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Hero Command Center Banner
    div(
      class = "hero-banner",
      div(
        class = "d-flex justify-content-between align-items-center flex-wrap gap-3",
        div(
          div(
            class = "d-inline-flex align-items-center px-3 py-1 rounded-pill mb-2",
            style = "background: rgba(16, 185, 129, 0.12); border: 1px solid rgba(16, 185, 129, 0.3); font-size: 0.78rem; font-weight: 600; color: #34d399;",
            span(class = "pulse-indicator"),
            "BANGALORE URBAN TELEMETRY ACTIVE • RAPIDO 50K COHORT"
          ),
          h3("Urban Bike Taxi Demand & Operational Intelligence", class = "fw-bold text-white mb-1", style = "font-family: 'Outfit', sans-serif;"),
          p("Real-time exploratory analytics, diurnal transit dynamics, risk detection, and driver allocation simulator.", class = "text-muted mb-0", style = "font-size: 0.92rem;")
        ),
        div(
          class = "d-flex gap-2 flex-wrap",
          div(
            class = "px-3 py-2 rounded text-center",
            style = "background: rgba(15, 23, 42, 0.7); border: 1px solid var(--border-subtle); min-width: 110px;",
            div(class = "text-muted small", "OBSERVED SPAN"),
            div(class = "fw-bold text-white", "61 Days")
          ),
          div(
            class = "px-3 py-2 rounded text-center",
            style = "background: rgba(15, 23, 42, 0.7); border: 1px solid var(--border-subtle); min-width: 110px;",
            div(class = "text-muted small", "ACTIVE HUBS"),
            div(class = "fw-bold text-info", "145 Zones")
          ),
          div(
            class = "px-3 py-2 rounded text-center",
            style = "background: rgba(15, 23, 42, 0.7); border: 1px solid var(--border-subtle); min-width: 110px;",
            div(class = "text-muted small", "BIKE SHARE"),
            div(class = "fw-bold text-warning", "40.0%")
          )
        )
      )
    ),
    
    # Filter Bar Card
    card(
      class = "mb-4 border-0 shadow-sm",
      card_body(
        class = "py-3",
        layout_column_wrap(
          width = 1/3,
          selectInput(
            ns("service_filter"),
            "Filter Modality:",
            choices = c("All Services", "Bike Taxi Only (Bike + Bike Lite)", "Auto", "Cab Economy", "Parcel"),
            selected = "All Services"
          ),
          dateRangeInput(
            ns("date_range"),
            "Date Window:",
            start = "2024-06-17",
            end = "2024-08-16",
            min = "2024-06-17",
            max = "2024-08-16"
          ),
          div(
            style = "display: flex; align-items: flex-end; height: 100%;",
            actionButton(ns("reset_filters"), "Reset Filters", icon = icon("rotate-left"), class = "btn-outline-secondary w-100")
          )
        )
      )
    ),
    
    # High-Impact KPI Row
    uiOutput(ns("kpi_cards")),
    
    # Visualizations Row 1
    layout_column_wrap(
      width = 1/2,
      class = "mb-4",
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Service Modality Breakdown & Cancellation Rates", class = "fw-bold"),
          span(class = "badge bg-info", "Fleet Distribution")
        ),
        card_body(
          plotlyOutput(ns("service_mix_plot"), height = "340px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Daily Demand Trajectory & 7-Day Moving Trend", class = "fw-bold"),
          span(class = "badge bg-primary", "Time-Series Flow")
        ),
        card_body(
          plotlyOutput(ns("daily_trend_plot"), height = "340px")
        )
      )
    ),
    
    # Bottom Row: Top Zones & Urban Transit Dynamics
    layout_column_wrap(
      width = 1/2,
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Highest-Demand Bangalore Zones (Observed Requests)", class = "fw-bold"),
          span(class = "badge bg-secondary", "Urban Hotspots")
        ),
        card_body(
          plotlyOutput(ns("top_zones_quick_plot"), height = "320px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Urban Transit Operational Protocols", class = "fw-bold"),
          span(class = "badge bg-success", "Methodology")
        ),
        card_body(
          callout_card(
            title = "Demand Request vs. Fulfilled Trip Distinction",
            message = "Every ingested record corresponds to an initial passenger ride booking request. 10.07% of requests ended in pre-dispatch or en-route cancellation without financial settlement (hence NA fare). Completed trips (89.93%) represent fulfilled demand. Analyzing raw requests allows the platform to quantify true transit pressure.",
            type = "info"
          ),
          callout_card(
            title = "Two-Wheeler Urban Agility Advantage",
            message = "Two-wheelers ('Bike' and 'Bike Lite') constitute the dominant single modality in Bangalore (40.02% of all trips), providing critical last-mile connectivity through traffic bottlenecks in Outer Ring Road, Indiranagar, and Whitefield.",
            type = "success"
          )
        )
      )
    )
  )
}

overview_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    # Reset filters observer (FIX: input$reset_filters, NOT input("reset_filters"))
    observeEvent(input$reset_filters, {
      updateSelectInput(session, "service_filter", selected = "All Services")
      updateDateRangeInput(session, "date_range", start = "2024-06-17", end = "2024-08-16")
    })
    
    # Filtered dataset reactive
    filtered_df <- reactive({
      req(shared_data$rides_df)
      df <- shared_data$rides_df
      
      # Service filter
      if (input$service_filter == "Bike Taxi Only (Bike + Bike Lite)") {
        df <- df %>% filter(is_bike_service)
      } else if (input$service_filter != "All Services") {
        svc_map <- c("Auto" = "auto", "Cab Economy" = "cab economy", "Parcel" = "parcel")
        df <- df %>% filter(services == svc_map[input$service_filter])
      }
      
      # Date filter
      if (!is.null(input$date_range)) {
        df <- df %>% filter(ride_date >= input$date_range[1] & ride_date <= input$date_range[2])
      }
      
      df
    })
    
    # Dynamic KPI Cards Output
    output$kpi_cards <- renderUI({
      df <- filtered_df()
      req(nrow(df) > 0)
      kpis <- compute_overall_kpis(df)
      
      layout_column_wrap(
        width = 1/4,
        class = "mb-4",
        saas_kpi_card(
          title = "Total Ride Requests",
          value = format_count(kpis$total_requests),
          subtitle = sprintf("%s completed rides", format_count(kpis$completed_trips)),
          icon_name = "route",
          accent_color = "#06b6d4",
          badge_text = "50k Cohort",
          badge_type = "cyan"
        ),
        saas_kpi_card(
          title = "Completion Rate",
          value = sprintf("%.1f%%", 100 - kpis$cancellation_rate_pct),
          subtitle = sprintf("%.1f%% cancellation (%s trips)", kpis$cancellation_rate_pct, format_count(kpis$cancelled_trips)),
          icon_name = "circle-check",
          accent_color = "#10b981",
          badge_text = "Operational",
          badge_type = "success"
        ),
        saas_kpi_card(
          title = "Bike Taxi Demand",
          value = sprintf("%.1f%%", kpis$bike_share_pct),
          subtitle = sprintf("%s bike requests", format_count(kpis$bike_requests)),
          icon_name = "motorcycle",
          accent_color = "#f59e0b",
          badge_text = "Dominant Mode",
          badge_type = "warning"
        ),
        saas_kpi_card(
          title = "Gross Completed Volume",
          value = format_inr(kpis$total_revenue_inr),
          subtitle = sprintf("₹%.1f average completed fare", kpis$avg_fare_inr),
          icon_name = "money-bill-wave",
          accent_color = "#6366f1",
          badge_text = "₹547/ride",
          badge_type = "cyan"
        )
      )
    })
    
    # Service Mix Plot
    output$service_mix_plot <- renderPlotly({
      df <- filtered_df()
      req(nrow(df) > 0)
      svc_agg <- compute_service_breakdown(df)
      
      # Friendly labels
      svc_agg$label <- paste0(
        toupper(substring(svc_agg$services, 1, 1)),
        substring(svc_agg$services, 2)
      )
      
      p <- plot_ly(
        svc_agg,
        x = ~reorder(label, requests),
        y = ~requests,
        type = "bar",
        text = ~paste0(format(requests, big.mark = ","), " (", share_pct, "%)"),
        textposition = "outside",
        textfont = list(color = "#f8fafc", size = 11, family = "Inter, sans-serif"),
        marker = list(
          color = c("#06b6d4", "#38bdf8", "#10b981", "#f59e0b", "#a855f7"),
          line = list(color = "rgba(255,255,255,0.1)", width = 1)
        )
      ) %>%
        layout(
          xaxis = list(title = "", tickfont = list(color = "#cbd5e1", size = 12)),
          yaxis = list(title = "Total Booking Requests", gridcolor = "rgba(255,255,255,0.06)")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
    # Daily Trend Plot
    output$daily_trend_plot <- renderPlotly({
      df <- filtered_df()
      req(nrow(df) > 0)
      daily_agg <- compute_daily_timeline(df)
      
      p <- plot_ly(daily_agg, x = ~ride_date) %>%
        add_bars(
          y = ~total_requests,
          name = "Daily Requests",
          marker = list(
            color = "rgba(6, 182, 212, 0.4)",
            line = list(color = "#06b6d4", width = 1)
          )
        ) %>%
        add_lines(
          y = ~rolling_7d_requests,
          name = "7-Day Rolling Trend",
          line = list(color = "#38bdf8", width = 3, shape = "spline")
        ) %>%
        layout(
          xaxis = list(title = "", gridcolor = "rgba(255,255,255,0.06)"),
          yaxis = list(title = "Requests / Day", gridcolor = "rgba(255,255,255,0.06)"),
          hovermode = "x unified"
        )
      
      style_plotly(p)
    })
    
    # Top Zones Quick Plot
    output$top_zones_quick_plot <- renderPlotly({
      df <- filtered_df()
      req(nrow(df) > 0)
      top_zones <- df %>%
        count(pickup_zone, sort = TRUE) %>%
        slice_head(n = 8)
      
      p <- plot_ly(
        top_zones,
        x = ~n,
        y = ~reorder(pickup_zone, n),
        type = "bar",
        orientation = "h",
        text = ~format(n, big.mark = ","),
        textposition = "outside",
        textfont = list(color = "#f8fafc", size = 11),
        marker = list(
          color = "rgba(99, 102, 241, 0.8)",
          line = list(color = "#6366f1", width = 1)
        )
      ) %>%
        layout(
          xaxis = list(title = "Requests", gridcolor = "rgba(255,255,255,0.06)"),
          yaxis = list(title = "", tickfont = list(color = "#cbd5e1", size = 11)),
          margin = list(l = 120)
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
  })
}
