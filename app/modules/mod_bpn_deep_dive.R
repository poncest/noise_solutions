# modules/mod_bpn_deep_dive.R
# Tab 2: How Support Varies
# Horizontal bar chart — locked per DESIGN_DECISIONS §6

# ── UI ────────────────────────────────────────────────────────────────────────
bpnDeepDiveUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    div(
      class = "ns-section-header",
      h2(class = "ns-section-title", "Competence leads. Connection lags behind."),
      p(class  = "ns-section-sub",
        "Average scores across ", app_info$n_sessions,
        " sessions (1 = not supported, 9 = fully supported)")
    ),
    
    # Distribution plot
    div(
      class = "ns-chart-container",
      style = "margin-bottom: 2em;",
      girafeOutput(ns("bpn_distribution"), height = "300px")
    ),
    
    # Insight callout
    div(
      class = "ns-insight-box",
      uiOutput(ns("distribution_insight"))
    ),
    
    # Table collapsed behind disclosure — chart is primary, table is secondary
    tags$details(
      style = "margin-top: 1.5em;",
      tags$summary(
        style = paste0(
          "color:#8B949E;",
          "font-size:0.85em;",
          "font-weight:600;",
          "cursor:pointer;",
          "padding:0.5em 0;",
          "list-style:none;"
        ),
        "View full summary statistics"
      ),
      div(
        class = "ns-table-container",
        style = "margin-top: 1em;",
        reactableOutput(ns("bpn_summary_table"))
      )
    ),
    
    # Context note
    div(
      class = "ns-context-note",
      icon("info circle"),
      " Scores are session-level averages of up to 5 AI analyses per session. ",
      "Negative sentence data for Relatedness is sparse (37/229 sessions) — ",
      "interpret that dimension's challenge quotes with caution."
    )
    
  )
}

