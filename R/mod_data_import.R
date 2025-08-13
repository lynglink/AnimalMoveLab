#' data_import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList fileInput actionButton numericInput
mod_data_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fileInput(ns("file"), "Choose CSV File",
              accept = c(
                "text/csv",
                "text/comma-separated-values,text/plain",
                ".csv")
    ),
    numericInput(ns("source_crs"), "Source EPSG Code", value = 4326),
    numericInput(ns("target_crs"), "Target Analysis EPSG Code", value = 4326),
    actionButton(ns("import"), "Import and Process Data")
  )
}

#' data_import Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer eventReactive req showNotification
#' @importFrom utils read.csv
#' @importFrom sf st_as_sf st_write st_transform
mod_data_import_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    imported_data <- eventReactive(input$import, {
      req(input$file, input$source_crs, input$target_crs)

      # Read the raw CSV data
      raw_data <- read.csv(input$file$datapath)

      # --- Roadmap Alignment (Phase 1) ---

      # 1. Ensure GPS directory exists
      if (!dir.exists("GPS")) {
        dir.create("GPS")
      }

      # 2. Convert to sf object with user-defined source CRS
      req("x" %in% names(raw_data), "y" %in% names(raw_data))
      initial_sf <- st_as_sf(raw_data, coords = c("x", "y"), crs = input$source_crs)

      # 3. Transform to the target analysis CRS
      transformed_sf <- st_transform(initial_sf, crs = input$target_crs)

      # 4. Write transformed data to GeoPackage file
      output_path <- file.path("GPS", "cleaned_tracks.gpkg")
      st_write(transformed_sf, output_path, delete_layer = TRUE)

      showNotification(
        paste("Data imported, transformed to EPSG:", input$target_crs, "and saved."),
        type = "message"
      )

      # Return the transformed spatial data
      return(transformed_sf)
    })

    return(imported_data)
  })
}

## To be copied in the UI
# mod_data_import_ui("data_import_1")

## To be copied in the server
# mod_data_import_server("data_import_1")
