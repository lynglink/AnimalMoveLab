#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  imported_data <- mod_data_import_server("data_import_1")
  mod_data_viewer_server("data_viewer_1", imported_data)
  mod_work_package_server("work_package_1", imported_data)
}
