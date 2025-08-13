#' work_package UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList numericInput actionButton verbatimTextOutput selectInput
mod_work_package_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Project Management"),
    h4("Load Cleaned GPS Data"),
    actionButton(ns("load_data"), "Load Cleaned GPS Data"),
    hr(),
    h4("Create New Analysis Work Package"),
    numericInput(ns("wp_number"), "Work Package Number", value = 1, min = 1),
    actionButton(ns("create_wp"), "Create WP Folders"),
    hr(),
    h4("Existing Analysis Work Packages"),
    verbatimTextOutput(ns("existing_wps"))
  )
}

#' work_package Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent reactive req renderPrint reactiveVal updateSelectInput showNotification
#' @importFrom sf st_read
mod_work_package_server <- function(id, imported_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    loaded_data <- reactiveVal()

    # Reactive to get the list of work packages
    wp_list <- reactive({
      list.dirs("ANALYSES", full.names = FALSE, recursive = FALSE)
    })

    # Reactive to format the list of existing WPs for display
    existing_wps_text <- reactive({
      analyses_dirs <- wp_list()
      output_dirs <- list.dirs("OUTPUT", full.names = FALSE, recursive = FALSE)
      paste(
        "ANALYSES:", paste(analyses_dirs, collapse = ", "),
        "\nOUTPUT:", paste(output_dirs, collapse = ", ")
      )
    })

    # Render the list of existing WPs
    output$existing_wps <- renderPrint({
      existing_wps_text()
    })

    # Handle creation of a new work package's folders
    observeEvent(input$create_wp, {
      req(input$wp_number)
      wp_num <- input$wp_number
      create_wp(wp_num)
      showNotification(paste("Work Package", wp_num, "folders created."), type = "message")
    })

    # Handle loading the primary cleaned data
    observeEvent(input$load_data, {
      data_file <- file.path("GPS", "cleaned_tracks.gpkg")

      if (file.exists(data_file)) {
        loaded_data(st_read(data_file))
        showNotification(paste("Loaded cleaned data from", data_file), type = "message")
      } else {
        showNotification(paste("Cleaned data file not found at", data_file), type = "error")
      }
    })

    return(loaded_data)
  })
}
