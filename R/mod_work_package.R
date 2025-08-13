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
    h3("Work Package Management"),
    h4("Create New Work Package"),
    numericInput(ns("wp_number"), "Work Package Number", value = 1, min = 1),
    actionButton(ns("create_wp"), "Create Work Package and Save Data"),
    hr(),
    h4("Load from Existing Work Package"),
    selectInput(ns("select_wp"), "Choose Work Package", choices = NULL),
    actionButton(ns("load_data"), "Load Data"),
    hr(),
    h4("Existing Work Packages"),
    verbatimTextOutput(ns("existing_wps"))
  )
}

#' work_package Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent reactive req renderPrint reactiveVal updateSelectInput showNotification
#' @importFrom utils write.csv read.csv
mod_work_package_server <- function(id, imported_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    loaded_data <- reactiveVal()

    # Reactive to get the list of work packages
    wp_list <- reactive({
      list.dirs("ANALYSES", full.names = FALSE, recursive = FALSE)
    })

    # Update the select input when the list of work packages changes
    observeEvent(wp_list(), {
      updateSelectInput(session, "select_wp", choices = wp_list())
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

    # Handle creation of a new work package
    observeEvent(input$create_wp, {
      req(input$wp_number)
      wp_num <- input$wp_number

      create_wp(wp_num)

      req(imported_data())
      data_to_save <- imported_data()
      wp_name <- paste0("WP", wp_num)
      analyses_path <- file.path("ANALYSES", wp_name)
      output_file <- file.path(analyses_path, "imported_data.csv")
      write.csv(data_to_save, output_file, row.names = FALSE)

      showNotification(paste("Work Package", wp_num, "created and data saved."), type = "message")
    })

    # Handle loading data from a work package
    observeEvent(input$load_data, {
      req(input$select_wp)
      wp_name <- input$select_wp
      data_file <- file.path("ANALYSES", wp_name, "imported_data.csv")

      if (file.exists(data_file)) {
        loaded_data(read.csv(data_file))
        showNotification(paste("Data loaded from", wp_name), type = "message")
      } else {
        showNotification(paste("Could not find data file in", wp_name), type = "error")
      }
    })

    return(loaded_data)
  })
}
