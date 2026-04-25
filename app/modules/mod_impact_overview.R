# modules/mod_impact_overview.R
# Tab 1: Impact at a Glance
# 10-second view: 3 BPN KPI cards + session rating + hero quote + takeaway

# ── UI ────────────────────────────────────────────────────────────────────────
impactOverviewUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    # Section: headline
    div(
      class = "ns-section-header",
      h2(class = "ns-section-title", "Young people feel capable \u2014 but less connected."),
      p(class  = "ns-section-sub",
        "Analysis of ", app_info$n_sessions, " sessions with ",
        app_info$n_participants, " young people")
    ),
    
    # KPI cards row — 3 BPN scores + session rating
    div(
      class = "ui four column stackable grid ns-kpi-grid",
      
      div(class = "column", uiOutput(ns("kpi_competence"))),
      div(class = "column", uiOutput(ns("kpi_autonomy"))),
      div(class = "column", uiOutput(ns("kpi_relatedness"))),
      div(class = "column", uiOutput(ns("kpi_rating")))
    ),
    
    # Takeaway sentence
    div(
      class = "ns-takeaway",
      style = "padding-right: 1em;",
      uiOutput(ns("takeaway_text"))
    ),
    
    # Rating / BPN alignment chart — subordinate, below takeaway
    div(
      class = "ns-chart-container",
      style = "margin-top: 2em; margin-bottom: 0; max-width: 600px; margin-left: auto; margin-right: auto;",
      girafeOutput(ns("rating_bpn_chart"), height = "200px")
    ),
    
    # Chart caption
    div(
      class = "ns-context-note",
      style = "margin-bottom: 2em;",
      icon("info circle"),
      " Higher-rated sessions tend to show slightly higher BPN scores, ",
      "indicating partial alignment between reported experience and modelled outcomes. ",
      paste0("Based on ", sum(!is.na(sessions_clean$session_rating)),
             " sessions with participant ratings.")
    ),
    
    # Hero quote
    div(
      class = "ns-hero-quote",
      uiOutput(ns("hero_quote"))
    )
    
  )
}

