#' data_import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList fileInput actionButton
mod_data_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fileInput(ns("file"), "Choose CSV File",
              accept = c(
                "text/csv",
                "text/comma-separated-values,text/plain",
                ".csv")
    ),
    actionButton(ns("import"), "Import Data")
  )
}

#' data_import Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer eventReactive req showNotification
#' @importFrom utils read.csv
#' @importFrom sf st_as_sf st_write
mod_data_import_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    imported_data <- eventReactive(input$import, {
      req(input$file)

      # Read the raw CSV data
      raw_data <- read.csv(input$file$datapath)

      # --- Roadmap Alignment (Phase 1) ---
      # This section converts the imported data to a spatial object
      # and saves it to the standardized project structure.

      # 1. Ensure GPS directory exists
      if (!dir.exists("GPS")) {
        dir.create("GPS")
      }

      # 2. Convert to sf object (assuming x, y columns and WGS84 CRS)
      # A more robust implementation would allow user to select columns and CRS.
      req("x" %in% names(raw_data), "y" %in% names(raw_data))
      spatial_data <- st_as_sf(raw_data, coords = c("x", "y"), crs = 4326)

      # 3. Write to GeoPackage file
      output_path <- file.path("GPS", "cleaned_tracks.gpkg")
      st_write(spatial_data, output_path, delete_layer = TRUE)

      showNotification(paste("Data imported and saved to", output_path), type = "message")

      # Return the spatial data for use in other modules
      return(spatial_data)
    })

    return(imported_data)
  })
}

## To be copied in the UI
# mod_data_import_ui("data_import_1")

## To be copied in the server
# mod_data_import_server("data_import_1")
