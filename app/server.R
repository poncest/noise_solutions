# server.R
# Main server function — delegates to module servers
# Each module handles its own outputs and outputOptions

server <- function(input, output, session) {

  # ── Module servers ──────────────────────────────────────────────────────────
  impactOverviewServer("impact",  sessions_clean, participants)
  bpnDeepDiveServer(  "bpn",     sessions_clean)
  voicesServer(       "voices",  sessions_clean)
  journeyServer(      "journey", sessions_clean, participants)

}
