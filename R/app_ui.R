#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    fluidPage(
      h1("Animal Movement Analysis"),
      sidebarLayout(
        sidebarPanel(
          mod_data_import_ui("data_import_1"),
          hr(),
          mod_work_package_ui("work_package_1")
        ),
        mainPanel(
          mod_plot_view_ui("plot_view_1"),
          hr(),
          mod_data_viewer_ui("data_viewer_1")
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "animal.movement.analysis"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