# ── Server ────────────────────────────────────────────────────────────────────
impactOverviewServer <- function(id, sessions_clean, participants) {
  moduleServer(id, function(input, output, session) {
    
    # ── Computed values ───────────────────────────────────────────────────────
    avg_competence  <- round(mean(sessions_clean$competence,  na.rm = TRUE), 1)
    avg_autonomy    <- round(mean(sessions_clean$autonomy,    na.rm = TRUE), 1)
    avg_relatedness <- round(mean(sessions_clean$relatedness, na.rm = TRUE), 1)
    avg_rating      <- round(mean(sessions_clean$session_rating, na.rm = TRUE), 1)
    pct_rating      <- round(sum(!is.na(sessions_clean$session_rating)) /
                               nrow(sessions_clean) * 100)
    
    # ── KPI helper ────────────────────────────────────────────────────────────
    make_kpi_card <- function(value, label, sublabel, accent_color) {
      div(
        class = "ns-kpi-card",
        div(
          class = "ns-kpi-value",
          style = paste0("color:", accent_color, ";"),
          value
        ),
        div(class = "ns-kpi-label",    label),
        div(
          class = "ns-kpi-sublabel",
          style = "color:#8B949E; font-size:0.78rem;",
          sublabel
        )
      )
    }
    
    # ── KPI outputs ───────────────────────────────────────────────────────────
    output$kpi_competence <- renderUI({
      make_kpi_card(
        avg_competence, "Competence", "avg score / 9",
        bpn_colors["Competence"]
      )
    })
    
    output$kpi_autonomy <- renderUI({
      make_kpi_card(
        avg_autonomy, "Autonomy", "avg score / 9",
        bpn_colors["Autonomy"]
      )
    })
    
    output$kpi_relatedness <- renderUI({
      make_kpi_card(
        avg_relatedness, "Relatedness", "avg score / 9",
        bpn_colors["Relatedness"]
      )
    })
    
    output$kpi_rating <- renderUI({
      make_kpi_card(
        paste0(avg_rating, "/10"),
        "Session Rating",
        paste0("participant-reported (", pct_rating, "% of sessions)"),
        ns_colors$white
      )
    })
    
    # ── Takeaway text ─────────────────────────────────────────────────────────
    output$takeaway_text <- renderUI({
      # Identify lowest BPN
      bpn_vals  <- c(
        Competence  = avg_competence,
        Autonomy    = avg_autonomy,
        Relatedness = avg_relatedness
      )
      lowest <- names(which.min(bpn_vals))
      highest <- names(which.max(bpn_vals))
      
      p(
        class = "ns-takeaway-p",
        paste0(
          "Young people consistently report strong ", tolower(highest),
          " (", max(bpn_vals), "/9), while lower ", tolower(lowest),
          " scores suggest an opportunity to strengthen connection within sessions, ",
          "particularly through activities that build peer interaction."
        )
      )
    })
    
    # ── Hero quote ────────────────────────────────────────────────────────────
    output$hero_quote <- renderUI({
      # Auto-select: highest-scored session's most positive overall statement
      best_session <- sessions_clean |>
        filter(!is.na(most_positive_sentence_overall)) |>
        filter(stringr::str_count(most_positive_sentence_overall, "\\S+") >= 8) |>
        arrange(desc(bpn_mean)) |>
        slice(1)
      
      if (nrow(best_session) == 0) return(NULL)
      
      quote_text <- stringr::str_to_sentence(best_session$most_positive_sentence_overall)
      # Remove rating artifact: strip leading "N out of N?" pattern if present
      quote_text <- stringr::str_remove(quote_text, "^\\d+\\s+out\\s+of\\s+\\d+\\??\\s*")
      quote_text <- stringr::str_to_sentence(quote_text)
      
      div(
        class = "ns-quote-block",
        div(class = "ns-quote-mark", "\u201C"),
        p(class = "ns-quote-text", quote_text),
        div(class = "ns-quote-attr", "— participant reflection")
      )
    })
    
    # ── Rating / BPN alignment chart ──────────────────────────────────────────
    output$rating_bpn_chart <- renderGirafe({
      
      # 3-bin grouping: ≤8 merged (7–8 bin only n=9, too thin alone)
      rating_bins <- sessions_clean |>
        dplyr::filter(!is.na(session_rating)) |>
        dplyr::mutate(
          rating_bin = cut(
            session_rating,
            breaks = c(-Inf, 8, 9, Inf),
            labels = c("\u22648", "8\u20139", "9\u201310"),
            right  = TRUE
          )
        ) |>
        dplyr::group_by(rating_bin) |>
        dplyr::summarise(
          n       = dplyr::n(),
          avg_bpn = round(mean(bpn_mean, na.rm = TRUE), 2),
          .groups = "drop"
        ) |>
        dplyr::mutate(
          tooltip_text = paste0(
            "Rating: ", rating_bin,
            "\nAvg BPN: ", avg_bpn, " / 9",
            "\nSessions: ", n
          )
        )
      
      p <- ggplot2::ggplot(
        rating_bins,
        ggplot2::aes(
          x       = rating_bin,
          y       = avg_bpn,
          tooltip = tooltip_text,
          data_id = as.character(rating_bin)
        )
      ) +
        
        ggiraph::geom_col_interactive(
          fill  = "#8B949E",
          width = 0.5,
          alpha = 0.75
        ) +
        
        # Value labels
        ggplot2::geom_text(
          ggplot2::aes(label = avg_bpn),
          vjust    = -0.5,
          size     = 3.8,
          color    = "#C9D1D9",
          fontface = "bold"
        ) +
        
        # N labels inside bar bottom — avoids clipping below axis
        ggplot2::geom_text(
          ggplot2::aes(y = 0.15, label = paste0("n=", n)),
          vjust  = 0,
          size   = 2.8,
          color  = "#555E68"
        ) +
        
        ggplot2::scale_y_continuous(
          limits = c(0, 7.5),
          breaks = c(0, 3, 5, 7),
          labels = c("0", "3", "5", "7")
        ) +
        
        ggplot2::labs(
          x     = "Session rating (participant-reported)",
          y     = "Avg BPN score",
          title = "Do ratings align with modelled outcomes?"
        ) +
        
        theme_ns(base_size = 11) +
        ggplot2::theme(
          plot.title       = ggplot2::element_text(
            size   = 11,
            color  = ns_colors$text_muted,
            face   = "plain"
          ),
          panel.grid.major.x = ggplot2::element_blank(),
          panel.grid.major.y = ggplot2::element_line(
            color = "#21262D", linewidth = 0.3
          ),
          axis.text.x = ggplot2::element_text(color = "#C9D1D9", size = 10),
          axis.text.y = ggplot2::element_text(color = "#8B949E", size = 9)
        )
      
      ggiraph::girafe(
        ggobj     = p,
        width_svg  = 6,
        height_svg = 2.2,
        options   = list(
          ggiraph::opts_toolbar(saveaspng = FALSE),
          ggiraph::opts_hover(css = "opacity:0.85;"),
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
    
    # ── Critical: prevent lazy evaluation with CSS tabs ───────────────────────
    outputOptions(output, "kpi_competence",   suspendWhenHidden = FALSE)
    outputOptions(output, "kpi_autonomy",     suspendWhenHidden = FALSE)
    outputOptions(output, "kpi_relatedness",  suspendWhenHidden = FALSE)
    outputOptions(output, "kpi_rating",       suspendWhenHidden = FALSE)
    outputOptions(output, "takeaway_text",    suspendWhenHidden = FALSE)
    outputOptions(output, "rating_bpn_chart", suspendWhenHidden = FALSE)
    outputOptions(output, "hero_quote",       suspendWhenHidden = FALSE)
    
  })
}