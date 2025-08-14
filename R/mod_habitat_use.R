#' habitat_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList checkboxGroupInput actionButton
#' @importFrom DT dataTableOutput
mod_habitat_use_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Covariate Extraction"),
    p("Select environmental layers to extract data from and append to the track data."),
    checkboxGroupInput(ns("raster_layers"), "Available Raster Layers:", choices = NULL),
    actionButton(ns("extract_covariates"), "Extract Covariate Data"),
    hr(),
    h5("Data with Extracted Covariates"),
    DT::dataTableOutput(ns("extraction_table"))
  )
}

#' habitat_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent req reactiveVal reactivePoll updateCheckboxGroupInput
#' @importFrom DT renderDataTable
#' @importFrom terra rast
#' @importFrom sf st_drop_geometry
mod_habitat_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    analysis_data <- reactiveVal(NULL)

    # Poll for changes in the RASTERS directory to update raster list
    available_rasters <- reactivePoll(1000, session,
      checkFunc = function() {
        if (dir.exists("RASTERS")) { list.files("RASTERS") } else { "" }
      },
      valueFunc = function() {
        if (dir.exists("RASTERS")) { list.files("RASTERS", pattern = "\\.tif$") } else { NULL }
      }
    )

    observeEvent(available_rasters(), {
      updateCheckboxGroupInput(session, "raster_layers", choices = available_rasters())
    })

    # Extraction logic
    observeEvent(input$extract_covariates, {
      req(current_data(), input$raster_layers)

      # Load selected rasters
      raster_paths <- file.path("RASTERS", input$raster_layers)
      raster_list <- lapply(raster_paths, rast)
      # Name the list elements based on file names (without extension)
      names(raster_list) <- tools::file_path_sans_ext(input$raster_layers)

      # Call helper function
      data_with_covariates <- extract_raster_values(current_data(), raster_list)

      # Store the result
      analysis_data(data_with_covariates)
    })

    # Display the resulting table
    output$extraction_table <- DT::renderDataTable({
      req(analysis_data())
      # Display non-spatial part of the data
      st_drop_geometry(analysis_data())
    }, options = list(scrollX = TRUE))

  })
}
