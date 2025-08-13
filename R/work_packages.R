#' Create Work Package directories
#'
#' This function creates the necessary subdirectories for a new work package (WP)
#' within the 'ANALYSES' and 'OUTPUT' folders.
#'
#' @param wp_number An integer representing the work package number.
#'
#' @return Nothing, called for its side effects.
#' @export
#'
#' @examples
#' \dontrun{
#' create_wp(1)
#' }
create_wp <- function(wp_number) {
  if (!is.numeric(wp_number) || wp_number <= 0 || floor(wp_number) != wp_number) {
    stop("wp_number must be a positive integer.")
  }

  wp_name <- paste0("WP", wp_number)

  analyses_path <- file.path("ANALYSES", wp_name)
  output_path <- file.path("OUTPUT", wp_name)

  if (!dir.exists(analyses_path)) {
    dir.create(analyses_path, recursive = TRUE)
    message(paste("Created directory:", analyses_path))
  } else {
    message(paste("Directory already exists:", analyses_path))
  }

  if (!dir.exists(output_path)) {
    dir.create(output_path, recursive = TRUE)
    message(paste("Created directory:", output_path))
  } else {
    message(paste("Directory already exists:", output_path))
  }
}
