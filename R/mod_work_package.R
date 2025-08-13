#' work_package UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList numericInput actionButton verbatimTextOutput
mod_work_package_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Work Package Management"),
    numericInput(ns("wp_number"), "Work Package Number", value = 1, min = 1),
    actionButton(ns("create_wp"), "Create Work Package and Save Data"),
    h4("Existing Work Packages"),
    verbatimTextOutput(ns("existing_wps"))
  )
}

#' work_package Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent reactive req renderPrint
#' @importFrom utils write.csv
mod_work_package_server <- function(id, imported_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive to list existing WPs
    existing_wps <- reactive({
      # List directories in ANALYSES and OUTPUT
      analyses_dirs <- list.dirs("ANALYSES", full.names = FALSE, recursive = FALSE)
      output_dirs <- list.dirs("OUTPUT", full.names = FALSE, recursive = FALSE)
      # Return a formatted string
      paste(
        "ANALYSES:", paste(analyses_dirs, collapse = ", "),
        "\nOUTPUT:", paste(output_dirs, collapse = ", ")
      )
    })

    # Render the list of existing WPs
    output$existing_wps <- renderPrint({
      existing_wps()
    })

    observeEvent(input$create_wp, {
      req(input$wp_number)
      wp_num <- input$wp_number

      # Call the create_wp function
      create_wp(wp_num)

      # Save the imported data
      req(imported_data())
      data_to_save <- imported_data()
      wp_name <- paste0("WP", wp_num)
      analyses_path <- file.path("ANALYSES", wp_name)
      output_file <- file.path(analyses_path, "imported_data.csv")
      write.csv(data_to_save, output_file, row.names = FALSE)

      # Show a notification (optional, but good for UX)
      showNotification(paste("Work Package", wp_num, "created and data saved."), type = "message")

      # Update the list of existing WPs
      output$existing_wps <- renderPrint({
        existing_wps()
      })
    })
  })
}
