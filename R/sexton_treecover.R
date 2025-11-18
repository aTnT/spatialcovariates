# Sexton Tree Cover Functions

#' Generate Sexton tree cover tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#'
#' @return Character vector of tile names in format "N00W060"
#' @keywords internal
sexton_tile_names <- function(roi) {
  bbox <- validate_extent(roi)

  # Sexton uses 10x10 degree tiles
  crds <- expand.grid(
    x = c(bbox[1], bbox[3]),
    y = c(bbox[2], bbox[4])
  )

  tile_names <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    lon <- 10 * (crds$x[i] %/% 10)
    lat <- 10 * (crds$y[i] %/% 10)

    # Sexton naming: N/S for latitude, E/W for longitude
    lat_letter <- ifelse(lat >= 0, "N", "S")
    lon_letter <- ifelse(lon >= 0, "E", "W")

    lat_str <- sprintf("%02d", abs(lat))
    lon_str <- sprintf("%03d", abs(lon))

    tile_names[i] <- paste0(lat_letter, lat_str, lon_letter, lon_str)
  }

  return(unique(tile_names))
}

#' Download Sexton Tree Cover data from UMD GLCF
#'
#' Downloads Global Tree Canopy Cover data (Sexton et al., 2015) representing
#' 2015 conditions at 30m resolution.
#'
#' @param roi sf object, SpatVector, or NULL
#' @param output_folder Character, directory to save files (default: "data/SEXTON_TCC")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 1800)
#' @param year Numeric, year to download (2010 or 2015, default: 2015)
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#' @importFrom rvest read_html html_nodes html_attr
#'
#' @keywords internal
download_sexton_treecover <- function(roi = NULL,
                                     output_folder = "data/SEXTON_TCC",
                                     n_cores = 1,
                                     timeout = 1800,
                                     year = 2015) {

  ensure_directory(output_folder)

  if (!year %in% c(2010, 2015)) {
    warning("Sexton tree cover is available for 2010 and 2015. Using 2015.")
    year <- 2015
  }

  # Base URL for Sexton tree cover data
  # Note: This URL may change - verify at https://glad.umd.edu
  if (year == 2015) {
    base_url <- "ftp://ftp.glcf.umd.edu/glcf/Global_TreeCover/v3/2015/"
  } else {
    base_url <- "ftp://ftp.glcf.umd.edu/glcf/Global_TreeCover/v3/2010/"
  }

  if (!is.null(roi)) {
    tile_names <- sexton_tile_names(roi)
  } else {
    stop("Global download not implemented. Please specify an roi.")
  }

  # Construct file URLs
  # Format: Percent_Tree_Cover_N00W060.tif
  file_urls <- sprintf("%sPercent_Tree_Cover_%s.tif", base_url, tile_names)

  message(sprintf("Attempting to download %d Sexton tree cover tile(s) for year %d...",
                 length(tile_names), year))

  download_single <- function(i) {
    file_url <- file_urls[i]
    tile_name <- tile_names[i]
    local_path <- file.path(output_folder, sprintf("Percent_Tree_Cover_%d_%s.tif", year, tile_name))

    # Skip if exists
    if (file.exists(local_path)) {
      message(sprintf("File %s already exists - skipping", basename(local_path)))
      return(local_path)
    }

    # FTP download may require different method
    success <- tryCatch({
      download.file(file_url, local_path, mode = "wb", quiet = FALSE, method = "auto")
      TRUE
    }, error = function(e) {
      warning(sprintf("Failed to download %s: %s", file_url, e$message))
      FALSE
    })

    if (success && file.exists(local_path)) {
      return(local_path)
    } else {
      return(NULL)
    }
  }

  # Download files
  if (n_cores > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Export internal functions to cluster workers
    parallel::clusterExport(cl, "download_with_retry",
                          envir = asNamespace("spatialcovariates"))
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single, cl = cl)
  } else {
    downloaded_files <- pbapply::pblapply(seq_along(tile_names), download_single)
  }

  downloaded_files <- unlist(downloaded_files)
  downloaded_files <- downloaded_files[!sapply(downloaded_files, is.null)]

  if (length(downloaded_files) == 0) {
    stop("Failed to download any Sexton tree cover tiles. ",
         "The FTP server may be unavailable. ",
         "Please check ftp://ftp.glcf.umd.edu/glcf/Global_TreeCover/ for availability.")
  }

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process Sexton tree cover tiles (crop, mosaic, aggregate)
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
process_sexton_treecover <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Processing Sexton tree cover tiles...")

  # Load tiles
  treecover_rasters <- lapply(files, function(f) {
    tryCatch({
      terra::rast(f)
    }, error = function(e) {
      warning(sprintf("Failed to read %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  treecover_rasters <- treecover_rasters[!sapply(treecover_rasters, is.null)]

  if (length(treecover_rasters) == 0) {
    stop("Failed to load any tree cover rasters")
  }

  # Mosaic if multiple tiles
  if (length(treecover_rasters) == 1) {
    treecover <- treecover_rasters[[1]]
  } else {
    message("Mosaicking multiple tiles...")
    treecover <- do.call(terra::mosaic, treecover_rasters)
  }

  # Crop to extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  treecover <- terra::crop(treecover, extent_vect)

  # Aggregate from 30m to target resolution
  native_res <- 30  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating tree cover by factor %d (30m -> %dm)",
                   agg_factor, target_res))

    # For very large aggregation factors, process in steps
    if (agg_factor > 100) {
      message("Large aggregation factor detected, processing in steps...")
      step_factor <- 10
      while (agg_factor > 1) {
        current_factor <- min(step_factor, agg_factor)
        treecover <- terra::aggregate(treecover, fact = current_factor, fun = mean, na.rm = TRUE)
        agg_factor <- agg_factor / current_factor
      }
    } else {
      treecover <- terra::aggregate(treecover, fact = agg_factor, fun = mean, na.rm = TRUE)
    }
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    year <- stringr::str_extract(basename(files[1]), "\\d{4}")
    if (is.na(year)) year <- "2015"
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    tc_file <- file.path(outdir, sprintf("TC_Sexton_%s_%s.tif", year, res_label))
    terra::writeRaster(treecover, tc_file, overwrite = TRUE)
    message(sprintf("Saved tree cover to %s", tc_file))
  }

  return(treecover)
}

#' Fetch Global Tree Canopy Cover (Sexton et al., 2015)
#'
#' Downloads and processes Global Tree Canopy Cover data at 30m resolution
#' (2015 or 2010) and aggregates to target resolution.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, year to fetch (2010 or 2015). Default: 2015
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/SEXTON_TCC"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return SpatRaster object with percent tree cover (0-100)
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch tree cover data
#' treecover <- getSextonTreeCover(bbox, year = 2015, resolution = "10km")
#' plot(treecover, main = "Tree Cover (%)")
#' }
#'
#' @references
#' Sexton, J. O., Song, X. P., Feng, M., Noojipady, P., Anand, A., Huang, C., ...
#' & Townshend, J. R. (2013). Global, 30-m resolution continuous fields of tree
#' cover: Landsat-based rescaling of MODIS vegetation continuous fields with
#' lidar-based estimates of error. International Journal of Digital Earth, 6(5), 427-448.
#' \doi{10.1080/17538947.2013.786146}
getSextonTreeCover <- function(extent,
                              year = 2015,
                              resolution = "10km",
                              outdir = NULL,
                              download = TRUE,
                              tiles_dir = "data/SEXTON_TCC",
                              n_cores = 1) {

  bbox <- validate_extent(extent)

  if (!year %in% c(2010, 2015)) {
    warning("Sexton tree cover is available for 2010 and 2015. Using 2015.")
    year <- 2015
  }

  # Get or download tiles
  if (download) {
    message(sprintf("Downloading Sexton tree cover data for year %d...", year))
    files <- download_sexton_treecover(
      roi = extent,
      output_folder = tiles_dir,
      n_cores = n_cores,
      year = year
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    tile_names <- sexton_tile_names(extent)
    files <- file.path(tiles_dir, sprintf("Percent_Tree_Cover_%d_%s.tif", year, tile_names))
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles
  message("Processing tree cover tiles...")
  result <- process_sexton_treecover(files, extent, resolution, outdir)

  return(result)
}
