#' space_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList actionButton verbatimTextOutput downloadButton selectInput fluidRow column
mod_space_use_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Home Range Estimation"),
    p("Calculate home range area using classic or modern methods."),
    fluidRow(
      column(4, actionButton(ns("run_mcp"), "Calculate MCP")),
      column(4, actionButton(ns("run_kde"), "Calculate KDE")),
      column(4, actionButton(ns("run_akde"), "Calculate AKDE"))
    ),
    hr(),
    h5("Area Results"),
    verbatimTextOutput(ns("results")),
    hr(),
    h5("AKDE Model Summary"),
    verbatimTextOutput(ns("akde_summary")),
    hr(),
    h5("Export Home Range Polygons"),
    p("Exports the most recently calculated home range as a Shapefile."),
    selectInput(ns("wp_export_target"), "Select WP for Server-Side Save", choices = NULL),
    downloadButton(ns("export_poly"), "Download Shapefile")
  )
}

#' space_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent eventReactive req reactiveVal renderPrint downloadHandler updateSelectInput reactivePoll showNotification
#' @importFrom sf st_coordinates st_as_sf st_write
#' @importFrom sp SpatialPointsDataFrame
#' @importFrom adehabitatHR mcp kernelUD kernel.area getverticeshr
#' @importFrom ctmm as.telemetry variogram ctmm.guess ctmm.fit akde
mod_space_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    results_text <- reactiveVal("Results will be shown here.")
    akde_summary_text <- reactiveVal("AKDE model summary will be shown here.")
    home_range_poly <- reactiveVal(NULL)

    # Poll for changes in the OUTPUT directory to update WP selector
    wp_list <- reactivePoll(1000, session,
      checkFunc = function() {
        if (dir.exists("OUTPUT")) { list.files("OUTPUT") } else { "" }
      },
      valueFunc = function() {
        if (dir.exists("OUTPUT")) { list.files("OUTPUT") } else { NULL }
      }
    )

    observeEvent(wp_list(), {
      updateSelectInput(session, "wp_export_target", choices = wp_list())
    })

    # Convert sf data to SpatialPointsDataFrame for adehabitatHR
    sp_data <- eventReactive(current_data(), {
      req(current_data())

      # Assuming the first column is the animal ID
      track_id <- current_data()[[1]]

      # adehabitatHR needs a data.frame with the ID column
      df <- data.frame(id = track_id)

      # Create SpatialPointsDataFrame
      SpatialPointsDataFrame(
        coords = st_coordinates(current_data()),
        data = df,
        proj4string = current_data()$geometry@proj4string
      )
    })

    # MCP Calculation
    observeEvent(input$run_mcp, {
      req(sp_data())
      results_text("Calculating MCP...")
      akde_summary_text("")

      mcp_poly <- mcp(sp_data(), percent = 95)
      home_range_poly(st_as_sf(mcp_poly)) # Store sf object

      area_m2 <- mcp_poly$area
      area_ha <- area_m2 / 10000
      results_text(paste("MCP (95%) Area:", round(area_m2, 2), "m^2 |", round(area_ha, 2), "hectares"))
    })

    # KDE Calculation
    observeEvent(input$run_kde, {
      req(sp_data())
      results_text("Calculating KDE...")
      akde_summary_text("")

      kde_ud <- kernelUD(sp_data(), h = "href")
      kde_poly <- getverticeshr(kde_ud, percent = 95)
      home_range_poly(st_as_sf(kde_poly)) # Store sf object

      kde_area_m2 <- kernel.area(kde_ud, percent = 95)
      area_ha <- kde_area_m2$`95` / 10000
      results_text(paste("KDE (95%) Area:", round(kde_area_m2$`95`, 2), "m^2 |", round(area_ha, 2), "hectares"))
    })

    # AKDE Calculation
    observeEvent(input$run_akde, {
      req(current_data())
      results_text("Calculating AKDE...")
      akde_summary_text("Converting data to telemetry object...")
      req("timestamp" %in% names(current_data()))

      telemetry_data <- as.telemetry(current_data())

      akde_summary_text("Calculating variogram...")
      vg <- variogram(telemetry_data)

      akde_summary_text("Guessing initial model parameters...")
      guess <- ctmm.guess(telemetry_data, variogram = vg, interactive = FALSE)

      akde_summary_text("Fitting movement model (this may take a moment)...")
      fit <- ctmm.fit(telemetry_data, guess)

      akde_summary_text("Calculating AKDE home range...")
      akde_result <- akde(telemetry_data, fit)
      home_range_poly(st_as_sf(akde_result)) # Store sf object

      akde_area_m2 <- summary(akde_result)$CI[2]
      akde_area_ha <- akde_area_m2 / 10000
      results_text(paste("AKDE (95%) Area:", round(akde_area_m2, 2), "m^2 |", round(akde_area_ha, 2), "hectares"))

      summary_capture <- capture.output(summary(fit))
      akde_summary_text(paste(summary_capture, collapse = "\n"))
    })

    output$results <- renderPrint({
      results_text()
    })

    output$akde_summary <- renderPrint({
      akde_summary_text()
    })

    # Download Handler
    output$export_poly <- downloadHandler(
      filename = function() {
        paste("home_range-", Sys.Date(), ".zip", sep = "")
      },
      content = function(file) {
        req(home_range_poly(), input$wp_export_target)

        # Define paths for server-side save
        wp_path <- file.path("OUTPUT", input$wp_export_target)
        shp_name <- paste0("homerange_", Sys.Date(), ".shp")
        server_path <- file.path(wp_path, shp_name)

        # Save to server
        st_write(home_range_poly(), server_path, delete_layer = TRUE)
        showNotification(paste("Saved homerange to", server_path), type = "message")

        # Save to a temporary directory for user download
        temp_dir <- tempdir()
        temp_path <- file.path(temp_dir, shp_name)
        st_write(home_range_poly(), temp_path, delete_layer = TRUE)

        # Zip the shapefile components for download
        zip(
          zipfile = file,
          files = list.files(temp_dir, pattern = "homerange_.*", full.names = TRUE),
          flags = "-j" # junk paths
        )
      }
    )

  })
}
