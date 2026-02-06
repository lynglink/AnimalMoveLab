# CLAUDE.md — AI Assistant Guide for Animal MoveLab

## Project Overview

Animal MoveLab is a local-first R Shiny application built with the [Golem](https://thinkr-open.github.io/golem/) framework for animal movement ecology analysis. Scientists use it to import, process, visualize, and analyze GPS tracking data entirely on their local machine.

**Package name:** `animal.movement.analysis`
**Version:** 0.0.0.9000 (early development)
**License:** GPL-3

## Repository Structure

```
AnimalMoveLab/
├── R/                        # All R source code (Shiny modules + utilities)
│   ├── app_config.R          # App configuration, file upload limits, golem config
│   ├── app_server.R          # Main server: wires up all modules via reactives
│   ├── app_ui.R              # Main UI: sidebar layout with tabbed main panel
│   ├── run_app.R             # Entry point: run_app() launches the Shiny app
│   ├── mod_data_import.R     # Module: CSV import with CRS transformation → GeoPackage
│   ├── mod_data_viewer.R     # Module: interactive data table (DT)
│   ├── mod_plot_view.R       # Module: ggplot2 movement track visualization
│   ├── mod_env_import.R      # Module: GeoTIFF raster import and reprojection
│   ├── mod_work_package.R    # Module: project metadata (YAML) and work package mgmt
│   ├── mod_space_use.R       # Module: MCP, KDE, AKDE home range estimators
│   ├── mod_habitat_use.R     # Module: RSF and SSF habitat analysis
│   ├── work_packages.R       # Exported function: create_wp()
│   └── utils_helpers.R       # Exported function: extract_raster_values()
├── tests/
│   └── testthat/
│       ├── test-utils_helpers.R   # Tests for extract_raster_values()
│       └── test-work_packages.R   # Tests for create_wp()
├── man/                      # Roxygen2-generated .Rd documentation
├── inst/
│   ├── app/www/              # Static web assets (favicon)
│   └── golem-config.yml      # Golem framework configuration
├── dev/                      # Golem development workflow scripts
│   ├── 01_start.R            # Initial project setup
│   ├── 02_dev.R              # Add modules, dependencies, CI templates
│   ├── 03_deploy.R           # Package checks and deployment
│   └── run_dev.R             # Quick-launch script for development
├── DESCRIPTION               # R package metadata and dependencies
├── NAMESPACE                 # Roxygen2-generated exports
├── README.md                 # Project documentation and feature status
├── INSTALL.md                # Installation and setup instructions
├── run_tests.R               # Script to run test suite
└── .Rbuildignore             # Files excluded from R CMD build
```

### Runtime data directories (created by the app, not in version control)

```
GPS/                          # Imported tracking data (cleaned_tracks.gpkg)
RASTERS/                      # Imported environmental layers (.tif)
ANALYSES/WPn/                 # Work package analysis scripts
OUTPUT/WPn/                   # Work package outputs (shapefiles, plots)
project.yml                   # Project metadata (name, researcher, species)
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `golem` | Shiny app framework (module scaffolding, config, deployment) |
| `shiny` | Web application framework |
| `sf` | Spatial data (points, tracks) as Simple Features |
| `terra` | Raster data handling (GeoTIFF import, reprojection) |
| `sp` | Legacy spatial classes (required by adehabitatHR) |
| `adehabitatHR` | Home range estimation (MCP, KDE) |
| `ctmm` | Continuous-time movement modeling (AKDE) |
| `amt` | Animal Movement Tools (step-selection functions) |
| `ggplot2` | Plotting and visualization |
| `DT` | Interactive data tables |
| `yaml` | Project metadata persistence |
| `config` | Golem configuration management |

## Architecture

### Golem Module Pattern

Every feature is a self-contained Shiny module with a paired UI and server function:

```r
mod_<feature>_ui <- function(id) {
  ns <- NS(id)
  tagList(...)
}

mod_<feature>_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    ...
  })
}
```

Modules are wired together in `app_server.R` via a central `current_data` reactive value. Data flows:

1. `mod_data_import` or `mod_work_package` produces spatial data
2. `app_server.R` updates `current_data` reactiveVal
3. Downstream modules (`data_viewer`, `plot_view`, `space_use`, `habitat_use`) receive `current_data`

### Exported Functions

Only two functions are exported in NAMESPACE:
- `run_app()` — launch the Shiny application
- `create_wp(wp_number)` — create work package directory structure

### Data Flow

- **Input:** CSV files with GPS coordinates + EPSG codes for source/target CRS
- **Storage:** GeoPackage (`cleaned_tracks.gpkg`) for vector data, GeoTIFF for rasters
- **Metadata:** YAML (`project.yml`) for project configuration
- **Output:** Shapefiles for home ranges, prediction rasters for habitat models

## Development Commands

### Run the application
```r
# Option 1: Via golem
golem::run_dev()

