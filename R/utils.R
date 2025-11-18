# Utility Functions for spatialcovariates Package

#' Validate and standardize extent input
#'
#' @param extent Either an sf object or a numeric vector of length 4 (xmin, ymin, xmax, ymax)
#'
#' @return A numeric vector of length 4 with bbox coordinates
#' @keywords internal
validate_extent <- function(extent) {
  if (inherits(extent, "sf") || inherits(extent, "sfc")) {
    bbox <- sf::st_bbox(extent)
    return(as.numeric(bbox))
  } else if (inherits(extent, "SpatVector")) {
    bbox <- terra::ext(extent)
    return(c(bbox$xmin, bbox$ymin, bbox$xmax, bbox$ymax))
  } else if (is.numeric(extent) && length(extent) == 4) {
    names(extent) <- c("xmin", "ymin", "xmax", "ymax")
    return(extent)
  } else {
    stop("'extent' must be an sf object, SpatVector, or numeric vector of length 4 (xmin, ymin, xmax, ymax)")
  }
}

#' Parse resolution string to meters
#'
#' @param res_string Character string like "10km", "1000m", or "1deg"
#'
#' @return Numeric value in meters
#' @keywords internal
parse_resolution <- function(res_string) {
  if (is.numeric(res_string)) {
    return(res_string)
  }

  if (grepl("km$", res_string, ignore.case = TRUE)) {
    value <- as.numeric(gsub("[^0-9.]", "", res_string))
    return(value * 1000)
  } else if (grepl("m$", res_string, ignore.case = TRUE)) {
    value <- as.numeric(gsub("[^0-9.]", "", res_string))
    return(value)
  } else if (grepl("deg", res_string, ignore.case = TRUE)) {
    value <- as.numeric(gsub("[^0-9.]", "", res_string))
    return(value * 111000)  # Approximate: 1 degree ~ 111 km at equator
  } else {
    stop("Resolution string must end with 'km', 'm', or 'deg'")
  }
}

#' Calculate aggregation factor between two resolutions
#'
#' @param native_res Numeric, native resolution in meters
#' @param target_res Numeric, target resolution in meters
#'
#' @return Integer aggregation factor
#' @keywords internal
calc_aggregation_factor <- function(native_res, target_res) {
  factor <- round(target_res / native_res)
  if (factor < 1) {
    warning("Target resolution is finer than native resolution. Returning factor of 1.")
    return(1)
  }
  return(as.integer(factor))
}

#' Generate tile names for 10x10 degree global grid
#'
#' @param bbox Numeric vector of length 4 (xmin, ymin, xmax, ymax)
#' @param tile_size Numeric, size of tiles in degrees (default 10)
#'
#' @return Character vector of tile names in format "NNx_EEWW"
#' @keywords internal
calculate_tile_names <- function(bbox, tile_size = 10) {
  # Expand bbox to corner coordinates
  crds <- expand.grid(
    x = c(bbox[1], bbox[3]),
    y = c(bbox[2], bbox[4])
  )

  tile_names <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    lon <- tile_size * (crds$x[i] %/% tile_size)
    lat <- tile_size * (crds$y[i] %/% tile_size) + tile_size

    # Longitude formatting
    lon_letter <- ifelse(lon < 0, "W", "E")
    lon_str <- sprintf("%03d", abs(lon))

    # Latitude formatting
    lat_letter <- ifelse(lat < 0, "S", "N")
    lat_str <- sprintf("%02d", abs(lat))

    tile_names[i] <- paste0(lat_str, lat_letter, "_", lon_str, lon_letter)
  }

  return(unique(tile_names))
}

