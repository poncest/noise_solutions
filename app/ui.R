# ui.R
# Main UI definition — sources AFTER global.R so ns_colors and app_info are available
# Uses shiny.semantic (Appsilon) for dark, modern aesthetic

ui <- semanticPage(
  title = "Noise Solution | Impact Dashboard",
  theme = "slate",   # Dark base theme — we override with custom CSS
  
  # Load custom CSS (brand tokens, typography, component overrides)
  tags$head(
    tags$link(
      rel  = "stylesheet",
      href = "styles.css"
    )
  ),
  
  # ── Header ─────────────────────────────────────────────────────────────────
  div(
    class = "ns-header",
    div(
      class = "ns-header-inner",
      div(
        class = "ns-logo-area",
        span(class = "ns-logo-text", "NOISE"),
        span(class = "ns-logo-accent", "SOLUTION")
      ),
      div(
        style = "display: flex; align-items: center; gap: 1.5em;",
        div(
          class = "ns-header-subtitle",
          "Impact Dashboard \u2014 Music Mentoring"
        ),
        tags$button(
          class   = "ns-about-btn",
          onclick = "$('.ui.modal.about-modal').modal('show');",
          icon("info circle"), " About"
        )
      )
    )
  ),
  
  # ── About modal ────────────────────────────────────────────────────────────
  div(
    class = "ui modal about-modal",
    div(
      class = "ns-modal-header",
      icon("music"),
      " About This Dashboard"
    ),
    div(
      class = "content",
      style = paste0(
        "background:", "#0D1117", ";",
        "color:", "#FFFFFF", ";",
        "padding: 2em;"
      ),
      tags$p(
        style = "margin-bottom: 1.5em;",
        tags$strong(style = paste0("color:", "#BEFF00", ";"), "Noise Solution"),
        " is a social enterprise that uses one-to-one music mentoring to support ",
        "young people experiencing mental health challenges, exclusion from education, ",
        "or other significant difficulties."
      ),
      tags$p(
        style = "margin-bottom: 1.5em;",
        "This dashboard visualises outcomes from Noise Solution\u2019s music mentoring sessions ",
        "and is designed to help programme leads and commissioners understand where sessions ",
        "are most effective and where additional support may be needed."
      ),
      tags$p(
        style = "margin-bottom: 2em;",
        "Scores are mapped to ",
        tags$strong("Self-Determination Theory"),
        " \u2014 measuring three basic needs: Competence, Autonomy, and Relatedness."
      ),
      tags$p(
        style = "margin-bottom: 0.8em;",
        "Scores are derived through AI analysis of participant reflection videos recorded ",
        "during or shortly after each session. Each session is analysed up to five times ",
        "to reduce variability; values shown are session averages."
      ),
      tags$p(
        style = paste0("margin-bottom: 0.8em; color:", "#A8B3BC", ";"),
        "Scores range from 1 (not supported) to 9 (fully supported), ",
        "with 5 representing the midpoint."
      ),
      tags$p(
        style = paste0("margin-bottom: 1.5em; color:", "#A8B3BC", ";"),
        "Patterns shown are descriptive and should be interpreted ",
        "in the context of sample size and session variation."
      ),
      tags$hr(style = paste0("border-color:", "#21262D", "; margin: 1.5em 0;")),
      tags$p(
        style = paste0("color:", "#8B949E", "; font-size: 0.9em;"),
        "Designed by ",
        tags$strong(style = "color:#FFFFFF;", "Steven Ponce"),
        " as part of the Data ChangeMakers volunteer programme. ",
        tags$a(
          href   = "https://www.noisesolution.org",
          target = "_blank",
          style  = paste0("color:", "#BEFF00", ";"),
          "noisesolution.org"
        ),
        " \u00b7 ",
        tags$a(
          href   = "https://stevenponce.netlify.app/",
          target = "_blank",
          style  = paste0("color:", "#BEFF00", ";"),
          "stevenponce.netlify.app"
        )
      )
    ),
    div(
      class = "actions",
      style = paste0("background:", "#0D1117", "; border-top: 1px solid ", "#21262D", ";"),
      tags$button(
        class   = "ui button",
        style   = paste0(
          "background:", "#21262D", ";",
          "color:", "#FFFFFF", ";",
          "font-family: Barlow, sans-serif;"
        ),
        onclick = "$('.ui.modal.about-modal').modal('hide');",
        "Close"
      )
    )
  ),
  
  # ── Tab navigation ─────────────────────────────────────────────────────────
  div(
    class = "ui secondary pointing menu ns-tab-menu",
    a(class = "active item", `data-tab` = "impact",   "Impact"),
    a(class = "item",        `data-tab` = "bpn",      "How Support Varies"),
    a(class = "item",        `data-tab` = "voices",   "In Their Words"),
    a(class = "item",        `data-tab` = "journey",  "Over Time")
  ),
  
  # ── Tab content ────────────────────────────────────────────────────────────
  div(
    class = "ui active tab segment ns-tab-content",
    `data-tab` = "impact",
    impactOverviewUI("impact")
  ),
  
  div(
    class = "ui tab segment ns-tab-content",
    `data-tab` = "bpn",
    bpnDeepDiveUI("bpn")
  ),
  
  div(
    class = "ui tab segment ns-tab-content",
    `data-tab` = "voices",
    voicesUI("voices")
  ),
  
  div(
    class = "ui tab segment ns-tab-content",
    `data-tab` = "journey",
    journeyUI("journey")
  ),
  
  # ── Tab init JS ────────────────────────────────────────────────────────────
  # Required: Semantic UI CSS tabs don't notify Shiny when they become visible
  # This fires a Shiny input change so outputs can render
  tags$script(HTML("
    $(document).ready(function() {
      $('.ns-tab-menu .item').tab({
        onVisible: function(tabPath) {
          Shiny.setInputValue('active_tab', tabPath, {priority: 'event'});
        }
      });
    });
  ")),
  
  # ── Footer ─────────────────────────────────────────────────────────────────
  div(
    class = "ns-footer",
    p(class = "ns-footer-text",
      "BPN scores are derived from AI analysis of participant reflection videos, ",
      "mapped to Self-Determination Theory domains (Competence, Autonomy, Relatedness). ",
      "Scores are session averages of up to 5 analyses per session. ",
      "Patterns are associative; sample size limits generalisation."
    )
  )
)