# Option 2: Direct
devtools::load_all()
run_app()
```

### Run tests
```r
# From R console
devtools::load_all()
testthat::test_dir("tests/testthat")

# Or use the helper script
source("run_tests.R")
```

### Regenerate documentation
```r
devtools::document()
```

### Package check
```r
devtools::check()
```

## Testing Conventions

- **Framework:** testthat edition 3
- **Location:** `tests/testthat/`
- **Naming:** `test-<module_or_function>.R`
- **Pattern:** Each test creates its own fixtures (sample rasters, points), runs the function, and asserts results. Tests clean up after themselves.
- Tests require `devtools::load_all()` before running since this is a package.

## Code Conventions

### Naming
- Module files: `mod_<feature>.R` (e.g., `mod_space_use.R`)
- Module functions: `mod_<feature>_ui()`, `mod_<feature>_server()`
- Utility files: `utils_<topic>.R`
- Module IDs in app_server.R: `"<feature>_1"` (e.g., `"space_use_1"`)

### Shiny Patterns
- Use `NS(id)` for namespacing all UI input/output IDs
- Use `req()` to guard against missing reactive values
- Use `tryCatch()` for operations that may fail (file I/O, spatial transforms)
- Use `showNotification()` for user-facing success/error messages
- Use `reactiveVal()` for shared mutable state, `eventReactive()` for derived data

### Documentation
- Roxygen2 comments (`#'`) for exported functions
- `@noRd` for internal functions that should not generate .Rd files
- `@import shiny` on main app functions; `@importFrom` for specific functions elsewhere

### Spatial Data
- All spatial data uses the `sf` package (Simple Features)
- Rasters use `terra` (not the older `raster` package)
- CRS transformations via `sf::st_transform()` and `terra::project()`
- The `sp` package is only used where required by `adehabitatHR`

## Adding a New Module

1. Create `R/mod_<name>.R` with `mod_<name>_ui()` and `mod_<name>_server()`
2. Add the UI call in `app_ui.R` (sidebar or as a new tab)
3. Wire the server call in `app_server.R`, passing `current_data` if needed
4. Add roxygen2 `@importFrom` tags for any new package functions used
5. Run `devtools::document()` to regenerate NAMESPACE
6. Add tests in `tests/testthat/test-<name>.R`

## Common Pitfalls

- The `shiny.maxRequestSize` option is set in `app_config.R` (100 MB). This file is sourced at package load time; moving it elsewhere may break large file uploads.
- `adehabitatHR` requires `sp` objects, so `sf` → `sp` conversion (via `as(x, "Spatial")`) is needed in `mod_space_use.R`.
- The `NAMESPACE` file is auto-generated by roxygen2 — never edit it by hand. Run `devtools::document()` after changing `@import`/`@importFrom` tags.
- `run_tests.R` calls `testthat::test_package("tests/testthat")` which uses the directory path, not the package name. This is non-standard but works for this project.
- Runtime data directories (GPS/, RASTERS/, ANALYSES/, OUTPUT/) are created by the app and should not be committed to version control.

## Git Conventions

- **Commit prefixes:** `feat:`, `fix:`, `docs:`, `debug:`, `refactor:`, `test:`
- **Branch strategy:** Feature branches merged via pull requests to `main`
- **No CI/CD configured yet** — tests must be run locally before pushing
