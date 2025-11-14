# Potapov Forest Canopy Height Functions

#' Generate Potapov height tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names
#' @keywords internal
potapov_tile_names <- function(roi) {
  bbox <- validate_extent(roi)
  tile_names <- calculate_tile_names(bbox, tile_size = 10)
  return(tile_names)
}

#' Download Potapov Forest Canopy Height data
#'
#' Downloads Global Forest Canopy Height data (Potapov et al., 2021) from GLAD.
#' Data represents forest height circa 2019 at 30m resolution.
#'
#' @param roi sf object, SpatVector, or NULL for global
#' @param output_folder Character, directory to save files (default: "data/POTAPOV_HEIGHT")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 1800)
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#' @importFrom rvest read_html html_nodes html_attr
#'
#' @keywords internal
download_potapov_height <- function(roi = NULL,
                                   output_folder = "data/POTAPOV_HEIGHT",
                                   n_cores = 1,
                                   timeout = 1800) {

  ensure_directory(output_folder)

  # Try multiple potential sources
  # Source 1: GLAD UMD server
  base_url <- "https://glad.umd.edu/dataset/gedi/"

  message("Fetching Potapov height tile list...")

  # For now, construct tile URLs based on known naming convention
  # Format: Forest_height_2019_PALSAR_ALOS_<tile>.tif
  # Since web scraping may not work, we'll construct URLs for required tiles

  if (!is.null(roi)) {
    tile_names <- potapov_tile_names(roi)
  } else {
    stop("Global download not implemented. Please specify an roi.")
  }

  # Construct file URLs
  # Note: The actual URL structure may vary - this is a placeholder
  # In practice, we may need to use a different source or API
  file_urls <- sprintf("https://glad.umd.edu/Potapov/GEDI_V27/Forest_height_2019_%s.tif",
                      tile_names)

  message(sprintf("Attempting to download %d Potapov height tile(s)...", length(tile_names)))

  download_single <- function(i) {
    file_url <- file_urls[i]
    tile_name <- tile_names[i]
    local_path <- file.path(output_folder, sprintf("Forest_height_2019_%s.tif", tile_name))

    # Skip if exists
    if (file.exists(local_path)) {
      message(sprintf("File %s already exists - skipping", basename(local_path)))
      return(local_path)
    }

    # Try to download
    success <- download_with_retry(file_url, local_path, timeout = timeout, quiet = FALSE)

    if (success) {
      return(local_path)
    } else {
      warning(sprintf("Failed to download tile %s from %s", tile_name, file_url))
      return(NULL)
    }
  }

  # Download files
  if (n_cores > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single, cl = cl)
  } else {
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single)
  }

  downloaded_files <- unlist(downloaded_files)
  downloaded_files <- downloaded_files[!sapply(downloaded_files, is.null)]

  if (length(downloaded_files) == 0) {
    stop("Failed to download any Potapov height tiles. The data source may have changed. ",
         "Please check https://glad.umd.edu for current data availability.")
  }

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process Potapov height tiles (crop, mosaic, aggregate)
#'
#' @param files Character vector of file paths to Potapov height tiles
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed raster
#'
#' @return SpatRaster object with forest height in meters
#'
#' @importFrom terra rast crop mosaic aggregate writeRaster
#'
#' @keywords internal
process_potapov_height <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Processing Potapov height tiles...")

  # Load tiles
  height_rasters <- lapply(files, function(f) {
    tryCatch({
      terra::rast(f)
    }, error = function(e) {
      warning(sprintf("Failed to read %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  height_rasters <- height_rasters[!sapply(height_rasters, is.null)]

  if (length(height_rasters) == 0) {
    stop("Failed to load any height rasters")
  }

  # Mosaic if multiple tiles
  if (length(height_rasters) == 1) {
    height <- height_rasters[[1]]
  } else {
    message("Mosaicking multiple tiles...")
    height <- do.call(terra::mosaic, height_rasters)
  }

  # Crop to extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  height <- terra::crop(height, extent_vect)

  # Aggregate from 30m to target resolution
  native_res <- 30  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating height by factor %d (30m -> %dm)",
                   agg_factor, target_res))

    # For very large aggregation factors, do it in steps to avoid memory issues
    if (agg_factor > 100) {
      message("Large aggregation factor detected, processing in steps...")
      step_factor <- 10
      while (agg_factor > 1) {
        current_factor <- min(step_factor, agg_factor)
        height <- terra::aggregate(height, fact = current_factor, fun = mean, na.rm = TRUE)
        agg_factor <- agg_factor / current_factor
      }
    } else {
      height <- terra::aggregate(height, fact = agg_factor, fun = mean, na.rm = TRUE)
    }
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    height_file <- file.path(outdir, sprintf("height_%s.tif", res_label))
    terra::writeRaster(height, height_file, overwrite = TRUE)
    message(sprintf("Saved height to %s", height_file))
  }

  return(height)
}

#' Fetch Global Forest Canopy Height (Potapov et al., 2021)
#'
#' Downloads and processes Global Forest Canopy Height data at 30m resolution
#' (circa 2019) and aggregates to target resolution.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, year parameter (currently only 2019 data available). Default: 2010
#'   Note: Data represents ~2019 conditions regardless of year parameter.
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/POTAPOV_HEIGHT"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return SpatRaster object with forest canopy height in meters
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch Potapov height data
#' height <- getPotapovHeight(bbox, resolution = "10km")
#' plot(height, main = "Forest Canopy Height (m)")
#' }
#'
#' @references
#' Potapov, P., Li, X., Hernandez-Serna, A., Tyukavina, A., Hansen, M. C.,
#' Kommareddy, A., ... & Hofton, M. (2021). Mapping global forest canopy height
#' through integration of GEDI and Landsat data. Remote Sensing of Environment, 253, 112165.
#' \doi{10.1016/j.rse.2020.112165}
getPotapovHeight <- function(extent,
                            year = 2010,
                            resolution = "10km",
                            outdir = NULL,
                            download = TRUE,
                            tiles_dir = "data/POTAPOV_HEIGHT",
                            n_cores = 1) {

  bbox <- validate_extent(extent)

  if (year != 2010 && year != 2019) {
    warning(sprintf("Potapov height data represents ~2019 conditions. Year %d will use 2019 data.", year))
  }

  # Get or download tiles
  if (download) {
    message("Downloading Potapov forest height data...")
    files <- download_potapov_height(
      roi = extent,
      output_folder = tiles_dir,
      n_cores = n_cores
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    tile_names <- potapov_tile_names(extent)
    files <- file.path(tiles_dir, sprintf("Forest_height_2019_%s.tif", tile_names))
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles
  message("Processing Potapov height tiles...")
  result <- process_potapov_height(files, extent, resolution, outdir)

  return(result)
}
