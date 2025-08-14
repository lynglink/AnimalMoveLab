#' space_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList actionButton verbatimTextOutput downloadButton selectInput fluidRow column tableOutput plotOutput
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
    downloadButton(ns("export_poly"), "Download Shapefile"),
    hr(),
    h4("Comparison of Estimators"),
    h5("Area Comparison Table"),
    tableOutput(ns("comparison_table")),
    h5("Map Comparison"),
    plotOutput(ns("comparison_plot"))
  )
}

#' space_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent eventReactive req reactiveVal renderPrint downloadHandler updateSelectInput reactivePoll showNotification renderTable renderPlot
#' @importFrom sf st_coordinates st_as_sf st_write
#' @importFrom sp SpatialPointsDataFrame
#' @importFrom adehabitatHR mcp kernelUD kernel.area getverticeshr
#' @importFrom ctmm as.telemetry variogram ctmm.guess ctmm.fit akde
#' @importFrom ggplot2 ggplot geom_sf aes theme_minimal labs scale_fill_viridis_d
mod_space_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    results_text <- reactiveVal("Results will be shown here.")
    akde_summary_text <- reactiveVal("AKDE model summary will be shown here.")
    home_range_poly <- reactiveVal(NULL) # for single download
    all_hr_results <- reactiveVal(list()) # for comparison

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
      mcp_sf <- st_as_sf(mcp_poly)
      home_range_poly(mcp_sf)

      area_m2 <- mcp_poly$area
      area_ha <- area_m2 / 10000

      # Add to results list
      new_res <- list(method = "MCP", area_m2 = area_m2, area_ha = area_ha, poly = mcp_sf)
      all_hr_results(c(all_hr_results(), list(new_res)))

      results_text(paste("MCP (95%) Area:", round(area_m2, 2), "m^2 |", round(area_ha, 2), "hectares"))
    })

    # KDE Calculation
    observeEvent(input$run_kde, {
      req(sp_data())
      results_text("Calculating KDE...")
      akde_summary_text("")

      kde_ud <- kernelUD(sp_data(), h = "href")
      kde_poly <- getverticeshr(kde_ud, percent = 95)
      kde_sf <- st_as_sf(kde_poly)
      home_range_poly(kde_sf)

      area_m2 <- kernel.area(kde_ud, percent = 95)$`95`
      area_ha <- area_m2 / 10000

      # Add to results list
      new_res <- list(method = "KDE", area_m2 = area_m2, area_ha = area_ha, poly = kde_sf)
      all_hr_results(c(all_hr_results(), list(new_res)))

      results_text(paste("KDE (95%) Area:", round(area_m2, 2), "m^2 |", round(area_ha, 2), "hectares"))
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
      akde_sf <- st_as_sf(akde_result)
      home_range_poly(akde_sf)

      area_m2 <- summary(akde_result)$CI[2]
      area_ha <- area_m2 / 10000

      # Add to results list
      new_res <- list(method = "AKDE", area_m2 = area_m2, area_ha = area_ha, poly = akde_sf)
      all_hr_results(c(all_hr_results(), list(new_res)))

      results_text(paste("AKDE (95%) Area:", round(area_m2, 2), "m^2 |", round(area_ha, 2), "hectares"))

      summary_capture <- capture.output(summary(fit))
      akde_summary_text(paste(summary_capture, collapse = "\n"))
    })

    output$results <- renderPrint({
      results_text()
    })

    output$akde_summary <- renderPrint({
      akde_summary_text()
    })

    # Comparison Table
    output$comparison_table <- renderTable({
      req(length(all_hr_results()) > 0)

      # Convert list of results to a data frame
      results_df <- do.call(rbind, lapply(all_hr_results(), function(res) {
        data.frame(
          Method = res$method,
          Area_m2 = res$area_m2,
          Area_ha = res$area_ha
        )
      }))

      # Clean up names for display
      names(results_df) <- c("Method", "Area (m^2)", "Area (hectares)")

      results_df
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

    # Comparison Plot
    output$comparison_plot <- renderPlot({
      req(length(all_hr_results()) > 0, current_data())

      # Combine all polygons into one sf data frame for plotting
      all_polys <- do.call(rbind, lapply(all_hr_results(), function(res) {
        # Add a method column to the sf object
        res$poly$method <- res$method
        res$poly
      }))

      ggplot() +
        geom_sf(data = current_data(), alpha = 0.5, color = "grey50") +
        geom_sf(data = all_polys, aes(fill = method), alpha = 0.4) +
        scale_fill_viridis_d(name = "Estimator") +
        labs(
          title = "Home Range Comparison",
          subtitle = "Displaying all calculated home range polygons.",
          caption = paste("CRS:", st_crs(current_data())$input)
        ) +
        theme_minimal()
    })

  })
}
