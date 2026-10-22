# R/mod_simulator.R
# What-If Driver Allocation Simulator Module: Interactive Policy Playground

simulator_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Control Panel Card
    card(
      class = "mb-4 border-0 shadow-sm",
      card_header(
        class = "d-flex justify-content-between align-items-center flex-wrap gap-2",
        div(
          span("What-If Fleet Allocation Policy Cockpit", class = "fw-bold fs-5"),
          span(" | Rebalance Driver Supply Across Bangalore Hubs", class = "text-muted small")
        ),
        span(class = "badge bg-primary px-3 py-2", "Supply Conservation Invariant Active")
      ),
      card_body(
        # Explanation Callout
        callout_card(
          title = "How the What-If Simulation Works & Why Capacity Matters",
          message = "This simulator models the operational impact of rebalancing virtual driver supply from a low-strain 'Donor' zone to a high-demand 'Recipient' zone. A zone only experiences a Risk Score reduction when its initial driver capacity is below its demand (unmet shortage). If driver capacity already exceeds demand, shortage is 0, so adding more drivers produces 0 delta. Use the Preset Scenarios below or set Recipient drivers to a realistic operational deficit (e.g., 1–3 drivers) to see immediate risk mitigation!",
          type = "info"
        ),
        
        # One-Click Scenario Presets
        div(
          class = "p-3 rounded mb-4",
          style = "background: rgba(15, 23, 42, 0.6); border: 1px solid var(--border-subtle);",
          div(class = "text-muted small text-uppercase fw-bold mb-2", icon("wand-magic-sparkles", class = "me-1 text-info"), "Instant Simulation Presets:"),
          div(
            class = "d-flex gap-2 flex-wrap",
            actionButton(ns("preset_acute"), "Acute Peak Deficit (High Impact)", icon = icon("fire", class = "text-danger"), class = "btn-outline-danger btn-sm"),
            actionButton(ns("preset_moderate"), "Moderate Commute Strain", icon = icon("triangle-exclamation", class = "text-warning"), class = "btn-outline-warning btn-sm"),
            actionButton(ns("preset_balanced"), "Balanced Fleet Redistribution", icon = icon("scale-balanced", class = "text-success"), class = "btn-outline-success btn-sm"),
            actionButton(ns("reset_defaults"), "Reset to Defaults", icon = icon("rotate-left"), class = "btn-outline-secondary btn-sm")
          )
        ),
        
        # Zone Configuration Columns
        layout_column_wrap(
          width = 1/2,
          # Donor column
          div(
            class = "p-3 rounded border mb-3",
            style = "background: rgba(15, 23, 42, 0.45); border-color: rgba(245, 158, 11, 0.3) !important;",
            div(
              class = "d-flex justify-content-between align-items-center mb-2",
              h6(icon("arrow-up-right-from-square", class = "me-2 text-warning"), "Donor Zone (Supply Source)", class = "fw-bold text-warning mb-0"),
              span(class = "badge bg-warning text-dark", "Surplus Fleet")
            ),
            selectInput(ns("donor_zone"), "Select Donor Zone:", choices = NULL),
            uiOutput(ns("donor_live_hud")),
            sliderInput(ns("donor_drivers"), "Initial Virtual Drivers (Donor):", min = 1, max = 30, value = 5, step = 1)
          ),
          # Recipient column
          div(
            class = "p-3 rounded border mb-3",
            style = "background: rgba(15, 23, 42, 0.45); border-color: rgba(6, 182, 212, 0.3) !important;",
            div(
              class = "d-flex justify-content-between align-items-center mb-2",
              h6(icon("arrow-down", class = "me-2 text-info"), "Recipient Zone (High-Demand Target)", class = "fw-bold text-info mb-0"),
              span(class = "badge bg-info text-dark", "Target Zone")
            ),
            selectInput(ns("recipient_zone"), "Select Recipient Zone:", choices = NULL),
            uiOutput(ns("recipient_live_hud")),
            sliderInput(ns("recipient_drivers"), "Initial Virtual Drivers (Recipient):", min = 1, max = 30, value = 1, step = 1)
          )
        ),
        
        # Reallocation & Run Row
        layout_column_wrap(
          width = 1/3,
          sliderInput(ns("transfer_amount"), "Drivers to Reallocate (Donor -> Recipient):", min = 0, max = 15, value = 2, step = 1),
          sliderInput(ns("rides_per_driver"), "Rides Served per Driver / Day:", min = 2, max = 15, value = 6, step = 1),
          div(
            style = "display: flex; align-items: flex-end; height: 100%;",
            actionButton(ns("run_sim_btn"), "Run What-If Simulation", icon = icon("bolt"), class = "btn-success w-100 py-2 fs-6 fw-bold")
          )
        )
      )
    ),
    
    # Error / Validation Display
    uiOutput(ns("validation_alert")),
    
    # Conservation & Delta KPI Cards
    uiOutput(ns("sim_kpi_cards")),
    
    # Visual Comparison Row
    layout_column_wrap(
      width = 1/2,
      class = "mb-4",
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Demand vs. Service Capacity (Before vs. After)", class = "fw-bold"),
          span(class = "badge bg-primary", "Capacity Balance")
        ),
        card_body(
          plotlyOutput(ns("capacity_comparison_plot"), height = "340px")
        )
      ),
      card(
        class = "shadow-sm border-0",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Risk Score Trajectory (Before vs. After)", class = "fw-bold"),
          span(class = "badge bg-info", "Risk Shift")
        ),
        card_body(
          plotlyOutput(ns("risk_comparison_plot"), height = "340px")
        )
      )
    ),
    
    # Detailed Before/After Comparative Matrix
    card(
      class = "shadow-sm border-0 mb-3",
      card_header(
        class = "d-flex justify-content-between align-items-center",
        span("Scenario Audit: Full Before vs. After Metric Comparison", class = "fw-bold"),
        span(class = "badge bg-secondary", "Detailed Evaluation")
      ),
      card_body(
        tableOutput(ns("scenario_comparison_table")),
        p(class = "small text-muted mt-2",
          "Note: Simulated driver counts and capacity metrics are scenario parameters, not empirical observations. Assumes 100% reallocation compliance and zero inter-zone deadheading attrition.")
      )
    )
  )
}

