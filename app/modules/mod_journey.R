# modules/mod_journey.R
# Tab 4: Over Time
# Small multiples line chart — individual trajectories + average overlay
# Faceted by BPN domain (3 panels)

# ── UI ────────────────────────────────────────────────────────────────────────
journeyUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    div(
      class = "ns-section-header",
      h2(class = "ns-section-title", "Support remains steady — but trajectories vary."),
      p(class  = "ns-section-sub",
        "Individual scores across sessions — ",
        "27 participants with 3 or more sessions")
    ),
    
    # Chart container
    div(
      class = "ns-chart-container",
      ggiraph::girafeOutput(ns("trajectory_chart"), height = "480px")
    ),
    
    # Insight box
    div(
      class = "ns-insight-box",
      div(
        class = "ns-insight-inner",
        p(
          class = "ns-insight-text",
          uiOutput(ns("trajectory_insight"), inline = TRUE)
        )
      )
    ),
    
    # Context note
    div(
      class = "ns-context-note",
      icon("info circle"),
      " Faint lines show individual participant trajectories. ",
      "Bold line shows the group average (sessions 1\u20139, N \u2265 10). ",
      "Sample thins beyond session 9 \u2014 later averages are indicative only."
    )
    
  )
}

# ── Server ────────────────────────────────────────────────────────────────────
journeyServer <- function(id, sessions_clean, participants) {
  moduleServer(id, function(input, output, session) {
    
    # ── Data prep ─────────────────────────────────────────────────────────────
    
    # Individual trajectories: participants with 3+ sessions only
    individual_traj <- sessions_clean |>
      dplyr::group_by(uin) |>
      dplyr::filter(dplyr::n() >= 3) |>
      dplyr::ungroup() |>
      dplyr::select(uin, session_number, competence, autonomy, relatedness) |>
      tidyr::pivot_longer(
        cols      = c(competence, autonomy, relatedness),
        names_to  = "domain",
        values_to = "score"
      ) |>
      dplyr::mutate(
        domain = dplyr::case_when(
          domain == "competence"  ~ "Competence",
          domain == "autonomy"    ~ "Autonomy",
          domain == "relatedness" ~ "Relatedness"
        ),
        domain = factor(domain, levels = c("Competence", "Autonomy", "Relatedness"))
      )
    
    # Average trajectory: sessions 1–9 only (N >= 10 throughout)
    avg_traj <- sessions_clean |>
      dplyr::filter(session_number <= 9) |>
      dplyr::group_by(session_number) |>
      dplyr::summarise(
        competence  = mean(competence,  na.rm = TRUE),
        autonomy    = mean(autonomy,    na.rm = TRUE),
        relatedness = mean(relatedness, na.rm = TRUE),
        .groups = "drop"
      ) |>
      tidyr::pivot_longer(
        cols      = c(competence, autonomy, relatedness),
        names_to  = "domain",
        values_to = "score"
      ) |>
      dplyr::mutate(
        domain = dplyr::case_when(
          domain == "competence"  ~ "Competence",
          domain == "autonomy"    ~ "Autonomy",
          domain == "relatedness" ~ "Relatedness"
        ),
        domain = factor(domain, levels = c("Competence", "Autonomy", "Relatedness"))
      )
    
    # Pre-compute tooltip and data_id — avoids discouraged $ notation inside aes()
    individual_traj <- individual_traj |>
      dplyr::mutate(
        tooltip_text = paste0("Session ", session_number, "\nScore: ", round(score, 1)),
        data_id_val  = paste0(uin, "_", domain)
      )
    
    # Domain color lookup — same as bpn_colors in global.R
    domain_colors <- c(
      "Competence"  = "#BEFF00",
      "Autonomy"    = "#8755FF",
      "Relatedness" = "#6B44CC"
    )
    
    # ── Chart ─────────────────────────────────────────────────────────────────
    output$trajectory_chart <- ggiraph::renderGirafe({
      
      # Individual lines — muted, thin
      p <- ggplot2::ggplot() +
        
        # Midpoint reference line (earns its place — scale context)
        ggplot2::geom_hline(
          yintercept = 5,
          color      = "#21262D",
          linewidth  = 0.6,
          linetype   = "solid"
        ) +
        
        # Individual participant lines — faint, non-interactive
        ggplot2::geom_line(
          data = individual_traj,
          ggplot2::aes(
            x     = session_number,
            y     = score,
            group = uin,
            color = domain
          ),
          alpha     = 0.11,
          linewidth = 0.4
        ) +
        
        # Invisible interactive points for accurate tooltips
        ggiraph::geom_point_interactive(
          data = individual_traj,
          ggplot2::aes(
            x       = session_number,
            y       = score,
            group   = uin,
            color   = domain,
            tooltip = tooltip_text,
            data_id = data_id_val
          ),
          alpha = 0,
          size  = 3
        ) +
        
        # Average line — bold, on top
        ggplot2::geom_line(
          data      = avg_traj,
          ggplot2::aes(x = session_number, y = score, color = domain),
          linewidth = 1.8,
          alpha     = 0.95
        ) +
        
        # Average line endpoint dot
        ggplot2::geom_point(
          data = avg_traj |> dplyr::filter(session_number == 9),
          ggplot2::aes(x = session_number, y = score, color = domain),
          size = 2.5
        ) +
        
        # Facet by domain
        ggplot2::facet_wrap(
          ~domain,
          ncol   = 3,
          scales = "fixed"
        ) +
        
        # Scale
        ggplot2::scale_y_continuous(
          limits = c(0, 9),
          breaks = c(0, 3, 5, 7, 9),
          labels = c("0", "3", "5\n(mid)", "7", "9")
        ) +
        ggplot2::scale_x_continuous(
          breaks = c(1, 3, 5, 7, 9),
          labels = c("1", "3", "5", "7", "9")
        ) +
        ggplot2::scale_color_manual(values = domain_colors) +
        
        # Labels
        ggplot2::labs(
          x = NULL,
          y = "Score (1–9)"
        ) +
        
        # Theme — inherits theme_ns from global.R, override specifics
        theme_ns() +
        ggplot2::theme(
          legend.position  = "none",
          panel.grid.major.x = ggplot2::element_blank(),
          strip.text       = ggplot2::element_text(
            color  = "#FFFFFF",
            face   = "bold",
            size   = 11
          ),
          axis.text.x      = ggplot2::element_text(size = 9),
          axis.text.y      = ggplot2::element_text(size = 9)
        )
      
      ggiraph::girafe(
        ggobj  = p,
        width_svg  = 10,
        height_svg = 4.5,
        options = list(
          ggiraph::opts_hover(css = "stroke-width:1.5; opacity:0.8;"),
          ggiraph::opts_tooltip(
            css       = paste0(
              "background:", "#0D1117", ";",
              "color:", "#FFFFFF", ";",
              "border:1px solid ", "#21262D", ";",
              "border-radius:6px;",
              "padding:8px 12px;",
              "font-family:Barlow,sans-serif;",
              "font-size:13px;"
            ),
            use_fill  = FALSE
          ),
          ggiraph::opts_sizing(rescale = TRUE)
        )
      )
    })
    
    # ── Insight text ──────────────────────────────────────────────────────────
    output$trajectory_insight <- renderUI({
      tagList(
        "Across participants with multiple sessions, scores remain broadly stable ",
        "rather than showing a consistent upward trend. ",
        "Individual trajectories vary considerably — some participants show ",
        "meaningful gains over time, while others fluctuate. ",
        "Relatedness is the most variable domain, suggesting connection may be ",
        "more sensitive to session-by-session experience. ",
        "These patterns are illustrative rather than conclusive, ",
        "given the sample size and the thinning of participants in later sessions."
      )
    })
    
    # ── Critical: prevent lazy evaluation with CSS tabs ───────────────────────
    outputOptions(output, "trajectory_chart",  suspendWhenHidden = FALSE)
    outputOptions(output, "trajectory_insight", suspendWhenHidden = FALSE)
    
  })
}