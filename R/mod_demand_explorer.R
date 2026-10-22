# R/mod_demand_explorer.R
# Demand Explorer Module: Granular Temporal Patterns, Economics, and Route Analytics

demand_explorer_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Filter Controls
    card(
      class = "mb-3 border-0 shadow-sm",
      card_body(
        layout_column_wrap(
          width = 1/4,
          selectInput(
            ns("service_filter"),
            "Service Filter:",
            choices = c("All Services", "Bike Taxi Only", "Auto", "Cab Economy", "Parcel"),
            selected = "All Services"
          ),
          selectInput(
            ns("status_filter"),
            "Ride Status:",
            choices = c("All Records (Requests)", "Completed Only", "Cancelled Only"),
            selected = "All Records (Requests)"
          ),
          selectInput(
            ns("day_type_filter"),
            "Day Category:",
            choices = c("All Days", "Weekday Only", "Weekend Only"),
            selected = "All Days"
          ),
          sliderInput(
            ns("hour_range"),
            "Hour Range:",
            min = 0, max = 23, value = c(0, 23), step = 1
          )
        )
      )
    ),
    
    # Temporal Profiles Row
    layout_column_wrap(
      width = 1/2,
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Diurnal Demand Curve: Weekday vs Weekend", class = "fw-bold"),
          span(class = "badge bg-primary", "Hourly Profile")
        ),
        card_body(
          plotlyOutput(ns("hourly_curve_plot"), height = "320px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Demand Heatmap: Day of Week × Hour of Day", class = "fw-bold"),
          span(class = "badge bg-info", "Peak Windows")
        ),
        card_body(
          plotlyOutput(ns("weekday_hour_heatmap"), height = "320px")
        )
      )
    ),
    
    # Physics & Economics Row
    layout_column_wrap(
      width = 1/2,
      class = "mt-3",
      card(
        class = "shadow-sm border-0",
        card_header("Trip Distance & Duration Distributions", class = "fw-bold"),
        card_body(
          plotlyOutput(ns("distance_duration_plot"), height = "300px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header("Unit Economics: Fare per Kilometer by Service", class = "fw-bold"),
        card_body(
          plotlyOutput(ns("fare_per_km_plot"), height = "300px")
        )
      )
    ),
    
    # Route Performance Data Table
    card(
      class = "shadow-sm border-0 mt-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Most Frequent Zone-to-Zone Routes & Service Quality", class = "fw-bold"),
        span(class = "badge bg-secondary", "Inter-Zone Mobility")
      ),
      card_body(
        DTOutput(ns("routes_table"))
      )
    )
  )
}

