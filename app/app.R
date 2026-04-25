# app.R
# Entry point for shinyapps.io
# Sources: global.R → ui.R → server.R → modules (in order)
# Hard rule: NO ui_main.R or server_main.R in R/ folder

# Source global.R first — packages, data, colors, theme
source("global.R")

# Source modules AFTER global.R has run
source("modules/mod_impact_overview.R")
source("modules/mod_bpn_deep_dive.R")
source("modules/mod_voices.R")
source("modules/mod_journey.R")

# Source UI and server (these depend on global.R objects)
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)