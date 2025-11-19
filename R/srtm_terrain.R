# SRTM Terrain Functions (DEM, Slope, Aspect)

#' Generate SRTM tile names for a region
#'
#' SRTM uses 5x5 degree tiles
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names in format "srtm_XX_YY"
#' @keywords internal
srtm_tile_names <- function(roi) {
  bbox <- validate_extent(roi)

  # SRTM uses 5x5 degree tiles
  # Need to include tiles that overlap the bbox, not just floor of max values
  lon_min <- floor(bbox[1] / 5) * 5
  lon_max <- floor(bbox[3] / 5) * 5
  # If max longitude is not on tile boundary, we need the next tile
  if (bbox[3] > lon_max && bbox[3] <= lon_max + 5) lon_max <- lon_max + 0  # Already have it

  lat_min <- floor(bbox[2] / 5) * 5
  lat_max <- floor(bbox[4] / 5) * 5
  # If max latitude extends beyond the tile, need the next tile
  if (bbox[4] > lat_max) lat_max <- lat_max + 5

  lons <- seq(lon_min, lon_max, by = 5)
  lats <- seq(lat_min, lat_max, by = 5)

  tile_grid <- expand.grid(lon = lons, lat = lats)

  tile_names <- character(nrow(tile_grid))

  for (i in 1:nrow(tile_grid)) {
    lon <- tile_grid$lon[i]
    lat <- tile_grid$lat[i]

    # SRTM tile naming: srtm_XX_YY where XX and YY are tile indices
    # Longitude: -180 to 180, divided by 5, offset by 36 (so -180 = 01, 0 = 37)
    # Latitude: -60 to 60, divided by 5, offset by 13 (so -60 = 01, 0 = 13)
    lon_idx <- (lon / 5) + 37
    lat_idx <- 13 - (lat / 5)

    tile_names[i] <- sprintf("srtm_%02d_%02d", lon_idx, lat_idx)
  }

  return(unique(tile_names))
}

#' Download SRTM DEM tiles
#'
#' Downloads SRTM Version 4.1 tiles from CGIAR-CSI or OpenTopography.
#'
#' @param roi sf object, SpatVector, or NULL
#' @param output_folder Character, directory to save files (default: "data/SRTM")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 600)
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#'
#' @keywords internal
download_srtm_dem <- function(roi = NULL,
                             output_folder = "data/SRTM",
                             n_cores = 1,
                             timeout = 600) {

  ensure_directory(output_folder)

  if (is.null(roi)) {
    stop("Global download not implemented. Please specify an roi.")
  }

  tile_names <- srtm_tile_names(roi)

  # CGIAR-CSI SRTM v4.1 base URL
  base_url <- "https://srtm.csi.cgiar.org/wp-content/uploads/files/srtm_5x5/TIFF/"

  message(sprintf("Attempting to download %d SRTM DEM tile(s)...", length(tile_names)))

  # Check which files already exist
  tif_files <- file.path(output_folder, paste0(tile_names, ".tif"))
  existing_files <- file.exists(tif_files)

  if (any(existing_files)) {
    message(sprintf("%d file(s) already exist - skipping download", sum(existing_files)))
  }

  download_single <- function(i) {
    tile_name <- tile_names[i]
    file_url <- paste0(base_url, tile_name, ".zip")
    zip_file <- file.path(output_folder, paste0(tile_name, ".zip"))
    tif_file <- tif_files[i]

    # Skip if TIF already exists (checked earlier, but double-check)
    if (file.exists(tif_file)) {
      return(tif_file)
    }

    # Download zip
    success <- download_with_retry(file_url, zip_file, timeout = timeout, quiet = TRUE)

    if (!success) {
      warning(sprintf("Failed to download %s", tile_name))
      return(NULL)
    }

    # Extract zip
    tryCatch({
      utils::unzip(zip_file, exdir = output_folder)
      unlink(zip_file)  # Remove zip after extraction

      if (file.exists(tif_file)) {
        return(tif_file)
      } else {
        warning(sprintf("Expected file %s not found after extraction", tif_file))
        return(NULL)
      }
    }, error = function(e) {
      warning(sprintf("Failed to extract %s: %s", zip_file, e$message))
      return(NULL)
    })
  }

  # Download files
  if (n_cores > 1 && sum(!existing_files) > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Export variables to cluster workers
    parallel::clusterExport(cl, c("tile_names", "tif_files", "base_url", "output_folder", "timeout"),
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
    stop("Failed to download any SRTM tiles. ",
         "The server may be unavailable. ",
         "Please check https://srtm.csi.cgiar.org for availability.")
  }

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process SRTM DEM tiles and compute terrain derivatives
#'
#' @param files Character vector of file paths to SRTM DEM tiles
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed rasters
#'
#' @return Named list with SpatRaster objects: slope (degrees) and aspect (degrees)
#'
#' @importFrom terra rast crop mosaic aggregate terrain writeRaster
#'
#' @keywords internal
process_srtm_terrain <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Processing SRTM DEM tiles...")

  # Load tiles
  dem_rasters <- lapply(files, function(f) {
    tryCatch({
      terra::rast(f)
    }, error = function(e) {
      warning(sprintf("Failed to read %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  dem_rasters <- dem_rasters[!sapply(dem_rasters, is.null)]

  if (length(dem_rasters) == 0) {
    stop("Failed to load any DEM rasters")
  }

  # Mosaic if multiple tiles
  if (length(dem_rasters) == 1) {
    dem <- dem_rasters[[1]]
  } else {
    message("Mosaicking multiple DEM tiles...")
    dem <- do.call(terra::mosaic, dem_rasters)
  }

  # Crop to extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  tryCatch({
    dem <- terra::crop(dem, extent_vect)
  }, error = function(e) {
    stop(sprintf("Failed to crop DEM to extent [%s]. DEM extent: [%s]. Error: %s",
                paste(bbox, collapse=", "),
                paste(as.vector(terra::ext(dem)), collapse=", "),
                e$message))
  })

  # Compute terrain derivatives BEFORE aggregation for accuracy
  message("Computing slope and aspect...")
  slope <- terra::terrain(dem, v = "slope", unit = "degrees")
  aspect <- terra::terrain(dem, v = "aspect", unit = "degrees")

  # Aggregate to target resolution
  # SRTM native resolution is ~90m
  native_res <- 90  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating terrain by factor %d (90m -> %dm)",
                   agg_factor, target_res))

    # Aggregate slope using standard mean
    slope <- aggregate_raster(slope, agg_factor, circular = FALSE, fun = "mean")

    # Aggregate aspect using circular mean (special handling)
    aspect <- aggregate_raster(aspect, agg_factor, circular = TRUE)
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))

    slope_file <- file.path(outdir, sprintf("slope_%s.tif", res_label))
    terra::writeRaster(slope, slope_file, overwrite = TRUE)
    message(sprintf("Saved slope to %s", slope_file))

    aspect_file <- file.path(outdir, sprintf("aspect_%s.tif", res_label))
    terra::writeRaster(aspect, aspect_file, overwrite = TRUE)
    message(sprintf("Saved aspect to %s", aspect_file))
  }

  return(list(slope = slope, aspect = aspect))
}

