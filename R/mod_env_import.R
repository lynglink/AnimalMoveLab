#' env_import UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList fileInput textInput actionButton
mod_env_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Import Environmental Layer"),
    fileInput(ns("env_file"), "Choose GeoTIFF File",
              accept = c(".tif", ".tiff")
    ),
    textInput(ns("layer_name"), "Layer Name", placeholder = "e.g., DEM"),
    actionButton(ns("import_env"), "Import Layer")
  )
}

#' env_import Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer
mod_env_import_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Server logic will be added in a future task
  })
}
