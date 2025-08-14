#' habitat_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList checkboxGroupInput actionButton verbatimTextOutput
#' @importFrom DT dataTableOutput
mod_habitat_use_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("1. Covariate Extraction"),
    p("Select environmental layers to extract data from and append to the track data."),
    checkboxGroupInput(ns("raster_layers"), "Available Raster Layers:", choices = NULL),
    actionButton(ns("extract_covariates"), "Extract Covariate Data"),
    hr(),
    h5("Data with Extracted Covariates"),
    DT::dataTableOutput(ns("extraction_table")),
    hr(),
    h4("2. Resource Selection Function (RSF)"),
    p("Build and fit a logistic regression model (GLM) to model habitat selection."),
    checkboxGroupInput(ns("rsf_predictors"), "Select Predictor Variables:", choices = NULL),
    actionButton(ns("fit_rsf"), "Fit RSF Model"),
    hr(),
    h5("RSF Model Summary"),
    verbatimTextOutput(ns("rsf_summary"))
  )
}

#' habitat_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent req reactiveVal reactivePoll updateCheckboxGroupInput showNotification renderPrint
#' @importFrom DT renderDataTable
#' @importFrom terra rast
#' @importFrom sf st_drop_geometry st_bbox st_as_sf st_sample
#' @importFrom stats as.formula glm
mod_habitat_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    analysis_data <- reactiveVal(NULL)
    rsf_summary_text <- reactiveVal("RSF model summary will be shown here.")

    # Poll for changes in the RASTERS directory to update raster list
    available_rasters <- reactivePoll(1000, session,
      checkFunc = function() {
        if (dir.exists("RASTERS")) { list.files("RASTERS") } else { "" }
      },
      valueFunc = function() {
        if (dir.exists("RASTERS")) { list.files("RASTERS", pattern = "\\.tif$") } else { NULL }
      }
    )

    observeEvent(available_rasters(), {
      updateCheckboxGroupInput(session, "raster_layers", choices = available_rasters())
    })

    # Extraction and Available Points Logic
    observeEvent(input$extract_covariates, {
      req(current_data(), input$raster_layers)

      showNotification("Extracting covariates for used points...", type = "message")

      # Load selected rasters
      raster_paths <- file.path("RASTERS", input$raster_layers)
      raster_list <- lapply(raster_paths, rast)
      covariate_names <- tools::file_path_sans_ext(input$raster_layers)
      names(raster_list) <- covariate_names

      # 1. Used points
      used_pts <- extract_raster_values(current_data(), raster_list)
      used_pts$used <- 1

      # 2. Available points
      showNotification("Generating available points...", type = "message")
      study_area <- st_bbox(used_pts)
      # Generate 10x available points
      available_pts_sf <- st_as_sf(st_sample(st_as_sfc(study_area), size = nrow(used_pts) * 10))

      showNotification("Extracting covariates for available points...", type = "message")
      available_pts <- extract_raster_values(available_pts_sf, raster_list)
      available_pts$used <- 0

      # 3. Combine and store
      # Ensure column names match before rbind
      # (used_pts has original data, available_pts does not. Need to match them)
      cols_to_keep <- c(covariate_names, "used", "geometry")
      final_data <- rbind(
        used_pts[, names(used_pts) %in% cols_to_keep],
        available_pts[, names(available_pts) %in% cols_to_keep]
      )

      analysis_data(final_data)

      # Update predictor choices for RSF model
      updateCheckboxGroupInput(session, "rsf_predictors", choices = covariate_names)

      showNotification("Data prepared for RSF analysis.", type = "message")
    })

    # Display the resulting table
    output$extraction_table <- DT::renderDataTable({
      req(analysis_data())
      # Display non-spatial part of the data
      st_drop_geometry(analysis_data())
    }, options = list(scrollX = TRUE))

    # RSF Model Fitting Logic
    observeEvent(input$fit_rsf, {
      req(analysis_data(), input$rsf_predictors)

      rsf_summary_text("Fitting RSF model...")

      # Create formula
      formula_str <- paste("used ~", paste(input$rsf_predictors, collapse = " + "))

      # Fit GLM
      # Note: na.omit is a simple way to handle NAs from raster extraction
      # at edges, a more robust solution might involve checking/imputing.
      model_data <- na.omit(st_drop_geometry(analysis_data()))
      rsf_model <- glm(
        as.formula(formula_str),
        family = binomial(link = "logit"),
        data = model_data
      )

      # Capture and store summary
      summary_capture <- capture.output(summary(rsf_model))
      rsf_summary_text(paste(summary_capture, collapse = "\n"))
    })

    output$rsf_summary <- renderPrint({
      rsf_summary_text()
    })

  })
}