demand_explorer_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    # Filtered Dataset Reactive
    filtered_df <- reactive({
      req(shared_data$rides_df)
      df <- shared_data$rides_df
      
      # Service filter
      if (input$service_filter == "Bike Taxi Only") {
        df <- df %>% filter(is_bike_service)
      } else if (input$service_filter != "All Services") {
        svc_map <- c("Auto" = "auto", "Cab Economy" = "cab economy", "Parcel" = "parcel")
        df <- df %>% filter(services == svc_map[input$service_filter])
      }
      
      # Status filter
      if (input$status_filter == "Completed Only") {
        df <- df %>% filter(is_completed)
      } else if (input$status_filter == "Cancelled Only") {
        df <- df %>% filter(is_cancelled)
      }
      
      # Day category
      if (input$day_type_filter == "Weekday Only") {
        df <- df %>% filter(!is_weekend)
      } else if (input$day_type_filter == "Weekend Only") {
        df <- df %>% filter(is_weekend)
      }
      
      # Hour range
      df <- df %>% filter(ride_hour >= input$hour_range[1] & ride_hour <= input$hour_range[2])
      
      df
    })
    
    # 1. Hourly Curve Plot
    output$hourly_curve_plot <- renderPlotly({
      df <- filtered_df()
      hourly_agg <- df %>%
        group_by(ride_hour, day_type) %>%
        summarise(
          requests = n(),
          completed = sum(is_completed),
          cancellations = sum(is_cancelled),
          .groups = "drop"
        )
      
      p <- plot_ly(hourly_agg, x = ~ride_hour) %>%
        add_lines(
          data = filter(hourly_agg, day_type == "Weekday"),
          y = ~requests,
          name = "Weekday Requests",
          line = list(color = "#0284c7", width = 3)
        ) %>%
        add_lines(
          data = filter(hourly_agg, day_type == "Weekend"),
          y = ~requests,
          name = "Weekend Requests",
          line = list(color = "#f59e0b", width = 3, dash = "dash")
        ) %>%
        layout(
          xaxis = list(title = "Hour of Day (0 - 23)", dtick = 2),
          yaxis = list(title = "Ride Requests"),
          hovermode = "x unified"
        )
      
      style_plotly(p)
    })
    
    # 2. Weekday x Hour Heatmap
    output$weekday_hour_heatmap <- renderPlotly({
      df <- filtered_df()
      grid_data <- df %>%
        group_by(ride_weekday, ride_hour) %>%
        summarise(requests = n(), .groups = "drop")
      
      # Order weekdays appropriately
      days_order <- c("Sunday", "Saturday", "Friday", "Thursday", "Wednesday", "Tuesday", "Monday")
      
      matrix_df <- grid_data %>%
        tidyr::complete(ride_weekday = days_order, ride_hour = 0:23, fill = list(requests = 0)) %>%
        mutate(ride_weekday = factor(ride_weekday, levels = days_order)) %>%
        arrange(ride_weekday, ride_hour)
      
      p <- plot_ly(
        matrix_df,
        x = ~ride_hour,
        y = ~ride_weekday,
        z = ~requests,
        type = "heatmap",
        colorscale = list(c(0, "#0f172a"), c(0.5, "#0284c7"), c(1, "#38bdf8")),
        hoverinfo = "text",
        text = ~sprintf("Day: %s<br>Hour: %02d:00<br>Requests: %d", ride_weekday, ride_hour, requests)
      ) %>%
        layout(
          xaxis = list(title = "Hour of Day", dtick = 2),
          yaxis = list(title = "")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
    # 3. Distance & Duration Plot
    output$distance_duration_plot <- renderPlotly({
      df <- filtered_df() %>% filter(is_completed)
      
      p <- plot_ly(alpha = 0.6) %>%
        add_histogram(
          x = ~df$distance,
          name = "Distance (km)",
          marker = list(color = "#0284c7")
        ) %>%
        layout(
          barmode = "overlay",
          xaxis = list(title = "Trip Distance (km)"),
          yaxis = list(title = "Trip Count")
        )
      
      style_plotly(p)
    })
    
    # 4. Fare per Km Plot
    output$fare_per_km_plot <- renderPlotly({
      df <- filtered_df() %>% filter(is_completed, !is.na(fare_per_km), fare_per_km < 100)
      
      p <- plot_ly(
        df,
        x = ~services,
        y = ~fare_per_km,
        type = "box",
        color = ~services,
        colors = c("#0284c7", "#38bdf8", "#10b981", "#f59e0b", "#a855f7")
      ) %>%
        layout(
          xaxis = list(title = "Service Category"),
          yaxis = list(title = "Fare per Km (₹/km)")
        )
      
      style_plotly(p, show_legend = FALSE)
    })
    
    # 5. Top Routes DataTable
    output$routes_table <- renderDT({
      df <- filtered_df()
      routes <- compute_top_routes(df, top_n = 50)
      
      datatable(
        routes %>% select(
          `Pickup Zone` = pickup_zone,
          `Drop-off Zone` = dropoff_zone,
          `Total Requests` = total_requests,
          `Completed Trips` = completed_trips,
          `Cancellation Rate` = cancellation_rate,
          `Avg Distance (km)` = avg_distance_km,
          `Avg Duration (min)` = avg_duration_min,
          `Avg Fare (₹)` = avg_fare
        ),
        options = list(
          pageLength = 8,
          scrollX = TRUE,
          dom = "frtip",
          order = list(list(2, "desc"))
        ),
        rownames = FALSE,
        class = "table-hover compact stripe"
      ) %>%
        formatCurrency("Avg Fare (₹)", currency = "₹ ", digits = 1) %>%
        formatString("Cancellation Rate", suffix = "%")
    })
    
  })
}