# ── Server ────────────────────────────────────────────────────────────────────
bpnDeepDiveServer <- function(id, sessions_clean) {
  moduleServer(id, function(input, output, session) {
    
    # ── Summary averages — 1dp throughout for consistency ─────────────────────
    avgs <- data.frame(
      domain = factor(
        c("Competence", "Autonomy", "Relatedness"),
        levels = c("Relatedness", "Autonomy", "Competence")
      ),
      mean = c(
        round(mean(sessions_clean$competence,  na.rm = TRUE), 1),
        round(mean(sessions_clean$autonomy,    na.rm = TRUE), 1),
        round(mean(sessions_clean$relatedness, na.rm = TRUE), 1)
      )
    )
    
    # ── Horizontal bar chart ──────────────────────────────────────────────────
    output$bpn_distribution <- renderGirafe({
      
      p <- ggplot2::ggplot(avgs, ggplot2::aes(
        x       = domain,
        y       = mean,
        fill    = domain,
        tooltip = paste0(domain, ": ", mean, " / 9"),
        data_id = as.character(domain)
      )) +
        
        ggiraph::geom_col_interactive(
          width = 0.55,
          alpha = 0.9
        ) +
        
        # Score label right of bar — single location, no duplication
        ggplot2::geom_text(
          ggplot2::aes(label = mean, color = domain),
          hjust    = -0.3,
          size     = 5,
          fontface = "bold"
        ) +
        
        # Midpoint reference — higher contrast than before, labelled once
        ggplot2::annotate(
          "segment",
          x = 0.4, xend = 3.6,
          y = 5,   yend = 5,
          color     = "#555E68",
          linewidth = 0.9,
          linetype  = "dashed"
        ) +
        ggplot2::annotate(
          "text",
          x = 2.5, y = 5.15,
          label  = "5 \u2014 midpoint",
          color  = "#8B949E",
          size   = 2.8,
          hjust  = 0,
          vjust  = 0.5,
          family = "Barlow"
        ) +
        
        ggplot2::coord_flip() +
        
        ggplot2::scale_fill_manual(values  = bpn_colors) +
        ggplot2::scale_color_manual(values = bpn_colors) +
        ggplot2::scale_y_continuous(
          limits = c(0, 9.8),
          breaks = c(0, 3, 5, 7, 9),
          labels = c("0", "3", "5", "7", "9")
        ) +
        
        ggplot2::labs(x = NULL, y = "Average score (1–9)") +
        
        theme_ns() +
        ggplot2::theme(
          legend.position    = "none",
          panel.grid.major.y = ggplot2::element_blank(),
          panel.grid.major.x = ggplot2::element_line(
            color = "#21262D", linewidth = 0.3
          ),
          axis.text.y = ggplot2::element_text(
            size  = 13,
            face  = "bold",
            color = "#C9D1D9"
          )
        )
      
      ggiraph::girafe(
        ggobj      = p,
        width_svg  = 9,
        height_svg = 3,
        options    = list(
          ggiraph::opts_toolbar(saveaspng = FALSE),
          ggiraph::opts_hover(css = "opacity:0.75;"),
          ggiraph::opts_tooltip(
            css = paste0(
              "background:#0D1117;",
              "color:#FFFFFF;",
              "border:1px solid #21262D;",
              "border-radius:6px;",
              "padding:8px 12px;",
              "font-family:Barlow,sans-serif;",
              "font-size:13px;"
            ),
            use_fill = FALSE
          ),
          ggiraph::opts_sizing(rescale = TRUE)
        )
      )
    })
    
    # ── Insight callout ───────────────────────────────────────────────────────
    output$distribution_insight <- renderUI({
      
      comp <- round(mean(sessions_clean$competence,  na.rm = TRUE), 1)
      rel  <- round(mean(sessions_clean$relatedness, na.rm = TRUE), 1)
      gap  <- round(comp - rel, 1)
      
      div(
        class = "ns-insight-inner",
        p(
          class = "ns-insight-text",
          "Competence is most consistently supported (",
          tags$strong(paste0(comp, "/9")),
          "), while relatedness — the sense of connection — is lower (",
          tags$strong(paste0(rel, "/9")),
          "). The ",
          tags$strong(paste0(gap, "-point gap")),
          " is consistent across sessions and suggests an opportunity ",
          "to strengthen connection within sessions."
        )
      )
    })
    
    # ── Summary table ─────────────────────────────────────────────────────────
    output$bpn_summary_table <- renderReactable({
      
      summary_df <- tibble::tibble(
        Domain = c("Competence", "Autonomy", "Relatedness"),
        Mean   = round(c(
          mean(sessions_clean$competence,  na.rm = TRUE),
          mean(sessions_clean$autonomy,    na.rm = TRUE),
          mean(sessions_clean$relatedness, na.rm = TRUE)
        ), 1),
        Median = round(c(
          median(sessions_clean$competence,  na.rm = TRUE),
          median(sessions_clean$autonomy,    na.rm = TRUE),
          median(sessions_clean$relatedness, na.rm = TRUE)
        ), 1),
        SD = round(c(
          sd(sessions_clean$competence,  na.rm = TRUE),
          sd(sessions_clean$autonomy,    na.rm = TRUE),
          sd(sessions_clean$relatedness, na.rm = TRUE)
        ), 1),
        Min = c(
          min(sessions_clean$competence,  na.rm = TRUE),
          min(sessions_clean$autonomy,    na.rm = TRUE),
          min(sessions_clean$relatedness, na.rm = TRUE)
        ),
        Max = c(
          max(sessions_clean$competence,  na.rm = TRUE),
          max(sessions_clean$autonomy,    na.rm = TRUE),
          max(sessions_clean$relatedness, na.rm = TRUE)
        )
      )
      
      reactable::reactable(
        summary_df,
        theme = reactable::reactableTheme(
          backgroundColor = ns_colors$surface,
          color           = ns_colors$white,
          borderColor     = ns_colors$border,
          headerStyle     = list(
            color      = ns_colors$text_muted,
            fontWeight = "600"
          )
        ),
        columns = list(
          Domain = reactable::colDef(
            style = function(value) {
              list(color = bpn_colors[value], fontWeight = "700")
            }
          )
        ),
        highlight  = TRUE,
        borderless = TRUE,
        striped    = FALSE
      )
    })
    
    # ── outputOptions: prevent lazy eval with CSS tabs ────────────────────────
    outputOptions(output, "bpn_distribution",    suspendWhenHidden = FALSE)
    outputOptions(output, "distribution_insight", suspendWhenHidden = FALSE)
    outputOptions(output, "bpn_summary_table",   suspendWhenHidden = FALSE)
    
  })
}