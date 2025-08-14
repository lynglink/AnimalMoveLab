#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  current_data <- reactiveVal()

  # Data from the import module
  data_from_import <- mod_data_import_server("data_import_1")

  # Data from the work package module
  data_from_wp <- mod_work_package_server("work_package_1", data_from_import)

  # When new data is imported, update the current_data reactiveVal
  observeEvent(data_from_import(), {
    current_data(data_from_import())
  })

  # When new data is loaded from a work package, update the current_data reactiveVal
  observeEvent(data_from_wp(), {
    current_data(data_from_wp())
  })

  # Data from the environmental import module
  mod_env_import_server("env_import_1")

  # Pass the current data to the data viewer module
  mod_data_viewer_server("data_viewer_1", current_data)
  # Pass the current data to the plot viewer module
  mod_plot_view_server("plot_view_1", current_data)
  # Pass the current data to the space-use module
  mod_space_use_server("space_use_1", current_data)
}
