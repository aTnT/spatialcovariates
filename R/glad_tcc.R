# GLAD Tree Canopy Cover 2010 Functions
# GLAD TCC 2010 provides 30m resolution tree canopy cover for year 2010
# Uses 10x10 degree tile system (same as Hansen GFC)

#' Generate GLAD TCC 2010 tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names in format "20N_110W"
#' @keywords internal
glad_tcc_tile_names <- function(roi) {
  bbox <- validate_extent(roi)

  # GLAD TCC 2010 uses same 10x10 degree tile system as Hansen GFC
  # Tiles are named by top-left corner
  crds <- expand.grid(
    x = c(bbox[1], bbox[3]),
    y = c(bbox[2], bbox[4])
  )

  tile_names <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    # Western edge of tile
    lon <- 10 * (crds$x[i] %/% 10)
    # Southern edge of tile
    lat <- 10 * (crds$y[i] %/% 10)

    # Tiles named by top-left corner (northern edge + 10, western edge)
    north_lat <- lat + 10

    # Handle special case: equatorial tile (0 to -10) is named "00N"
    if (north_lat == 0) {
      lat_letter <- "N"
      lat_str <- "00"
    } else if (north_lat > 0) {
      lat_letter <- "N"
      lat_str <- sprintf("%02d", north_lat)
    } else {
      lat_letter <- "S"
      lat_str <- sprintf("%02d", abs(north_lat))
    }

    # Longitude uses western edge
    lon_letter <- ifelse(lon >= 0, "E", "W")
    lon_str <- sprintf("%03d", abs(lon))

    tile_names[i] <- paste0(lat_str, lat_letter, "_", lon_str, lon_letter)
  }

  return(unique(tile_names))
}

