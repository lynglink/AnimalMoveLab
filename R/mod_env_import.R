#' env_import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList fileInput textInput actionButton numericInput verbatimTextOutput
mod_env_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Import Environmental Layer"),
    fileInput(ns("env_file"), "Choose GeoTIFF File",
              accept = c(".tif", ".tiff")
    ),
    textInput(ns("layer_name"), "Layer Name", placeholder = "e.g., DEM"),
    numericInput(ns("target_crs_env"), "Target Analysis EPSG Code", value = 4326),
    actionButton(ns("import_env"), "Import Layer"),
    hr(),
    h5("Available Raster Layers"),
    verbatimTextOutput(ns("available_rasters"))
  )
}

#' env_import Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent req showNotification reactivePoll renderPrint
#' @importFrom terra rast project writeRaster
mod_env_import_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Poll for changes in the RASTERS directory
    available_rasters <- reactivePoll(1000, session,
      checkFunc = function() {
        if (dir.exists("RASTERS")) {
          list.files("RASTERS")
        } else {
          ""
        }
      },
      valueFunc = function() {
        if (dir.exists("RASTERS")) {
          list.files("RASTERS")
        } else {
          "No raster directory found."
        }
      }
    )

    output$available_rasters <- renderPrint({
      paste(available_rasters(), collapse = "\n")
    })

    observeEvent(input$import_env, {
      req(input$env_file, input$layer_name, input$target_crs_env)

      # Create RASTERS directory if it doesn't exist
      if (!dir.exists("RASTERS")) {
        dir.create("RASTERS")
      }

      tryCatch({
        # Read the uploaded raster
        uploaded_raster <- rast(input$env_file$datapath)

        # Define the target CRS string
        target_crs_string <- paste0("EPSG:", input$target_crs_env)

        # Reproject the raster
        # Using bilinear for continuous data, could be "near" for categorical
        reprojected_raster <- project(uploaded_raster, target_crs_string, method = "bilinear")

        # Define output path
        file_name <- paste0(gsub(" ", "_", input$layer_name), ".tif")
        output_path <- file.path("RASTERS", file_name)

        # Write the raster as a tiled, compressed GeoTIFF (COG-like)
        writeRaster(
          reprojected_raster,
          output_path,
          overwrite = TRUE,
          gdal = c("TILED=YES", "COMPRESS=LZW", "COPY_SRC_OVERVIEWS=YES")
        )

        showNotification(
          paste("Raster layer '", input$layer_name, "' saved to ", output_path),
          type = "message"
        )

      }, error = function(e) {
        showNotification(paste("Error processing raster:", e$message), type = "error")
      })
    })
  })
}