#' Download file with retry logic and exponential backoff
#'
#' @param url Character, URL to download from
#' @param destfile Character, destination file path
#' @param max_attempts Integer, maximum number of retry attempts (default 3)
#' @param timeout Numeric, timeout in seconds (default 600)
#' @param quiet Logical, suppress download messages (default FALSE)
#'
#' @return Logical, TRUE if successful, FALSE otherwise
#' @keywords internal
download_with_retry <- function(url, destfile, max_attempts = 3, timeout = 600, quiet = FALSE) {
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout))
  options(timeout = max(timeout, old_timeout))

  wget_tried <- FALSE  # Track if wget fallback was attempted
  ssl_warnings <- character(0)  # Capture SSL warnings

  for (attempt in 1:max_attempts) {
    current_attempt <- attempt  # Capture for error handler closure
    result <- tryCatch({
      # Try libcurl first for better HTTPS/redirect support
      method <- if (capabilities("libcurl")) "libcurl" else "auto"
      # Capture warnings to detect SSL issues
      suppressWarnings({
        warnings_list <- withCallingHandlers(
          utils::download.file(url, destfile, mode = "wb", quiet = quiet, method = method),
          warning = function(w) {
            ssl_warnings <<- c(ssl_warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        )
      })
      TRUE  # Success
    }, error = function(e) {
      # Check for SSL issues in either error message or captured warnings
      has_ssl_issue <- grepl("SSL|certificate", e$message, ignore.case = TRUE) ||
                      any(grepl("SSL|certificate", ssl_warnings, ignore.case = TRUE))

      # If SSL error detected and wget not yet tried, try wget with --no-check-certificate
      if (has_ssl_issue && !wget_tried) {
        wget_tried <<- TRUE  # Mark wget as tried (use <<- for parent scope)
        if (!quiet) message("SSL certificate issue detected, trying wget fallback...")
        wget_result <- tryCatch({
          utils::download.file(url, destfile, mode = "wb", quiet = quiet,
                             method = "wget", extra = "--no-check-certificate")
          TRUE  # wget succeeded
        }, error = function(e2) {
          NULL  # wget failed, continue to retry logic
        })
        if (!is.null(wget_result) && wget_result) {
          return(TRUE)  # wget succeeded, return success
        }
      }

      # Normal retry logic
      if (current_attempt < max_attempts) {
        wait_time <- 2^current_attempt  # Exponential backoff: 2, 4, 8 seconds
        if (!quiet) {
          message(sprintf("Download attempt %d failed. Retrying in %d seconds...",
                         current_attempt, wait_time))
        }
        Sys.sleep(wait_time)
        NULL  # Signal to retry
      } else {
        if (!quiet) {
          warning(sprintf("Failed to download %s after %d attempts: %s",
                         url, max_attempts, e$message))
        }
        FALSE  # Final failure
      }
    })

    if (!is.null(result) && result) {
      return(TRUE)
    } else if (!is.null(result) && !result) {
      return(FALSE)
    }
    # if result is NULL, continue to next attempt
  }

  return(FALSE)
}

#' Verify file download by comparing file sizes
#'
#' @param url Character, remote URL
#' @param local_path Character, local file path
#'
#' @return Logical, TRUE if sizes match, FALSE otherwise
#' @keywords internal
verify_download <- function(url, local_path) {
  if (!file.exists(local_path)) {
    return(FALSE)
  }

  tryCatch({
    response <- httr::HEAD(url)
    headers <- httr::headers(response)
    remote_size <- as.numeric(headers$`content-length`)
    local_size <- file.info(local_path)$size

    if (is.na(remote_size)) {
      # Cannot verify, assume OK
      return(TRUE)
    }

    return(remote_size == local_size)
  }, error = function(e) {
    # If verification fails, assume file is OK
    return(TRUE)
  })
}

#' Aggregate raster with proper handling of circular variables
#'
#' @param rast SpatRaster object
#' @param fact Integer, aggregation factor
#' @param circular Logical, whether variable is circular (e.g., aspect)
#' @param fun Character, aggregation function ("mean", "sum", "modal")
#'
#' @return Aggregated SpatRaster
#' @keywords internal
aggregate_raster <- function(rast, fact, circular = FALSE, fun = "mean") {
  if (fact == 1) {
    return(rast)
  }

  if (circular) {
    # Handle circular variables (e.g., aspect) using vector decomposition
    rast_rad <- rast * pi / 180
    rast_x <- terra::app(rast_rad, cos)
    rast_y <- terra::app(rast_rad, sin)

    # Aggregate components
    rast_x_agg <- terra::aggregate(rast_x, fact = fact, fun = mean, na.rm = TRUE)
    rast_y_agg <- terra::aggregate(rast_y, fact = fact, fun = mean, na.rm = TRUE)

    # Reconstruct angle
    rast_agg <- terra::app(c(rast_y_agg, rast_x_agg), function(x) {
      angle <- atan2(x[1], x[2]) * 180 / pi
      ifelse(angle < 0, angle + 360, angle)
    })

    return(rast_agg)
  } else {
    # Standard aggregation
    return(terra::aggregate(rast, fact = fact, fun = fun, na.rm = TRUE))
  }
}

#' Create output directory if it doesn't exist
#'
#' @param dir_path Character, directory path
#'
#' @return NULL (creates directory as side effect)
#' @keywords internal
ensure_directory <- function(dir_path) {
  if (!is.null(dir_path) && !dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
    message(sprintf("Created directory: %s", dir_path))
  }
}

#' List tiles that intersect with a region of interest
#'
#' @param roi sf object or bbox representing region of interest
#' @param tiles_dir Character, directory containing tile files
#' @param pattern Character, regex pattern to match tile files
#'
#' @return Character vector of file paths
#' @keywords internal
list_tiles_for_roi <- function(roi, tiles_dir, pattern) {
  if (!dir.exists(tiles_dir)) {
    stop(sprintf("Tiles directory does not exist: %s", tiles_dir))
  }

  all_files <- list.files(tiles_dir, pattern = pattern, full.names = TRUE)

  if (length(all_files) == 0) {
    stop(sprintf("No files matching pattern '%s' found in %s", pattern, tiles_dir))
  }

  # If roi is NULL, return all tiles
  if (is.null(roi)) {
    return(all_files)
  }

  bbox <- validate_extent(roi)
  tile_names <- calculate_tile_names(bbox)

  # Filter files that match required tile names
  matched_files <- character()
  for (tile_name in tile_names) {
    matched <- grep(tile_name, all_files, value = TRUE)
    matched_files <- c(matched_files, matched)
  }

  if (length(matched_files) == 0) {
    warning(sprintf("No tiles found intersecting ROI. Required tiles: %s",
                   paste(tile_names, collapse = ", ")))
  }

  return(unique(matched_files))
}
