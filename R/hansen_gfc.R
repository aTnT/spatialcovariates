# Hansen Global Forest Change Tree Cover 2000 Functions
# Hansen GFC provides 30m resolution tree cover for year 2000 baseline
# Data is hosted on Google Cloud Storage and uses 10x10 degree tiles

#' Generate Hansen GFC tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names in format "10N_080W"
#' @keywords internal
hansen_tile_names <- function(roi) {
  bbox <- validate_extent(roi)

  # Hansen uses 10x10 degree tiles named by top-left corner
  # Generate all 10-degree tile boundaries that cover the bbox
  lon_seq <- seq(floor(bbox[1]/10)*10, ceiling(bbox[3]/10)*10, by=10)
  lat_seq <- seq(floor(bbox[2]/10)*10, ceiling(bbox[4]/10)*10, by=10)

  crds <- expand.grid(
    x = lon_seq,
    y = lat_seq
  )

  tile_names <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    # Western (left) edge of tile
    lon <- 10 * (crds$x[i] %/% 10)
    # Southern (bottom) edge of tile
    lat <- 10 * (crds$y[i] %/% 10)

    # Hansen tiles are named by top-left corner (north edge, west edge)
    north_lat <- lat + 10  # Top of the tile

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

#' Download Hansen Global Forest Change tree cover data
#'
#' Downloads Global Forest Change tree cover data (Hansen et al., 2013) representing
#' year 2000 conditions at 30m resolution from Google Cloud Storage.
#'
#' @param roi sf object, SpatVector, or NULL
#' @param output_folder Character, directory to save files (default: "data/HANSEN_TC")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 1800)
#' @param version Character, GFC version to download (default: "GFC-2023-v1.11")
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#' @importFrom httr GET write_disk progress
#'
#' @keywords internal
download_hansen_treecover <- function(roi = NULL,
                                     output_folder = "data/HANSEN_TC",
                                     n_cores = 1,
                                     timeout = 1800,
                                     version = "GFC-2023-v1.11") {

  ensure_directory(output_folder)

  if (!is.null(roi)) {
    tile_names <- hansen_tile_names(roi)
  } else {
    stop("Global download not implemented. Please specify an roi.")
  }

  # Base URL for Hansen GFC data on Google Cloud Storage
  base_url <- sprintf("https://storage.googleapis.com/earthenginepartners-hansen/%s", version)

  # Construct file URLs
  # Format: Hansen_GFC-2023-v1.11_treecover2000_10N_080W.tif
  file_urls <- sprintf("%s/Hansen_%s_treecover2000_%s.tif", base_url, version, tile_names)

  message(sprintf("Attempting to download %d Hansen GFC tree cover tile(s)...",
                 length(tile_names)))

  # Check which files already exist
  local_paths <- file.path(output_folder, sprintf("Hansen_treecover2000_%s.tif", tile_names))
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

    # Download using httr for better error handling
    success <- tryCatch({
      response <- httr::GET(
        file_url,
        httr::write_disk(local_path, overwrite = TRUE),
        httr::progress(),
        httr::timeout(timeout)
      )

      if (httr::status_code(response) == 200) {
        TRUE
      } else {
        if (file.exists(local_path)) file.remove(local_path)
        FALSE
      }
    }, error = function(e) {
      if (file.exists(local_path)) file.remove(local_path)
      FALSE
    })

    if (success && file.exists(local_path)) {
      return(local_path)
    } else {
      return(NULL)
    }
  }

  # Download files
  if (n_cores > 1 && sum(!existing_files) > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Export variables to cluster workers
    parallel::clusterExport(cl, c("file_urls", "tile_names", "local_paths", "timeout"),
                          envir = environment())
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single, cl = cl)
  } else {
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single)
  }

  downloaded_files <- unlist(downloaded_files)
  downloaded_files <- downloaded_files[!sapply(downloaded_files, is.null)]

  if (length(downloaded_files) == 0) {
    stop("Failed to download any Hansen GFC tree cover tiles. ",
         "Please check your internet connection and try again.")
  }

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process Hansen tree cover tiles (crop, mosaic, aggregate)
#'
#' @param files Character vector of file paths to tree cover tiles
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed raster
#'
#' @return SpatRaster object with percent tree cover (0-100)
#'
#' @importFrom terra rast crop mosaic aggregate writeRaster
#'
#' @keywords internal
process_hansen_treecover <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Processing Hansen GFC tree cover tiles...")

  # Define target extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])

  # Calculate aggregation factor
  native_res <- 30  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  # Load, crop, and aggregate tiles BEFORE mosaicking (much faster!)
  treecover_rasters <- lapply(files, function(f) {
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
  treecover_rasters <- treecover_rasters[!sapply(treecover_rasters, is.null)]

  if (length(treecover_rasters) == 0) {
    stop("Failed to load any tree cover rasters")
  }

  # Mosaic if multiple tiles (now much smaller/faster!)
  if (length(treecover_rasters) == 1) {
    treecover <- treecover_rasters[[1]]
  } else {
    message(sprintf("Mosaicking %d aggregated tiles...", length(treecover_rasters)))
    treecover <- do.call(terra::mosaic, treecover_rasters)
  }

  # Final crop to exact extent (in case mosaic extended bounds)
  treecover <- terra::crop(treecover, extent_vect)

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    tc_file <- file.path(outdir, sprintf("TC_Hansen2000_%s.tif", res_label))
    terra::writeRaster(treecover, tc_file, overwrite = TRUE)
    message(sprintf("Saved tree cover to %s", tc_file))
  }

  return(treecover)
}

#' Fetch Hansen Global Forest Change Tree Cover 2000
#'
#' Downloads and processes Hansen Global Forest Change tree cover data at 30m resolution
#' (year 2000 baseline) and aggregates to target resolution.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, year parameter (deprecated - Hansen GFC uses year 2000 baseline).
#'   Included for backward compatibility. Default: 2000
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/HANSEN_TC"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return SpatRaster object with percent tree cover (0-100) for year 2000
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch Hansen GFC tree cover data
#' treecover <- getHansenGFC(bbox, resolution = "10km")
#' plot(treecover, main = "Tree Cover 2000 (%)")
#' }
#'
#' @references
#' Hansen, M. C., Potapov, P. V., Moore, R., Hancher, M., Turubanova, S. A.,
#' Tyukavina, A., ... & Townshend, J. R. G. (2013). High-resolution global maps
#' of 21st-century forest cover change. Science, 342(6160), 850-853.
#' \doi{10.1126/science.1244693}
getHansenGFC <- function(extent,
                              year = 2000,
                              resolution = "10km",
                              outdir = NULL,
                              download = TRUE,
                              tiles_dir = "data/HANSEN_TC",
                              n_cores = 1) {

  bbox <- validate_extent(extent)

  # Warn if user tries to use year other than 2000
  if (!missing(year) && year != 2000) {
    warning("Hansen GFC tree cover uses year 2000 baseline. ",
            "The 'year' parameter is ignored. ",
            "For forest change over time, use the loss/gain layers (future enhancement).")
  }

  # Get or download tiles
  if (download) {
    message("Downloading Hansen GFC tree cover data (year 2000 baseline)...")
    files <- download_hansen_treecover(
      roi = extent,
      output_folder = tiles_dir,
      n_cores = n_cores
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    tile_names <- hansen_tile_names(extent)
    files <- file.path(tiles_dir, sprintf("Hansen_treecover2000_%s.tif", tile_names))
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles
  message("Processing tree cover tiles...")
  result <- process_hansen_treecover(files, extent, resolution, outdir)

  return(result)
}
