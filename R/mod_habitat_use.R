#' habitat_use UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList checkboxGroupInput actionButton verbatimTextOutput plotOutput
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
    verbatimTextOutput(ns("rsf_summary")),
    hr(),
    h4("3. Prediction Map"),
    p("Generate a map of predicted relative habitat suitability based on the fitted RSF model."),
    actionButton(ns("predict_map"), "Generate Prediction Map"),
    plotOutput(ns("prediction_plot")),
    hr(),
    h4("4. Step Selection Function (SSF)"),
    p("Fit a conditional logistic regression model to model habitat selection as a function of movement steps."),
    actionButton(ns("fit_ssf"), "Fit SSF Model"),
    hr(),
    h5("SSF Model Summary"),
    verbatimTextOutput(ns("ssf_summary")),
    hr(),
    h4("5. Predicted UD from SSF"),
    p("Simulate a path based on the fitted SSF model to generate a predicted Utilization Distribution (UD)."),
    actionButton(ns("simulate_ud"), "Simulate & Plot UD from SSF"),
    plotOutput(ns("ud_plot"))
  )
}

#' habitat_use Server Functions
#'
#' @noRd
#' @importFrom shiny moduleServer observeEvent req reactiveVal reactivePoll updateCheckboxGroupInput showNotification renderPrint renderPlot
#' @importFrom DT renderDataTable
#' @importFrom terra rast predict plot
#' @importFrom sf st_drop_geometry st_bbox st_as_sf st_sample st_crs
#' @importFrom stats as.formula glm
#' @importFrom amt make_track steps random_steps extract_covariates fit_clogit log_rss simulate_path rasterize_path
mod_habitat_use_server <- function(id, current_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    analysis_data <- reactiveVal(NULL)
    rsf_model_obj <- reactiveVal(NULL)
    rsf_summary_text <- reactiveVal("RSF model summary will be shown here.")
    prediction_raster <- reactiveVal(NULL)
    ssf_model_obj <- reactiveVal(NULL)
    ssf_summary_text <- reactiveVal("SSF model summary will be shown here.")
    ud_raster <- reactiveVal(NULL)

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

      # Store the model object
      rsf_model_obj(rsf_model)

      # Capture and store summary
      summary_capture <- capture.output(summary(rsf_model))
      rsf_summary_text(paste(summary_capture, collapse = "\n"))
    })

    output$rsf_summary <- renderPrint({
      rsf_summary_text()
    })

    # Prediction Map Logic
    observeEvent(input$predict_map, {
      req(rsf_model_obj(), input$raster_layers)

      showNotification("Generating prediction map...", type = "message")

      # Load the raster stack used for the model
      raster_paths <- file.path("RASTERS", input$raster_layers)
      raster_stack <- rast(raster_paths)
      names(raster_stack) <- tools::file_path_sans_ext(input$raster_layers)

      # Use terra::predict
      pred_map <- predict(raster_stack, rsf_model_obj(), type = "response")

      prediction_raster(pred_map)
      showNotification("Prediction map generated.", type = "message")
    })

    output$prediction_plot <- renderPlot({
      req(prediction_raster())
      plot(prediction_raster(), main = "Predicted Habitat Suitability")
    })

    # SSF Model Fitting Logic
    observeEvent(input$fit_ssf, {
      req(current_data(), input$raster_layers)

      ssf_summary_text("Fitting SSF model (this may take a while)...")

      tryCatch({
        # 1. Create track
        # Assuming x, y, timestamp columns exist and ID is the first column
        req("timestamp" %in% names(current_data()), "x" %in% names(current_data()), "y" %in% names(current_data()))
        track <- make_track(
          st_drop_geometry(current_data()),
          .x = x, .y = y, .t = timestamp,
          id = current_data()[[1]],
          crs = st_crs(current_data())
        )

        # 2. Generate steps
        # Using a default resampling rate and number of random steps for now
        steps <- steps(track)
        random_steps <- random_steps(steps, n_control = 10)

        # 3. Extract Covariates
        # Load the raster stack used for the model
        raster_paths <- file.path("RASTERS", input$raster_layers)
        raster_stack <- rast(raster_paths)
        names(raster_stack) <- tools::file_path_sans_ext(input$raster_layers)

        steps_with_covs <- extract_covariates(random_steps, raster_stack)

        # 4. Fit Model
        # Formula includes movement parameters (step length, turning angle)
        # and habitat covariates.
        model_formula <- paste(
          "case_ ~",
          paste(names(raster_stack), collapse = " + "),
          "+ cos(ta_) + sl_ + log(sl_)"
        )

        ssf_model <- fit_clogit(steps_with_covs, as.formula(model_formula))

        # 5. Store model and display summary
        ssf_model_obj(ssf_model)
        summary_capture <- capture.output(summary(ssf_model))
        ssf_summary_text(paste(summary_capture, collapse = "\n"))

      }, error = function(e) {
        ssf_summary_text(paste("Error fitting SSF model:", e$message))
        showNotification("Error fitting SSF model.", type = "error")
      })
    })

    output$ssf_summary <- renderPrint({
      ssf_summary_text()
    })

    # SSF Prediction/Simulation Logic
    observeEvent(input$simulate_ud, {
      req(ssf_model_obj(), input$raster_layers, current_data())

      showNotification("Simulating predicted UD from SSF...", type = "message")

      tryCatch({
        # Load the raster stack used for the model
        raster_paths <- file.path("RASTERS", input$raster_layers)
        raster_stack <- rast(raster_paths)
        names(raster_stack) <- tools::file_path_sans_ext(input$raster_layers)

        # Calculate log_rss
        log_rss <- log_rss(raster_stack, ssf_model_obj())

        # Simulate path
        # Note: This can be slow. n_steps is kept low for a demo.
        sim_path <- simulate_path(log_rss, n_steps = 1000)

        # Rasterize path to get UD
        sim_ud <- rasterize_path(sim_path, raster_stack[[1]])

        ud_raster(sim_ud)
        showNotification("Predicted UD generated.", type = "message")

      }, error = function(e) {
        showNotification(paste("Error generating UD:", e$message), type = "error")
      })
    })

    output$ud_plot <- renderPlot({
      req(ud_raster())
      plot(ud_raster(), main = "Predicted UD from SSF")
    })

  })
}
