# SRTM Terrain Functions (DEM, Slope, Aspect)

#' Generate SRTM tile names for a region
#'
#' USGS MEASURES SRTM uses 1x1 degree tiles
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names in format "N00E000" or "S00W000"
#' @keywords internal
srtm_tile_names <- function(roi) {
  bbox <- validate_extent(roi)

  # USGS MEASURES SRTM uses 1x1 degree tiles
  # Tiles are named by their lower-left corner (e.g., N18W096 covers 18-19N, 96-97W)
  # Tiles are [start, start+1) - inclusive at lower bound, exclusive at upper bound

  # Calculate tile range
  lon_min <- floor(bbox[1])
  lat_min <- floor(bbox[2])

  # For max coordinates, use ceiling - 1 to get the tile containing the max point
  # This correctly handles boundary cases where max is exactly on a tile edge
  lon_max <- ceiling(bbox[3]) - 1
  lat_max <- ceiling(bbox[4]) - 1

  # Generate all tile coordinates
  lons <- seq(lon_min, lon_max, by = 1)
  lats <- seq(lat_min, lat_max, by = 1)

  tile_grid <- expand.grid(lon = lons, lat = lats)

  # Safety check: shouldn't need more than ~10000 tiles for reasonable extents
  if (nrow(tile_grid) > 10000) {
    warning(sprintf("SRTM tile calculation returned %d tiles for extent [%.2f, %.2f, %.2f, %.2f]. ",
                   nrow(tile_grid), bbox[1], bbox[2], bbox[3], bbox[4]),
            "This seems excessive. Please verify your extent is correct.")
  }

  tile_names <- character(nrow(tile_grid))

  for (i in 1:nrow(tile_grid)) {
    lon <- tile_grid$lon[i]
    lat <- tile_grid$lat[i]

    # USGS MEASURES naming: N/S + lat + E/W + lon (e.g., N18W096)
    lat_letter <- if (lat >= 0) "N" else "S"
    lon_letter <- if (lon >= 0) "E" else "W"

    tile_names[i] <- sprintf("%s%02d%s%03d",
                            lat_letter, abs(lat),
                            lon_letter, abs(lon))
  }

  return(unique(tile_names))
}

