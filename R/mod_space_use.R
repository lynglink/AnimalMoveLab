#' space_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList actionButton verbatimTextOutput
mod_space_use_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Home Range Estimation"),
    p("Calculate home range area using classic or modern methods."),
    actionButton(ns("run_mcp"), "Calculate MCP"),
    actionButton(ns("run_kde"), "Calculate KDE"),
    actionButton(ns("run_akde"), "Calculate AKDE"),
    hr(),
    h5("Area Results"),
    verbatimTextOutput(ns("results")),
    hr(),
    h5("AKDE Model Summary"),
    verbatimTextOutput(ns("akde_summary"))
  )
}

#' space_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent eventReactive req reactiveVal renderPrint
#' @importFrom sf st_coordinates
#' @importFrom sp SpatialPointsDataFrame
#' @importFrom adehabitatHR mcp kernelUD kernel.area
#' @importFrom ctmm as.telemetry variogram ctmm.guess ctmm.fit akde
mod_space_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    results_text <- reactiveVal("Results will be shown here.")
    akde_summary_text <- reactiveVal("AKDE model summary will be shown here.")

    # Convert sf data to SpatialPointsDataFrame for adehabitatHR
    sp_data <- eventReactive(current_data(), {
      req(current_data())

      # Assuming the first column is the animal ID
      track_id <- current_data()[[1]]

      # adehabitatHR needs a data.frame with the ID column
      df <- data.frame(id = track_id)

      # Create SpatialPointsDataFrame
      SpatialPointsDataFrame(
        coords = st_coordinates(current_data()),
        data = df,
        proj4string = current_data()$geometry@proj4string
      )
    })

    # MCP Calculation
    observeEvent(input$run_mcp, {
      req(sp_data())

      results_text("Calculating MCP...")
      akde_summary_text("") # Clear AKDE summary

      mcp_poly <- mcp(sp_data(), percent = 95)
      area_m2 <- mcp_poly$area
      area_ha <- area_m2 / 10000

      results_text(
        paste("MCP (95%) Area:",
              round(area_m2, 2), "m^2",
              "|",
              round(area_ha, 2), "hectares")
      )
    })

    # KDE Calculation
    observeEvent(input$run_kde, {
      req(sp_data())

      results_text("Calculating KDE...")
      akde_summary_text("") # Clear AKDE summary

      kde_ud <- kernelUD(sp_data(), h = "href")
      kde_area_m2 <- kernel.area(kde_ud, percent = 95)
      # kernel.area returns a data.frame
      area_ha <- kde_area_m2$`95` / 10000

      results_text(
        paste("KDE (95%) Area:",
              round(kde_area_m2$`95`, 2), "m^2",
              "|",
              round(area_ha, 2), "hectares")
      )
    })

    # AKDE Calculation
    observeEvent(input$run_akde, {
      req(current_data())

      results_text("Calculating AKDE...")
      akde_summary_text("Converting data to telemetry object...")

      # ctmm requires a timestamp, assume a column named 'timestamp' exists
      # A more robust implementation would allow column selection.
      req("timestamp" %in% names(current_data()))

      telemetry_data <- as.telemetry(current_data())

      akde_summary_text("Calculating variogram...")
      vg <- variogram(telemetry_data)

      akde_summary_text("Guessing initial model parameters...")
      guess <- ctmm.guess(telemetry_data, variogram = vg, interactive = FALSE)

      akde_summary_text("Fitting movement model (this may take a moment)...")
      fit <- ctmm.fit(telemetry_data, guess)

      akde_summary_text("Calculating AKDE home range...")
      akde_result <- akde(telemetry_data, fit)

      # Update results
      akde_area_ha <- summary(akde_result)$CI[2] / 10000 # Get estimate in hectares
      akde_area_m2 <- summary(akde_result)$CI[2]
      results_text(
        paste("AKDE (95%) Area:",
              round(akde_area_m2, 2), "m^2",
              "|",
              round(akde_area_ha, 2), "hectares")
      )

      # Update summary
      # Capture the summary print output to a string
      summary_capture <- capture.output(summary(fit))
      akde_summary_text(paste(summary_capture, collapse = "\n"))
    })

    output$results <- renderPrint({
      results_text()
    })

    output$akde_summary <- renderPrint({
      akde_summary_text()
    })

  })
}