simulator_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {
    
    # Initialize Zone Dropdowns
    observe({
      req(shared_data$daily_panel)
      top_zones <- shared_data$daily_panel %>%
        group_by(pickup_zone) %>%
        summarise(total = sum(demand_requests), .groups = "drop") %>%
        arrange(desc(total)) %>%
        pull(pickup_zone)
      
      updateSelectInput(session, "recipient_zone", choices = top_zones, selected = "Koramangala")
      updateSelectInput(session, "donor_zone", choices = top_zones, selected = "Gottigere")
    })
    
    # Preset 1: Acute Peak Deficit (Recipient starved of drivers)
    observeEvent(input$preset_acute, {
      updateSelectInput(session, "recipient_zone", selected = "Koramangala")
      updateSelectInput(session, "donor_zone", selected = "Gottigere")
      updateSliderInput(session, "recipient_drivers", value = 1)
      updateSliderInput(session, "donor_drivers", value = 5)
      updateSliderInput(session, "rides_per_driver", value = 6)
      updateSliderInput(session, "transfer_amount", value = 2)
    })
    
    # Preset 2: Moderate Commute Strain
    observeEvent(input$preset_moderate, {
      updateSelectInput(session, "recipient_zone", selected = "Koramangala")
      updateSelectInput(session, "donor_zone", selected = "Banaswadi")
      updateSliderInput(session, "recipient_drivers", value = 2)
      updateSliderInput(session, "donor_drivers", value = 4)
      updateSliderInput(session, "rides_per_driver", value = 6)
      updateSliderInput(session, "transfer_amount", value = 1)
    })
    
    # Preset 3: Balanced Fleet Redistribution
    observeEvent(input$preset_balanced, {
      updateSelectInput(session, "recipient_zone", selected = "Koramangala")
      updateSelectInput(session, "donor_zone", selected = "HSR Layout")
      updateSliderInput(session, "recipient_drivers", value = 2)
      updateSliderInput(session, "donor_drivers", value = 3)
      updateSliderInput(session, "rides_per_driver", value = 5)
      updateSliderInput(session, "transfer_amount", value = 1)
    })
    
    # Reset Defaults
    observeEvent(input$reset_defaults, {
      updateSliderInput(session, "recipient_drivers", value = 1)
      updateSliderInput(session, "donor_drivers", value = 5)
      updateSliderInput(session, "rides_per_driver", value = 6)
      updateSliderInput(session, "transfer_amount", value = 2)
    })
    
    # Dynamically cap transfer slider by donor drivers available
    observe({
      donor_d <- input$donor_drivers
      if (!is.null(donor_d) && donor_d > 0) {
        updateSliderInput(session, "transfer_amount", max = donor_d, value = min(input$transfer_amount, donor_d))
      }
    })
    
    # Donor Live Heads-Up Display
    output$donor_live_hud <- renderUI({
      req(input$donor_zone, shared_data$daily_panel)
      d_hist <- shared_data$daily_panel %>% filter(pickup_zone == input$donor_zone) %>% pull(demand_requests)
      d_demand <- max(1, round(mean(tail(d_hist, 7)), 1))
      d_cap <- (input$donor_drivers %||% 5) * (input$rides_per_driver %||% 6)
      d_bal <- d_cap - d_demand
      
      status_badge <- if (d_bal >= 0) {
        span(class = "badge bg-success-subtle text-success", sprintf("+%.0f surplus rides/day", d_bal))
      } else {
        span(class = "badge bg-danger-subtle text-danger", sprintf("%.0f deficit rides/day", abs(d_bal)))
      }
      
      div(
        class = "small text-muted mb-2 d-flex justify-content-between align-items-center flex-wrap gap-1",
        span(sprintf("Demand: ~%.1f rides/day | Capacity: %d rides", d_demand, d_cap)),
        status_badge
      )
    })
    
    # Recipient Live Heads-Up Display
    output$recipient_live_hud <- renderUI({
      req(input$recipient_zone, shared_data$daily_panel)
      r_hist <- shared_data$daily_panel %>% filter(pickup_zone == input$recipient_zone) %>% pull(demand_requests)
      r_demand <- max(1, round(mean(tail(r_hist, 7)), 1))
      r_cap <- (input$recipient_drivers %||% 1) * (input$rides_per_driver %||% 6)
      r_bal <- r_cap - r_demand
      
      status_badge <- if (r_bal < 0) {
        span(class = "badge bg-danger-subtle text-danger", sprintf("%.0f deficit rides/day", abs(r_bal)))
      } else {
        span(class = "badge bg-success-subtle text-success", sprintf("+%.0f surplus rides/day", r_bal))
      }
      
      div(
        class = "small text-muted mb-2 d-flex justify-content-between align-items-center flex-wrap gap-1",
        span(sprintf("Demand: ~%.1f rides/day | Capacity: %d rides", r_demand, r_cap)),
        status_badge
      )
    })
    
    # Reactive Simulation Results
    sim_results <- reactive({
      # Depend on action button or inputs
      input$run_sim_btn
      
      req(input$donor_zone, input$recipient_zone, shared_data$daily_panel)
      
      panel <- shared_data$daily_panel
      
      # Historical daily averages for forecasts
      d_hist <- panel %>% filter(pickup_zone == input$donor_zone) %>% pull(demand_requests)
      r_hist <- panel %>% filter(pickup_zone == input$recipient_zone) %>% pull(demand_requests)
      
      donor_fc <- max(1, round(mean(tail(d_hist, 7)), 1))
      recip_fc <- max(1, round(mean(tail(r_hist, 7)), 1))
      
      donor_cv <- if (length(d_hist) > 1 && mean(d_hist) > 0) sd(d_hist) / mean(d_hist) else 0.25
      recip_cv <- if (length(r_hist) > 1 && mean(r_hist) > 0) sd(r_hist) / mean(r_hist) else 0.25
      
      run_what_if_simulation(
        donor_zone = input$donor_zone,
        recipient_zone = input$recipient_zone,
        donor_forecast = donor_fc,
        recipient_forecast = recip_fc,
        donor_drivers = input$donor_drivers,
        recipient_drivers = input$recipient_drivers,
        transfer = input$transfer_amount,
        rides_per_driver = input$rides_per_driver,
        donor_cv = donor_cv,
        recipient_cv = recip_cv
      )
    })
    
    # Validation alert output
    output$validation_alert <- renderUI({
      sim <- sim_results()
      if (!sim$is_valid) {
        callout_card(
          title = "Configuration Error",
          message = sim$error_message,
          type = "danger"
        )
      } else {
        NULL
      }
    })
    
    # KPI Cards Output
    output$sim_kpi_cards <- renderUI({
      sim <- sim_results()
      req(sim$is_valid)
      
      recip_change_str <- sprintf("%.1f -> %.1f (Δ -%.1f pts)", sim$recipient$before$risk_score, sim$recipient$after$risk_score, sim$recip_risk_reduction)
      donor_change_str <- sprintf("%.1f -> %.1f (Δ +%.1f pts)", sim$donor$before$risk_score, sim$donor$after$risk_score, sim$donor_risk_increase)
      shortage_str <- sprintf("%s unserved rides eliminated", format_count(sim$net_shortage_reduction))
      
      recip_badge_type <- if (sim$recip_risk_reduction > 0) "success" else "warning"
      recip_badge_text <- if (sim$recip_risk_reduction > 0) "Eased Strain" else "No Change"
      
      layout_column_wrap(
        width = 1/4,
        class = "mb-4",
        saas_kpi_card(
          title = "Recipient Risk Reduction",
          value = sprintf("-%.1f pts", sim$recip_risk_reduction),
          subtitle = recip_change_str,
          icon_name = "arrow-down",
          accent_color = "#10b981",
          badge_text = recip_badge_text,
          badge_type = recip_badge_type
        ),
        saas_kpi_card(
          title = "Donor Risk Tradeoff",
          value = sprintf("+%.1f pts", sim$donor_risk_increase),
          subtitle = donor_change_str,
          icon_name = "arrow-up",
          accent_color = "#f59e0b",
          badge_text = "Absorbed",
          badge_type = "warning"
        ),
        saas_kpi_card(
          title = "System Shortage Cut",
          value = format_count(sim$net_shortage_reduction),
          subtitle = shortage_str,
          icon_name = "circle-check",
          accent_color = "#06b6d4",
          badge_text = "Fleet Lift",
          badge_type = "cyan"
        ),
        saas_kpi_card(
          title = "Conserved Drivers",
          value = format_count(sim$total_drivers_conserved),
          subtitle = sprintf("%d moved | 100%% Conserved", sim$transfer_amount),
          icon_name = "users",
          accent_color = "#6366f1",
          badge_text = "Conserved",
          badge_type = "cyan"
        )
      )
    })
    
    # Capacity Comparison Plot
    output$capacity_comparison_plot <- renderPlotly({
      sim <- sim_results()
      req(sim$is_valid)
      
      plot_df <- data.frame(
        Category = c(
          paste0(sim$donor_zone, "\n(Before)"),
          paste0(sim$donor_zone, "\n(After)"),
          paste0(sim$recipient_zone, "\n(Before)"),
          paste0(sim$recipient_zone, "\n(After)")
        ),
        Demand = c(
          sim$donor$before$forecast_demand,
          sim$donor$after$forecast_demand,
          sim$recipient$before$forecast_demand,
          sim$recipient$after$forecast_demand
        ),
        Capacity = c(
          sim$donor$before$estimated_capacity,
          sim$donor$after$estimated_capacity,
          sim$recipient$before$estimated_capacity,
          sim$recipient$after$estimated_capacity
        ),
        stringsAsFactors = FALSE
      )
      
      p <- plot_ly(plot_df, x = ~Category) %>%
        add_bars(
          y = ~Demand,
          name = "Forecast Demand (rides/day)",
          marker = list(color = "#94a3b8")
        ) %>%
        add_bars(
          y = ~Capacity,
          name = "Service Capacity (rides/day)",
          marker = list(color = "#06b6d4")
        ) %>%
        layout(
          barmode = "group",
          xaxis = list(title = "", tickfont = list(color = "#cbd5e1", size = 11)),
          yaxis = list(title = "Rides / Day", gridcolor = "rgba(255,255,255,0.06)")
        )
      
      style_plotly(p)
    })
    
    # Risk Trajectory Comparison Plot
    output$risk_comparison_plot <- renderPlotly({
      sim <- sim_results()
      req(sim$is_valid)
      
      risk_df <- data.frame(
        Zone = c(sim$donor_zone, sim$donor_zone, sim$recipient_zone, sim$recipient_zone),
        Stage = factor(c("Before", "After", "Before", "After"), levels = c("Before", "After")),
        Risk = c(
          sim$donor$before$risk_score,
          sim$donor$after$risk_score,
          sim$recipient$before$risk_score,
          sim$recipient$after$risk_score
        ),
        stringsAsFactors = FALSE
      )
      
      p <- plot_ly(
        risk_df,
        x = ~Stage,
        y = ~Risk,
        color = ~Zone,
        colors = c("#f59e0b", "#06b6d4"),
        type = "scatter",
        mode = "lines+markers",
        marker = list(size = 12, line = list(width = 2, color = "#0f172a")),
        line = list(width = 3)
      ) %>%
        layout(
          xaxis = list(title = "Policy Stage", tickfont = list(color = "#cbd5e1", size = 12)),
          yaxis = list(title = "Risk Score (0 - 100)", range = c(0, 100), gridcolor = "rgba(255,255,255,0.06)")
        )
      
      style_plotly(p)
    })
    
    # Comparison Table Output
    output$scenario_comparison_table <- renderTable({
      sim <- sim_results()
      req(sim$is_valid)
      
      sim$comparison_table
    }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")
    
  })
}
