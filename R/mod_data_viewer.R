#' data_viewer UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
#' @importFrom DT dataTableOutput
mod_data_viewer_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Imported Data"),
    DT::dataTableOutput(ns("data_table"))
  )
}

#' data_viewer Server Functions
#'
#' @param imported_data A reactive expression that returns the imported data.
#' @noRd
#' @importFrom DT renderDataTable
mod_data_viewer_server <- function(id, imported_data){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    output$data_table <- DT::renderDataTable({
      req(imported_data())
      imported_data()
    })
  })
}

## To be copied in the UI
# mod_data_viewer_ui("data_viewer_1")

## To be copied in the server
# mod_data_viewer_server("data_viewer_1")
