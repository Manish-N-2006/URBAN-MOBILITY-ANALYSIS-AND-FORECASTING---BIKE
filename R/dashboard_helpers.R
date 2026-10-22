# R/dashboard_helpers.R
# Reusable UI Components, KPI Cards, and Formatting Helpers for Shiny & bslib

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(plotly)
  library(scales)
})

#' Format numeric values into clean Indian Rupee currency strings (fully vectorized)
format_inr <- function(x) {
  if (is.null(x)) return(character(0))
  ifelse(is.na(x), "₹0", paste0("₹", format(round(x), big.mark = ",")))
}

#' Format counts with thousands separator (fully vectorized)
format_count <- function(x) {
  if (is.null(x)) return(character(0))
  ifelse(is.na(x), "0", format(round(x), big.mark = ","))
}

#' Create Modern SaaS-Grade Executive KPI Card
saas_kpi_card <- function(
  title,
  value,
  subtitle = NULL,
  icon_name = "chart-line",
  accent_color = "#06b6d4",
  badge_text = NULL,
  badge_type = "cyan"
) {
  badge_class <- paste0("badge-", badge_type, "-subtle")
  
  # Map icon background and color
  icon_bg <- sprintf("rgba(%s, 0.15)", paste(col2rgb(accent_color), collapse = ", "))
  
  tags$div(
    class = "saas-kpi-card",
    style = paste0("--card-accent: ", accent_color, "; --icon-bg: ", icon_bg, "; --icon-color: ", accent_color, ";"),
    tags$div(
      class = "saas-kpi-header",
      tags$span(class = "saas-kpi-title", title),
      tags$div(
        class = "saas-kpi-icon-wrap",
        icon(icon_name)
      )
    ),
    tags$div(class = "saas-kpi-value", value),
    tags$div(
      class = "saas-kpi-footer",
      if (!is.null(badge_text)) tags$span(class = paste("saas-kpi-badge", badge_class), badge_text) else NULL,
      tags$span(subtitle)
    )
  )
}

# Compatibility alias for existing calls
kpi_card <- function(title, value, subtitle = NULL, icon_name = "chart-line", bg_color = "#1e293b", text_color = "#f8fafc", accent = "#06b6d4") {
  saas_kpi_card(
    title = title,
    value = value,
    subtitle = subtitle,
    icon_name = icon_name,
    accent_color = accent
  )
}

#' Create an informational alert / callout card
callout_card <- function(title, message, type = "info") {
  colors <- list(
    info = list(border = "#06b6d4", bg = "rgba(6, 182, 212, 0.08)", icon = "circle-info"),
    warning = list(border = "#f59e0b", bg = "rgba(245, 158, 11, 0.08)", icon = "triangle-exclamation"),
    success = list(border = "#10b981", bg = "rgba(16, 185, 129, 0.08)", icon = "circle-check"),
    danger = list(border = "#f43f5e", bg = "rgba(244, 63, 94, 0.08)", icon = "shield-halved")
  )
  c_info <- colors[[type]]
  
  div(
    style = paste0(
      "border-left: 4px solid ", c_info$border, "; ",
      "background-color: ", c_info$bg, "; ",
      "padding: 14px 18px; border-radius: 10px; margin-bottom: 16px; border: 1px solid rgba(255,255,255,0.05); border-left: 4px solid ", c_info$border, ";"
    ),
    h6(
      icon(c_info$icon, class = "me-2"),
      title,
      style = paste0("color: ", c_info$border, "; font-weight: 700; margin-bottom: 6px;")
    ),
    p(message, style = "margin: 0; font-size: 0.88rem; color: #cbd5e1; line-height: 1.55;")
  )
}

#' Standardize Plotly styling to match sleek bslib dark dashboard theme
style_plotly <- function(p, title = NULL, x_title = NULL, y_title = NULL, show_legend = TRUE) {
  p %>%
    layout(
      title = if (!is.null(title)) list(
        text = title,
        font = list(size = 14, color = "#f8fafc", family = "Outfit, sans-serif")
      ) else NULL,
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)",
      font = list(color = "#94a3b8", family = "Inter, sans-serif"),
      showlegend = show_legend,
      legend = list(
        orientation = "h",
        y = -0.22,
        x = 0.5,
        xanchor = "center",
        font = list(color = "#cbd5e1", size = 11),
        bgcolor = "rgba(15, 23, 42, 0.6)",
        bordercolor = "rgba(255, 255, 255, 0.08)",
        borderwidth = 1
      ),
      hoverlabel = list(
        bgcolor = "#0f172a",
        bordercolor = "#06b6d4",
        font = list(family = "Inter, sans-serif", color = "#ffffff", size = 12)
      ),
      xaxis = list(
        title = if (!is.null(x_title)) list(text = x_title, font = list(size = 12, color = "#94a3b8")) else NULL,
        color = "#94a3b8",
        gridcolor = "rgba(255, 255, 255, 0.05)",
        zerolinecolor = "rgba(255, 255, 255, 0.1)"
      ),
      yaxis = list(
        title = if (!is.null(y_title)) list(text = y_title, font = list(size = 12, color = "#94a3b8")) else NULL,
        color = "#94a3b8",
        gridcolor = "rgba(255, 255, 255, 0.05)",
        zerolinecolor = "rgba(255, 255, 255, 0.1)"
      ),
      margin = list(l = 55, r = 25, t = 40, b = 50)
    ) %>%
    config(displayModeBar = FALSE, responsive = TRUE)
}