#' Fetch SRTM Terrain (Slope and Aspect)
#'
#' Downloads SRTM DEM data and computes terrain derivatives (slope and aspect)
#' at the target resolution. Slope is computed as the maximum rate of change
#' in elevation. Aspect is the compass direction of the slope (0-360 degrees).
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed rasters. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/SRTM"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return Named list with two SpatRaster objects:
#'   \describe{
#'     \item{slope}{Slope in degrees (0-90)}
#'     \item{aspect}{Aspect in degrees (0-360), where 0=North, 90=East, 180=South, 270=West}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch terrain data
#' terrain <- getSRTMTerrain(bbox, resolution = "10km")
#' plot(terrain$slope, main = "Slope (degrees)")
#' plot(terrain$aspect, main = "Aspect (degrees)")
#' }
#'
#' @references
#' Farr, T. G., Rosen, P. A., Caro, E., Crippen, R., Duren, R., Hensley, S., ...
#' & Alsdorf, D. (2007). The shuttle radar topography mission. Reviews of Geophysics, 45(2).
#' \doi{10.1029/2005RG000183}
#'
#' Jarvis, A., Reuter, H. I., Nelson, A., & Guevara, E. (2008). Hole-filled SRTM for the
#' globe Version 4. Available from the CGIAR-CSI SRTM 90m Database.
getSRTMTerrain <- function(extent,
                          resolution = "10km",
                          outdir = NULL,
                          download = TRUE,
                          tiles_dir = "data/SRTM",
                          n_cores = 1) {

  bbox <- validate_extent(extent)

  # Get or download tiles
  if (download) {
    message("Downloading SRTM DEM data...")
    files <- download_srtm_dem(
      roi = extent,
      output_folder = tiles_dir,
      n_cores = n_cores
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    tile_names <- srtm_tile_names(extent)
    files <- file.path(tiles_dir, paste0(tile_names, ".tif"))
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles and compute terrain
  message("Processing SRTM terrain...")
  result <- process_srtm_terrain(files, extent, resolution, outdir)

  return(result)
}
