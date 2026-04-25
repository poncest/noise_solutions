# modules/mod_voices.R
# Tab 3: In Their Words
# The hero tab — surfacing participant language per BPN domain

# ── UI ────────────────────────────────────────────────────────────────────────
voicesUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    div(
      class = "ns-section-header",
      h2(class = "ns-section-title", "What young people said."),
      p(class  = "ns-section-sub",
        "What young people said about their experiences — ",
        "drawn from session reflection videos")
    ),
    
    # Sentiment toggle
    div(
      class = "ns-toggle-row",
      div(
        class = "ui buttons",
        actionButton(ns("show_positive"), "Positive moments",
                     class = "ui button active ns-toggle-btn"),
        actionButton(ns("show_negative"), "Challenges",
                     class = "ui button ns-toggle-btn")
      )
    ),
    
    # Quote cards — one per BPN domain
    div(
      class = "ui three column stackable grid ns-voices-grid",
      
      div(
        class = "column",
        uiOutput(ns("quote_competence"))
      ),
      div(
        class = "column",
        uiOutput(ns("quote_autonomy"))
      ),
      div(
        class = "column",
        uiOutput(ns("quote_relatedness"))
      )
    ),
    
    # Refresh button — subtle, secondary
    div(
      class = "ns-refresh-row",
      actionButton(ns("refresh_quotes"), "Show another moment",
                   class = "ui basic button ns-refresh-btn",
                   icon  = icon("refresh"),
                   style = "font-size:0.85em; opacity:0.7;")
    ),
    
    # JS handler for toggle active state (avoids updateActionButton class arg crash)
    tags$script(HTML(paste0(
      "Shiny.addCustomMessageHandler('toggleBtn', function(msg) {",
      "  $('#' + msg.active).addClass('active');",
      "  $('#' + msg.inactive).removeClass('active');",
      "});"
    ))),
    
    # Context note
    div(
      class = "ns-context-note",
      icon("info circle"),
      " Quotes are drawn from AI-transcribed reflection videos. ",
      "They represent individual sessions and may not reflect a participant's overall experience."
    )
    
  )
}

# ── Server ────────────────────────────────────────────────────────────────────
voicesServer <- function(id, sessions_clean) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # ── State ──────────────────────────────────────────────────────────────────
    sentiment <- reactiveVal("positive")
    quote_seed <- reactiveVal(1)   # Changes on refresh to cycle quotes
    
    observeEvent(input$show_positive, {
      sentiment("positive")
      session$sendCustomMessage("toggleBtn", list(
        active   = ns("show_positive"),
        inactive = ns("show_negative")
      ))
    })
    
    observeEvent(input$show_negative, {
      sentiment("negative")
      session$sendCustomMessage("toggleBtn", list(
        active   = ns("show_negative"),
        inactive = ns("show_positive")
      ))
    })
    
    observeEvent(input$refresh_quotes, {
      quote_seed(quote_seed() + 1)
    })
    
    # ── Quote selection helper ────────────────────────────────────────────────
    get_quote <- function(domain, sent, seed) {
      col <- paste0(
        "most_", sent, "_sentence_", tolower(domain)
      )
      
      if (!col %in% names(sessions_clean)) return(NULL)
      
      pool <- sessions_clean |>
        filter(!is.na(.data[[col]])) |>
        filter(stringr::str_count(.data[[col]], "\\S+") >= 8) |>
        arrange(desc(bpn_mean))
      
      if (nrow(pool) == 0) return(NULL)
      
      # Cycle through top quotes using seed
      idx <- ((seed - 1) %% min(nrow(pool), 10)) + 1
      pool[[col]][idx]
    }
    
    # ── Quote card helper ──────────────────────────────────────────────────────
    make_quote_card <- function(domain, quote_text, sent) {
      accent <- bpn_colors[domain]
      sentiment_label <- if (sent == "positive") "positive moment" else "challenge"
      
      if (is.null(quote_text)) {
        return(
          div(
            class = "ns-quote-card ns-quote-empty",
            style = paste0("border-top: 3px solid ", accent, ";"),
            div(class = "ns-quote-domain", style = paste0("color:", accent, ";"), domain),
            p(class = "ns-quote-empty-text", "No quote available for this filter.")
          )
        )
      }
      
      div(
        class = "ns-quote-card",
        style = paste0("border-top: 3px solid ", accent, ";"),
        div(class = "ns-quote-domain",
            style = paste0("color:", accent, ";"),
            domain),
        div(class = "ns-quote-mark-sm", "\u201C"),
        p(class = "ns-quote-card-text",
          stringr::str_to_sentence(quote_text))
      )
    }
    
    # ── Quote outputs ─────────────────────────────────────────────────────────
    output$quote_competence <- renderUI({
      s <- sentiment()
      q <- get_quote("Competence", s, quote_seed())
      make_quote_card("Competence", q, s)
    })
    
    output$quote_autonomy <- renderUI({
      s <- sentiment()
      q <- get_quote("Autonomy", s, quote_seed())
      make_quote_card("Autonomy", q, s)
    })
    
    output$quote_relatedness <- renderUI({
      s <- sentiment()
      q <- get_quote("Relatedness", s, quote_seed())
      make_quote_card("Relatedness", q, s)
    })
    
    # ── outputOptions ─────────────────────────────────────────────────────────
    outputOptions(output, "quote_competence",  suspendWhenHidden = FALSE)
    outputOptions(output, "quote_autonomy",    suspendWhenHidden = FALSE)
    outputOptions(output, "quote_relatedness", suspendWhenHidden = FALSE)
    
  })
}