#' Extract Raster Values at Point Locations
#'
#' This function takes a spatial points data frame (`sf` object) and a named list
#' of `terra` SpatRaster objects. It extracts the value of each raster at each
#' point location and appends these values as new columns to the input data frame.
#'
#' @param gps_data An `sf` object containing POINT geometries.
#' @param raster_list A named list of `SpatRaster` objects. The names of the list
#'   elements will be used as the new column names.
#'
#' @return The input `sf` data frame with new columns containing the extracted
#'   raster values.
#' @export
#'
#' @importFrom terra extract
#' @importFrom sf st_drop_geometry st_as_sf st_geometry
#'
#' @examples
#' \dontrun{
#' # Create sample data
#' library(sf)
#' library(terra)
#' pts <- st_as_sf(data.frame(x = 1:5, y = 1:5), coords = c("x", "y"), crs = "EPSG:4326")
#' r1 <- rast(xmin = 0, xmax = 5, ymin = 0, ymax = 5, resolution = 1)
#' values(r1) <- 1:25
#' r2 <- rast(r1)
#' values(r2) <- 26:50
#' raster_list <- list(layer1 = r1, layer2 = r2)
#'
#' # Extract values
#' result <- extract_raster_values(pts, raster_list)
#' print(result)
#' }
extract_raster_values <- function(gps_data, raster_list) {
  if (!inherits(gps_data, "sf")) {
    stop("gps_data must be an sf object.")
  }
  if (!is.list(raster_list) || !all(sapply(raster_list, inherits, "SpatRaster"))) {
    stop("raster_list must be a list of SpatRaster objects.")
  }
  if (is.null(names(raster_list)) || any(names(raster_list) == "")) {
    stop("raster_list must be a named list with non-empty names.")
  }

  # Extract values for each raster in the list
  extracted_vals <- lapply(raster_list, function(r) {
    # terra::extract returns a data.frame with an ID and the layer value
    terra::extract(r, gps_data)[, -1]
  })

  # Combine the extracted values into a single data frame
  extracted_df <- do.call(cbind, extracted_vals)
  names(extracted_df) <- names(raster_list)

  # cbind the extracted values to the original data frame (without its geometry)
  result_df <- cbind(
    sf::st_drop_geometry(gps_data),
    extracted_df
  )

  # Restore the geometry to make it an sf object again
  result_sf <- sf::st_as_sf(result_df, geometry = sf::st_geometry(gps_data))

  return(result_sf)
}