#' Download GLAD Tree Cover 2010 data
#'
#' Downloads GLAD Tree Cover 2010 data from University of Maryland GLAD lab.
#' Data represents tree canopy cover percentage (0-100) for year 2010 at 30m resolution.
#'
#' @param roi sf object, SpatVector, or NULL for global
#' @param output_folder Character, directory to save files (default: "data/GLAD_TCC_2010")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 1800)
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#'
#' @keywords internal
download_glad_tcc_2010 <- function(roi = NULL,
                                   output_folder = "data/GLAD_TCC_2010",
                                   n_cores = 1,
                                   timeout = 1800) {

  ensure_directory(output_folder)

  # GLAD TCC 2010 data
  # Source: https://glad.umd.edu/Potapov/TCC_2010/
  base_url <- "https://glad.umd.edu/Potapov/TCC_2010/"

  message("Fetching GLAD TCC 2010 tile list...")

  if (!is.null(roi)) {
    tile_names <- glad_tcc_tile_names(roi)
  } else {
    stop("Global download not implemented. Please specify an roi.")
  }

  # Construct file URLs
  # Format: treecover2010_20N_110W.tif
  file_urls <- sprintf("%streecover2010_%s.tif", base_url, tile_names)

  message(sprintf("Attempting to download %d GLAD TCC 2010 tile(s)...", length(tile_names)))

  # Check which files already exist
  local_paths <- file.path(output_folder, sprintf("treecover2010_%s.tif", tile_names))
  existing_files <- file.exists(local_paths)

  if (any(existing_files)) {
    message(sprintf("%d file(s) already exist - skipping download", sum(existing_files)))
  }

  download_single <- function(i) {
    file_url <- file_urls[i]
    tile_name <- tile_names[i]
    local_path <- local_paths[i]

    # Skip if exists (checked earlier, but double-check)
    if (file.exists(local_path)) {
      return(local_path)
    }

    # Try to download
    success <- download_with_retry(file_url, local_path, timeout = timeout, quiet = TRUE)

    if (success) {
      return(local_path)
    } else {
      return(NULL)
    }
  }

  # Download files
  if (n_cores > 1 && sum(!existing_files) > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Export internal functions to cluster workers
    parallel::clusterExport(cl, c("download_with_retry", "file_urls", "tile_names", "local_paths"),
                          envir = environment())
    parallel::clusterExport(cl, "download_with_retry",
                          envir = asNamespace("spatialcovariates"))
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single, cl = cl)
  } else {
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single)
  }

  downloaded_files <- unlist(downloaded_files)
  downloaded_files <- downloaded_files[!sapply(downloaded_files, is.null)]

  if (length(downloaded_files) == 0) {
    stop("Failed to download any GLAD TCC 2010 tiles. The data source may have changed. ",
         "Please check https://glad.umd.edu/Potapov/TCC_2010/ for current data availability.")
  }

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process GLAD TCC 2010 tiles (crop, mosaic, aggregate)
#'
#' @param files Character vector of file paths to GLAD TCC 2010 tiles
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed raster
#'
#' @return SpatRaster object with tree canopy cover percentage (0-100)
#'
#' @importFrom terra rast crop mosaic aggregate writeRaster
#'
#' @keywords internal
process_glad_tcc_2010 <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Processing GLAD TCC 2010 tiles...")

  # Define target extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])

  # Calculate aggregation factor
  native_res <- 30  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  # Load, crop, and aggregate tiles BEFORE mosaicking (much faster!)
  tcc_rasters <- lapply(files, function(f) {
    tryCatch({
      # Load tile
      r <- terra::rast(f)

      # Crop immediately to reduce data volume
      r <- terra::crop(r, extent_vect)

      # Aggregate immediately if needed (while data is small)
      if (agg_factor > 1) {
        r <- terra::aggregate(r, fact = agg_factor, fun = mean, na.rm = TRUE)
      }

      return(r)
    }, error = function(e) {
      warning(sprintf("Failed to process %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  tcc_rasters <- tcc_rasters[!sapply(tcc_rasters, is.null)]

  if (length(tcc_rasters) == 0) {
    stop("Failed to load any TCC rasters")
  }

  # Mosaic if multiple tiles (now much smaller/faster!)
  if (length(tcc_rasters) == 1) {
    tcc <- tcc_rasters[[1]]
  } else {
    message(sprintf("Mosaicking %d aggregated tiles...", length(tcc_rasters)))
    tcc <- do.call(terra::mosaic, tcc_rasters)
  }

  # Final crop to exact extent (in case mosaic extended bounds)
  tcc <- terra::crop(tcc, extent_vect)

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    tcc_file <- file.path(outdir, sprintf("tcc2010_%s.tif", res_label))
    terra::writeRaster(tcc, tcc_file, overwrite = TRUE)
    message(sprintf("Saved TCC 2010 to %s", tcc_file))
  }

  return(tcc)
}

#' Fetch GLAD Tree Cover 2010 data
#'
#' Downloads and processes GLAD Tree Cover 2010 data at 30m resolution
#' and aggregates to target resolution.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, year parameter (deprecated - data is for 2010). Default: 2010
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/GLAD_TCC_2010"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return SpatRaster object with tree canopy cover percentage (0-100) for year 2010
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch GLAD TCC 2010 data
#' tcc <- getGLADTCC2010(bbox, resolution = "10km")
#' plot(tcc, main = "Tree Canopy Cover 2010 (%)")
#' }
#'
#' @references
#' Potapov, P., et al. (2011). Quantifying forest cover loss in Democratic Republic of the Congo,
#' 2000-2010, with Landsat ETM+ data. Remote Sensing of Environment, 122, 106-116.
#'
#' @note For actual canopy height data, consider using Google Earth Engine with the
#' ETH Global Canopy Height 2020 product: \code{users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1}
getGLADTCC2010 <- function(extent,
                            year = 2010,
                            resolution = "10km",
                            outdir = NULL,
                            download = TRUE,
                            tiles_dir = "data/GLAD_TCC_2010",
                            n_cores = 1) {

  bbox <- validate_extent(extent)

  if (!missing(year) && year != 2010) {
    warning("GLAD TCC data is for year 2010. The 'year' parameter is ignored.")
  }

  # Get or download tiles
  if (download) {
    message("Downloading GLAD TCC 2010 data...")
    files <- download_glad_tcc_2010(
      roi = extent,
      output_folder = tiles_dir,
      n_cores = n_cores
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    tile_names <- glad_tcc_tile_names(extent)
    files <- file.path(tiles_dir, sprintf("treecover2010_%s.tif", tile_names))
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles
  message("Processing GLAD TCC 2010 tiles...")
  result <- process_glad_tcc_2010(files, extent, resolution, outdir)

  return(result)
}
