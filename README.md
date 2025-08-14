# Animal MoveLab

## Overview

Animal MoveLab is a local-first Shiny/Golem platform designed for animal movement ecology analysis. It provides a robust and reproducible environment for scientists to import, process, visualize, and analyze animal tracking data.

The application is built incrementally, following a detailed project roadmap, to ensure that each feature is modular and well-defined.

## Current Features

The application currently supports the foundational steps of a typical movement analysis workflow:

*   **Project Setup & Metadata:**
    *   Define project-level metadata (Project Name, Researcher, Species).
    *   Save metadata to a `project.yml` file for provenance and reproducibility.
    *   Create standardized folder structures for analysis work packages (`ANALYSES/WPn`, `OUTPUT/WPn`).

*   **Data Import & Processing:**
    *   Import raw animal track data from CSV files.
    *   Specify the Coordinate Reference System (CRS) of the source data via its EPSG code.
    *   Define a target analysis CRS to standardize all project data.
    *   The application automatically transforms the data to the target CRS.

*   **Data Persistence:**
    *   The processed, CRS-corrected spatial data is automatically saved as a `cleaned_tracks.gpkg` file in the project's `GPS/` directory. This GeoPackage file serves as the canonical, cleaned data source for all subsequent analyses.

*   **Data Loading & Visualization:**
    *   Load the cleaned GeoPackage data back into the application at any time.
    *   Visualize the animal movement track with an interactive plot.
    *   Dynamically select the columns to be used for the X and Y axes.
    *   The plot automatically displays the CRS of the data, providing clear visual feedback.
    *   View the raw data in a searchable, sortable table.

*   **Environmental Data Integration:**
    *   Import environmental data as GeoTIFF raster layers (e.g., DEM, land cover).
    *   Reproject environmental layers to the common project analysis CRS.
    *   Extract covariate values from multiple raster layers at each GPS location.

*   **Core Space-Use Analysis:**
    *   Calculate classic home range estimators: Minimum Convex Polygon (MCP) and Kernel Density Estimation (KDE).
    *   Calculate modern, statistically robust home ranges using Autocorrelated Kernel Density Estimation (AKDE) via the `ctmm` package.
    *   View and compare area estimates for all calculated home ranges in a summary table.
    *   Visualize and compare all calculated home range polygons on a single map, overlaid on the movement track.
    *   Export any calculated home range polygon as a Shapefile for use in GIS software.

*   **Habitat Use & Selection:**
    *   Extract environmental covariate data for both used and available points.
    *   Fit Resource Selection Function (RSF) models to analyze habitat selection.
    *   Generate prediction maps of relative habitat suitability.
    *   Fit Step-Selection Function (SSF) models to analyze fine-scale habitat selection in relation to movement.

## Quick Start Guide

1.  **Launch the Application.**
2.  **Set Project Metadata:** In the "Project Management" panel, enter your project's name, researcher, and species, then click "Save Metadata".
3.  **Import Data:**
    *   In the "Data Import" panel, click "Choose CSV File" to select your raw data file. The CSV must contain columns named `x` and `y` for the coordinates.
    *   Enter the "Source EPSG Code" for your raw data (e.g., 4326 for WGS84).
    *   Enter the desired "Target Analysis EPSG Code" for your project.
    *   Click "Import and Process Data".
4.  **View Data:** The movement track plot and data table will automatically update with the imported and transformed data. Note the CRS displayed in the plot's caption.
5.  **Create Analysis Folders:** In the "Project Management" panel, enter a number and click "Create WP Folders" to create standardized directories for storing analysis outputs.
6.  **Reload Data:** In future sessions, you can click "Load Cleaned GPS Data" to load the processed `cleaned_tracks.gpkg` file directly without needing to re-import the raw CSV.
7.  **Import Environmental Data:** In the sidebar, use the "Import Environmental Layer" section to upload GeoTIFF files for your study area.
8.  **Extract Covariates:** Navigate to the "Habitat Use" tab. Select the desired raster layers and click "Extract Covariate Data" to append the environmental data to your tracking data.
9.  **Analyze Space-Use:** Navigate to the "Space-Use Analysis" tab. Click the buttons to calculate MCP, KDE, and/or AKDE. View the results in the table and map, and export the polygons using the download button.
10. **Analyze Habitat Use:** Navigate to the "Habitat Use" tab to run RSF or SSF analyses and generate prediction maps.

## Future Work

This application is under active development. Future enhancements may include advanced movement analysis, reporting, and user experience improvements.
