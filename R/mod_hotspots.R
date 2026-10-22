# R/mod_hotspots.R
# Hotspots and Spatial Analysis Module: Rankings, Concentration, and Leaflet Map

hotspots_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Spatial Concentration KPI Row
    uiOutput(ns("concentration_kpis")),
    
    # Geographic Map & Notice Card
    card(
      class = "shadow-sm border-0 mb-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Bangalore Urban Mobility Geographic Heatmap", class = "fw-bold"),
        span(class = "badge bg-primary", "OpenStreetMap Geocoded")
      ),
      card_body(
        callout_card(
          title = "Spatial Resolution & Geographic Data Notice",
          message = "In accordance with strict statistical integrity, coordinates are displayed solely for verified OpenStreetMap Nominatim centroids of Bangalore urban zones. Granular raw street point variations without verifiable coordinates are aggregated to their parent urban zone. No artificial GPS coordinates are ever generated or fabricated.",
          type = "info"
        ),
        leafletOutput(ns("spatial_map"), height = "460px")
      )
    ),
    
    # Zone Rankings Row
    layout_column_wrap(
      width = 1/2,
      card(
        class = "shadow-sm border-0",
        card_header("Top 15 Pickup Hotspot Zones", class = "fw-bold"),
        card_body(
          plotlyOutput(ns("top_pickup_plot"), height = "380px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header("Top 15 Destination Zones", class = "fw-bold"),
        card_body(
          plotlyOutput(ns("top_dropoff_plot"), height = "380px")
        )
      )
    ),
    
    # Origin-Destination Flow Heatmap
    card(
      class = "shadow-sm border-0 mt-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Origin-to-Destination (OD) Zone Interaction Heatmap", class = "fw-bold"),
        span(class = "badge bg-info", "Top 12 Hub Flow")
      ),
      card_body(
        plotlyOutput(ns("od_matrix_plot"), height = "420px")
      )
    )
  )
}

hotspots_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    # Concentration KPIs
    output$concentration_kpis <- renderUI({
      req(shared_data$rides_df)
      conc <- compute_demand_concentration(shared_data$rides_df)
      rankings <- compute_zone_rankings(shared_data$rides_df, top_n = 1)
      top_zone <- rankings$top_pickups$pickup_zone[1]
      top_zone_reqs <- rankings$top_pickups$demand_requests[1]
      
      layout_column_wrap(
        width = 1/4,
        saas_kpi_card(
          title = "Spatial Gini Index",
          value = sprintf("%.3f", conc$gini_coefficient),
          subtitle = conc$concentration_category,
          icon_name = "network-wired",
          accent_color = "#06b6d4",
          badge_text = "Concentration",
          badge_type = "cyan"
        ),
        saas_kpi_card(
          title = "Top 10% Zones Share",
          value = sprintf("%.1f%%", conc$top_10_pct_share),
          subtitle = sprintf("Top 20%% share: %.1f%% of volume", conc$top_20_pct_share),
          icon_name = "chart-pie",
          accent_color = "#10b981",
          badge_text = "Pareto Hubs",
          badge_type = "success"
        ),
        saas_kpi_card(
          title = "Peak Single Hotspot",
          value = top_zone,
          subtitle = sprintf("%s observed requests", format_count(top_zone_reqs)),
          icon_name = "location-dot",
          accent_color = "#f59e0b",
          badge_text = "Rank #1",
          badge_type = "warning"
        ),
        saas_kpi_card(
          title = "Urban Hubs Audited",
          value = format_count(conc$total_zones),
          subtitle = "Bangalore zones categorized",
          icon_name = "city",
          accent_color = "#6366f1",
          badge_text = "Active Cohort",
          badge_type = "cyan"
        )
      )
    })
    
    # Leaflet Interactive Map
    output$spatial_map <- renderLeaflet({
      req(shared_data$rides_df)
      geocoded_df <- get_geocoded_zone_demand(shared_data$rides_df)
      m <- render_hotspot_leaflet_map(geocoded_df)
      if (is.null(m)) {
        # Fallback empty map
        m <- leaflet() %>% addTiles() %>% setView(77.59, 12.97, zoom = 11)
      }
      m
    })
    
    # Top Pickups Plot
    output$top_pickup_plot <- renderPlotly({
      req(shared_data$rides_df)
      rankings <- compute_zone_rankings(shared_data$rides_df, top_n = 15)
      
      p <- plot_ly(
        rankings$top_pickups,
        x = ~demand_requests,
        y = ~reorder(pickup_zone, demand_requests),
        type = "bar",
        orientation = "h",
        text = ~sprintf("%s (Cancel: %.1f%%)", format_count(demand_requests), cancellation_rate_pct),
        textposition = "auto",
        marker = list(
          color = ~cancellation_rate_pct,
          colorscale = list(c(0, "#22c55e"), c(0.5, "#eab308"), c(1, "#ef4444")),
          showscale = FALSE
        )
      ) %>%
        layout(
          xaxis = list(title = "Total Pickup Requests"),
          yaxis = list(title = "")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
    # Top Dropoffs Plot
    output$top_dropoff_plot <- renderPlotly({
      req(shared_data$rides_df)
      rankings <- compute_zone_rankings(shared_data$rides_df, top_n = 15)
      
      p <- plot_ly(
        rankings$top_dropoffs,
        x = ~dropoffs,
        y = ~reorder(dropoff_zone, dropoffs),
        type = "bar",
        orientation = "h",
        text = ~format_count(dropoffs),
        textposition = "auto",
        marker = list(color = "#38bdf8")
      ) %>%
        layout(
          xaxis = list(title = "Total Drop-off Trips"),
          yaxis = list(title = "")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
    # OD Matrix Plot
    output$od_matrix_plot <- renderPlotly({
      req(shared_data$rides_df)
      od_df <- build_od_heatmap_data(shared_data$rides_df, top_n = 12)
      
      p <- plot_ly(
        od_df,
        x = ~dropoff_zone,
        y = ~pickup_zone,
        z = ~trips,
        type = "heatmap",
        colorscale = list(c(0, "#0f172a"), c(0.4, "#0284c7"), c(1, "#38bdf8")),
        hoverinfo = "text",
        text = ~sprintf("From: %s<br>To: %s<br>Trips: %d", pickup_zone, dropoff_zone, trips)
      ) %>%
        layout(
          xaxis = list(title = "Destination Zone", tickangle = -35),
          yaxis = list(title = "Origin Zone")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
  })
}