#' Download SRTM DEM tiles
#'
#' Downloads SRTM 90m (SRTMGL3 v003) tiles from USGS MEASURES server.
#'
#' @details
#' \strong{Authentication}: USGS MEASURES server requires NASA Earthdata authentication.
#'
#' \strong{Setup (recommended)}: Install earthdatalogin package and configure credentials:
#' \preformatted{
#' install.packages("earthdatalogin")
#' earthdatalogin::edl_netrc(username = "your_username", password = "your_password")
#' }
#' Register for free at: https://urs.earthdata.nasa.gov/users/new
#'
#' \strong{Alternative Sources}:
#' \itemize{
#' \item Manual Download: Download tiles from https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/
#' \item Google Earth Engine: Use \code{ee$Image("USGS/SRTMGL1_003")} if you have rgee configured
#' \item elevation package: R package with alternative SRTM access (install.packages("elevation"))
#' }
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

  # USGS MEASURES SRTM v3 (90m) base URL
  base_url <- "https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/"

  # Check if earthdatalogin is available for authentication
  has_earthdatalogin <- requireNamespace("earthdatalogin", quietly = TRUE)

  message(sprintf("Attempting to download %d SRTM DEM tile(s)...", length(tile_names)))

  if (has_earthdatalogin) {
    message("Using earthdatalogin for NASA Earthdata authentication")
  } else {
    message("Note: Install 'earthdatalogin' package for automatic authentication")
    message("  install.packages('earthdatalogin')")
    message("  earthdatalogin::edl_netrc(username, password)")
  }

  # Check which files already exist
  hgt_files <- file.path(output_folder, paste0(tile_names, ".hgt"))
  existing_files <- file.exists(hgt_files)

  if (any(existing_files)) {
    message(sprintf("%d file(s) already exist - skipping download", sum(existing_files)))
  }

  download_single <- function(i) {
    tile_name <- tile_names[i]
    file_url <- paste0(base_url, tile_name, ".SRTMGL3.hgt.zip")
    zip_file <- file.path(output_folder, paste0(tile_name, ".SRTMGL3.hgt.zip"))
    hgt_file <- hgt_files[i]

    # Skip if HGT already exists
    if (file.exists(hgt_file)) {
      return(hgt_file)
    }

    # Download zip using earthdatalogin if available, otherwise fall back
    success <- FALSE
    if (has_earthdatalogin) {
      tryCatch({
        earthdatalogin::edl_download(file_url, dest = zip_file)
        success <- file.exists(zip_file)
      }, error = function(e) {
        # Fall back to regular download
        success <- download_with_retry(file_url, zip_file, timeout = timeout, quiet = TRUE)
      })
    } else {
      success <- download_with_retry(file_url, zip_file, timeout = timeout, quiet = TRUE)
    }

    if (!success) {
      warning(sprintf("Failed to download %s", tile_name))
      return(NULL)
    }

    # Extract zip
    tryCatch({
      utils::unzip(zip_file, exdir = output_folder)
      unlink(zip_file)  # Remove zip after extraction

      if (file.exists(hgt_file)) {
        return(hgt_file)
      } else {
        warning(sprintf("Expected file %s not found after extraction", hgt_file))
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
    parallel::clusterExport(cl, c("tile_names", "hgt_files", "base_url", "output_folder",
     "timeout", "has_earthdatalogin"),
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
    if (has_earthdatalogin) {
      stop("Failed to download any SRTM tiles.\n\n",
           "Please configure earthdatalogin authentication:\n",
           "  earthdatalogin::edl_netrc(username = 'your_username', password = 'your_password')\n\n",
           "Register for free at: https://urs.earthdata.nasa.gov/users/new\n\n",
           "Required tiles: ", paste(tile_names, collapse=", "))
    } else {
      stop("Failed to download any SRTM tiles.\n\n",
           "The USGS MEASURES server requires NASA Earthdata authentication.\n\n",
           "Recommended: Install earthdatalogin package:\n",
           "  install.packages('earthdatalogin')\n",
           "  earthdatalogin::edl_netrc(username = 'your_username', password = 'your_password')\n",
           "  Register at: https://urs.earthdata.nasa.gov/users/new\n\n",
           "Alternatives:\n",
           "1. Manual Download: Download tiles from https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/\n",
           "   Required tiles: ", paste(tile_names, collapse=", "), "\n",
           "2. Use elevation package: install.packages('elevation')\n",
           "3. Use Google Earth Engine (if configured): ee$Image('USGS/SRTMGL1_003')")
    }
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

  # Define target extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])

  # Load and crop tiles BEFORE mosaicking (much faster!)
  dem_rasters <- lapply(files, function(f) {
    tryCatch({
      r <- terra::rast(f)
      # Crop immediately to reduce data volume
      terra::crop(r, extent_vect)
    }, error = function(e) {
      warning(sprintf("Failed to process %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  dem_rasters <- dem_rasters[!sapply(dem_rasters, is.null)]

  if (length(dem_rasters) == 0) {
    stop("Failed to load any DEM rasters")
  }

  # Mosaic if multiple tiles (now much smaller!)
  if (length(dem_rasters) == 1) {
    dem <- dem_rasters[[1]]
  } else {
    message(sprintf("Mosaicking %d cropped DEM tiles...", length(dem_rasters)))
    dem <- do.call(terra::mosaic, dem_rasters)
  }

  # Final crop to exact extent
  dem <- terra::crop(dem, extent_vect)

  # Compute terrain derivatives BEFORE aggregation for accuracy
  message("Computing terrain metrics...")
  slope <- terra::terrain(dem, v = "slope", unit = "degrees")
  aspect <- terra::terrain(dem, v = "aspect", unit = "degrees")
  tri <- terra::terrain(dem, v = "TRI")      # Terrain Ruggedness Index
  tpi <- terra::terrain(dem, v = "TPI")      # Topographic Position Index
  roughness <- terra::terrain(dem, v = "roughness")

  # Aggregate to target resolution
  # SRTM native resolution is ~90m
  native_res <- 90  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating terrain by factor %d (90m -> %dm)",
                   agg_factor, target_res))

    # Aggregate elevation using mean
    dem <- aggregate_raster(dem, agg_factor, circular = FALSE, fun = "mean")

    # Aggregate slope using standard mean
    slope <- aggregate_raster(slope, agg_factor, circular = FALSE, fun = "mean")

    # Aggregate aspect using circular mean (special handling)
    aspect <- aggregate_raster(aspect, agg_factor, circular = TRUE)

    # Aggregate TRI, TPI, roughness using mean
    tri <- aggregate_raster(tri, agg_factor, circular = FALSE, fun = "mean")
    tpi <- aggregate_raster(tpi, agg_factor, circular = FALSE, fun = "mean")
    roughness <- aggregate_raster(roughness, agg_factor, circular = FALSE, fun = "mean")
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))

    terra::writeRaster(dem, file.path(outdir, sprintf("elevation_%s.tif", res_label)), overwrite = TRUE)
    terra::writeRaster(slope, file.path(outdir, sprintf("slope_%s.tif", res_label)), overwrite = TRUE)
    terra::writeRaster(aspect, file.path(outdir, sprintf("aspect_%s.tif", res_label)), overwrite = TRUE)
    terra::writeRaster(tri, file.path(outdir, sprintf("tri_%s.tif", res_label)), overwrite = TRUE)
    terra::writeRaster(tpi, file.path(outdir, sprintf("tpi_%s.tif", res_label)), overwrite = TRUE)
    terra::writeRaster(roughness, file.path(outdir, sprintf("roughness_%s.tif", res_label)), overwrite = TRUE)
    message(sprintf("Saved terrain metrics to %s", outdir))
  }

  return(list(
    elevation = dem,
    slope = slope,
    aspect = aspect,
    tri = tri,
    tpi = tpi,
    roughness = roughness
  ))
}

#' Fetch SRTM Terrain
#'
#' Downloads SRTM DEM data and computes terrain derivatives such as slope, aspect,
#' Terrain Ruggedness Index (TRI), Topographic Position Index (TPI) and roughness
#' at the target resolution.
#'
#' @details
#' \strong{Data Source}: USGS MEASURES SRTMGL3 v003 (90m resolution, 1°×1° tiles)
#'
#' \strong{Authentication Required}: NASA Earthdata account (free)
#'
#' \strong{Setup (one-time)}:
#' \preformatted{
#' # 1. Register at https://urs.earthdata.nasa.gov/users/new
#' # 2. Install earthdatalogin package
#' install.packages("earthdatalogin")
#'
#' # 3. Configure credentials
#' earthdatalogin::edl_netrc(
#'   username = "your_username",
#'   password = "your_password"
#' )
#' }
#'
#' \strong{Alternative Sources}:
#' \itemize{
#' \item elevation package: \code{install.packages("elevation")}
#' \item Google Earth Engine: \code{ee$Image("USGS/SRTMGL1_003")} (requires rgee)
#' \item Manual download: https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/
#' }
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
#' @return Named list with six SpatRaster objects:
#' \describe{
#' \item{elevation}{Elevation in meters above sea level}
#' \item{slope}{Slope in degrees (0-90)}
#' \item{aspect}{Aspect in degrees (0-360), where 0=North, 90=East, 180=South, 270=West}
#' \item{tri}{Terrain Ruggedness Index - mean elevation difference between adjacent cells}
#' \item{tpi}{Topographic Position Index - difference from mean elevation of surrounding cells}
#' \item{roughness}{Roughness - difference between max and min elevation in 3x3 neighborhood}
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # One-time setup (required)
#' install.packages("earthdatalogin")
#' earthdatalogin::edl_netrc(username = "your_username", password = "your_password")
#'
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch terrain data
#' terrain <- getSRTMTerrain(bbox, resolution = "10km")
#'
#' # Plot individual metrics
#' plot(terrain$elevation, main = "Elevation (m)")
#' plot(terrain$slope, main = "Slope (degrees)")
#' plot(terrain$aspect, main = "Aspect (degrees)")
#' plot(terrain$tri, main = "Terrain Ruggedness Index")
#' plot(terrain$tpi, main = "Topographic Position Index")
#' plot(terrain$roughness, main = "Roughness")
#' }
#'
#' @references
#' NASA JPL (2013). NASA Shuttle Radar Topography Mission Global 3 arc second [Data set].
#' NASA EOSDIS Land Processes DAAC. \doi{10.5067/MEaSUREs/SRTM/SRTMGL3.003}
#'
#' Farr, T. G., Rosen, P. A., Caro, E., Crippen, R., Duren, R., Hensley, S., ...
#' & Alsdorf, D. (2007). The shuttle radar topography mission. Reviews of Geophysics, 45(2).
#' \doi{10.1029/2005RG000183}
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
    files <- file.path(tiles_dir, paste0(tile_names, ".hgt"))
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
