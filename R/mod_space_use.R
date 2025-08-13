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
    p("Calculate home range area using classic methods."),
    actionButton(ns("run_mcp"), "Calculate MCP"),
    actionButton(ns("run_kde"), "Calculate KDE"),
    hr(),
    h5("Results"),
    verbatimTextOutput(ns("results"))
  )
}

#' space_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent eventReactive req reactiveVal renderPrint
#' @importFrom sf st_coordinates
#' @importFrom sp SpatialPointsDataFrame
#' @importFrom adehabitatHR mcp kernelUD kernel.area
mod_space_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    results_text <- reactiveVal("Results will be shown here.")

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

    output$results <- renderPrint({
      results_text()
    })

  })
}
