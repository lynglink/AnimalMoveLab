#' plot_view UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList plotOutput selectInput fluidRow column
mod_plot_view_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Movement Track Visualization"),
    fluidRow(
      column(6, selectInput(ns("x_col"), "X-axis", choices = NULL)),
      column(6, selectInput(ns("y_col"), "Y-axis", choices = NULL))
    ),
    plotOutput(ns("track_plot"))
  )
}

#' plot_view Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent req updateSelectInput renderPlot
#' @importFrom ggplot2 ggplot geom_path aes labs theme_minimal
#' @importFrom sf st_crs
mod_plot_view_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Update column choices when new data is loaded
    observeEvent(current_data(), {
      req(current_data())
      choices <- names(current_data())
      updateSelectInput(session, "x_col", choices = choices, selected = choices[1])
      updateSelectInput(session, "y_col", choices = choices, selected = choices[2])
    })

    # Render the movement plot
    output$track_plot <- renderPlot({
      req(current_data(), input$x_col, input$y_col)
      data <- current_data()

      # Ensure selected columns are numeric
      req(is.numeric(data[[input$x_col]]), is.numeric(data[[input$y_col]]))

      ggplot(data, aes(x = .data[[input$x_col]], y = .data[[input$y_col]])) +
        geom_path() +
        labs(
          title = "Animal Movement Track",
          x = input$x_col,
          y = input$y_col,
          caption = paste("CRS:", st_crs(data)$input)
        ) +
        theme_minimal()
    })
  })
}
