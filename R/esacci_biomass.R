# ESA CCI Biomass Functions
# Ported and adapted from Plot2Map package

#' Validate ESA CCI Biomass year and version arguments
#'
#' @param year Numeric or character, year to validate
#' @param version Character, version to validate
#'
#' @return List with validated year and version
#' @keywords internal
validate_esacci_args <- function(year, version) {
  valid_years <- c(2010, 2015:2022)
  valid_versions <- c("v2.0", "v3.0", "v4.0", "v5.0", "v5.01", "v6.0")

  # Handle "latest" keywords
  if (is.character(year) && year == "latest") {
    year <- 2022
  }
  if (is.character(version) && version == "latest") {
    version <- "v6.0"
  }

  year <- as.numeric(year)
  if (!year %in% valid_years) {
    stop(sprintf("Invalid year: %d. Valid years are: %s",
                year, paste(valid_years, collapse = ", ")))
  }

  if (!version %in% valid_versions) {
    stop(sprintf("Invalid version: %s. Valid versions are: %s",
                version, paste(valid_versions, collapse = ", ")))
  }

  # Version-specific year constraints
  if (version %in% c("v2.0", "v3.0")) {
    if (!year %in% c(2010, 2017, 2018)) {
      stop(sprintf("Version %s only supports years 2010, 2017, and 2018", version))
    }
  } else if (version == "v4.0") {
    if (!year %in% c(2010, 2017:2020)) {
      stop(sprintf("Version %s only supports years 2010, 2017-2020", version))
    }
  } else if (version %in% c("v5.0", "v5.01")) {
    if (!year %in% c(2010, 2017:2021)) {
      stop(sprintf("Version %s only supports years 2010, 2017-2021", version))
    }
  }

  return(list(year = year, version = version))
}

#' Generate ESA CCI AGB tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#' @param year Numeric, year
#' @param version Character, version string
#' @param type Character, either "agb" or "sd" for standard deviation
#'
#' @return Character vector of tile filenames
#' @keywords internal
esacci_tile_names <- function(roi, year, version, type = "agb") {
  bbox <- validate_extent(roi)

  # Expand bbox to corner coordinates
  crds <- expand.grid(
    x = c(bbox[1], bbox[3]),
    y = c(bbox[2], bbox[4])
  )

  tile_names <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    lon <- 10 * (crds$x[i] %/% 10)
    lat <- 10 * (crds$y[i] %/% 10) + 10

    # Format coordinates
    lon_letter <- ifelse(lon < 0, "W", "E")
    lat_letter <- ifelse(lat < 0, "S", "N")
    lon_str <- sprintf("%03d", abs(lon))
    lat_str <- sprintf("%02d", abs(lat))

    # Construct filename based on type
    # Note: CEDA uses 'fv' prefix for file version (e.g., fv3.0 not v3.0)
    file_version <- gsub("^v", "fv", version)
    if (type == "sd") {
      tile_names[i] <- sprintf("%s%s%s%s_ESACCI-BIOMASS-L4-AGB_SD-MERGED-100m-%d-%s.tif",
                              lat_letter, lat_str, lon_letter, lon_str, year, file_version)
    } else {
      tile_names[i] <- sprintf("%s%s%s%s_ESACCI-BIOMASS-L4-AGB-MERGED-100m-%d-%s.tif",
                              lat_letter, lat_str, lon_letter, lon_str, year, file_version)
    }
  }

  return(unique(tile_names))
}

#' Download ESA CCI Biomass data from CEDA Archive
#'
#' @param roi sf object, SpatVector, or NULL for all tiles
#' @param year Numeric or "latest", year to download (2010, 2015-2022)
#' @param version Character or "latest", version to download (v2.0-v6.0)
#' @param output_folder Character, directory to save files (default: "data/ESACCI-BIOMASS")
#' @param n_cores Integer, number of cores for parallel download (default: 1)
#' @param timeout Numeric, download timeout in seconds (default: 600)
#' @param file_names Character vector, optional specific filenames to download
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#' @importFrom parallel makeCluster stopCluster
#' @importFrom rvest read_html html_nodes html_attr
#' @importFrom httr GET content
#'
#' @keywords internal
download_esacci_biomass <- function(roi = NULL,
                                   year = 2010,
                                   version = "v3.0",
                                   output_folder = "data/ESACCI-BIOMASS",
                                   n_cores = 1,
                                   timeout = 600,
                                   file_names = NULL) {

  # Validate arguments
  validated <- validate_esacci_args(year, version)
  year <- validated$year
  version <- validated$version

  # Create output directory
  ensure_directory(output_folder)

  # Construct base URL
  # Format: https://data.ceda.ac.uk/neodc/esacci/biomass/data/agb/maps/v3.0/geotiff/2010/
  # Use version string as-is (Plot2Map approach)
  base_url <- sprintf("https://data.ceda.ac.uk/neodc/esacci/biomass/data/agb/maps/%s/geotiff/%d/",
                     version, year)

  # Fetch file listing from URL using html_table (Plot2Map method)
  message(sprintf("Fetching file list from %s", base_url))
  tryCatch({
    page <- rvest::read_html(base_url)
    file_table <- rvest::html_table(page, fill = TRUE)[[1]]
    available_files <- file_table$X1  # First column contains filenames
    # Filter for .tif files only
    available_files <- grep("\\.tif$", available_files, value = TRUE)
  }, error = function(e) {
    stop(sprintf("Failed to fetch file list from %s: %s", base_url, e$message))
  })

  if (length(available_files) == 0) {
    stop(sprintf("No .tif files found at %s", base_url))
  }

  # Filter files if specific names provided
  if (!is.null(file_names)) {
    available_files <- intersect(available_files, file_names)
  } else if (!is.null(roi)) {
    # Filter by ROI
    required_agb <- esacci_tile_names(roi, year, version, type = "agb")
    required_sd <- esacci_tile_names(roi, year, version, type = "sd")
    required_files <- c(basename(required_agb), basename(required_sd))
    available_files <- intersect(available_files, required_files)
  }

  # Remove auxiliary files (1000m resolution, etc.)
  available_files <- grep("1000m|aux", available_files, value = TRUE, invert = TRUE)

  if (length(available_files) == 0) {
    stop("No files to download after filtering")
  }

  message(sprintf("Downloading %d ESA CCI Biomass file(s)...", length(available_files)))

  # Download function for a single file
  download_single <- function(filename) {
    file_url <- paste0(base_url, filename)
    local_path <- file.path(output_folder, filename)

    # Skip if file exists and is verified
    if (file.exists(local_path)) {
      if (verify_download(file_url, local_path)) {
        return(local_path)
      } else {
        message(sprintf("File %s exists but failed verification, re-downloading", filename))
      }
    }

    # Download with retry
    success <- download_with_retry(file_url, local_path, timeout = timeout, quiet = TRUE)

    if (success) {
      return(local_path)
    } else {
      warning(sprintf("Failed to download %s", filename))
      return(NULL)
    }
  }

  # Parallel download
  if (n_cores > 1) {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    # Export internal functions from package namespace to cluster workers
    parallel::clusterExport(cl, c("download_with_retry", "verify_download"),
                          envir = asNamespace("spatialcovariates"))
    downloaded_files <- pbapply::pblapply(available_files, download_single, cl = cl)
  } else {
    downloaded_files <- pbapply::pblapply(available_files, download_single)
  }

  # Remove NULLs (failed downloads)
  downloaded_files <- unlist(downloaded_files)
  downloaded_files <- downloaded_files[!sapply(downloaded_files, is.null)]

  message(sprintf("Successfully downloaded %d file(s)", length(downloaded_files)))
  return(downloaded_files)
}

#' Process ESA CCI Biomass tiles (crop, mosaic, aggregate)
#'
#' @param files Character vector of file paths to ESA CCI tiles
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed rasters
#'
#' @return Named list with SpatRaster objects: agb and sd
#'
#' @importFrom terra rast crop mosaic aggregate writeRaster
#'
#' @keywords internal
process_esacci_biomass <- function(files, extent, resolution = "10km", outdir = NULL) {
  if (length(files) == 0) {
    stop("No files to process")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  # Separate AGB and SD files
  agb_files <- grep("AGB_SD", files, value = TRUE, invert = TRUE)
  sd_files <- grep("AGB_SD", files, value = TRUE)

  if (length(agb_files) == 0) {
    stop("No AGB files found in provided files")
  }

  message("Processing AGB tiles...")
  # Load and mosaic AGB tiles
  agb_rasters <- lapply(agb_files, terra::rast)
  if (length(agb_rasters) == 1) {
    agb <- agb_rasters[[1]]
  } else {
    agb <- do.call(terra::mosaic, agb_rasters)
  }

  # Crop to extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  agb <- terra::crop(agb, extent_vect)

  # Aggregate if needed (native ~100m to target resolution)
  native_res <- terra::res(agb)[1] * 111000  # Convert degrees to meters (approximate)
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating AGB by factor %d", agg_factor))
    agb <- terra::aggregate(agb, fact = agg_factor, fun = mean, na.rm = TRUE)
  }

  # Process SD if available
  sd <- NULL
  if (length(sd_files) > 0) {
    message("Processing SD tiles...")
    sd_rasters <- lapply(sd_files, terra::rast)
    if (length(sd_rasters) == 1) {
      sd <- sd_rasters[[1]]
    } else {
      sd <- do.call(terra::mosaic, sd_rasters)
    }

    sd <- terra::crop(sd, extent_vect)

    if (agg_factor > 1) {
      message(sprintf("Aggregating SD by factor %d", agg_factor))
      sd <- terra::aggregate(sd, fact = agg_factor, fun = mean, na.rm = TRUE)
    }
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    year <- stringr::str_extract(basename(agb_files[1]), "\\d{4}")
    res_label <- gsub("000$", "km", as.character(target_res/1000))

    agb_file <- file.path(outdir, sprintf("agb_%s_%s.tif", year, res_label))
    terra::writeRaster(agb, agb_file, overwrite = TRUE)
    message(sprintf("Saved AGB to %s", agb_file))

    if (!is.null(sd)) {
      sd_file <- file.path(outdir, sprintf("sd_%s_%s.tif", year, res_label))
      terra::writeRaster(sd, sd_file, overwrite = TRUE)
      message(sprintf("Saved SD to %s", sd_file))
    }
  }

  return(list(agb = agb, sd = sd))
}

#' Fetch ESA CCI Biomass AGB and SD maps
#'
#' Downloads and processes ESA CCI Biomass Aboveground Biomass (AGB) and
#' Standard Deviation (SD) maps for a specified region, year, and version.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric or "latest", year to fetch (2010, 2015-2022). Default: 2010
#' @param version Character or "latest", ESA CCI version (v2.0-v6.0). Default: "v3.0"
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed rasters. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param tiles_dir Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/ESACCI-BIOMASS"
#' @param n_cores Integer, number of cores for parallel download. Default: 1
#'
#' @return Named list with two SpatRaster objects: \code{agb} (Aboveground Biomass in Mg/ha)
#'   and \code{sd} (Standard Deviation in Mg/ha). If SD data is not available, sd will be NULL.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for Mexico
#' mexico_bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)
#'
#' # Fetch ESA CCI Biomass for 2010
#' biomass <- getESACCIAGB(mexico_bbox, year = 2010, resolution = "10km")
#'
#' # Access AGB and SD
#' plot(biomass$agb, main = "AGB 2010")
#' plot(biomass$sd, main = "SD 2010")
#' }
#'
#' @references
#' Santoro, M., & Cartus, O. (2023). ESA Biomass Climate Change Initiative (Biomass_cci):
#' Global datasets of forest above-ground biomass for the years 2010, 2017, 2018, 2019 and 2020.
#' NERC EDS Centre for Environmental Data Analysis. \doi{10.5285/5f331c418e9f4935b8eb1b836f8a91b8}
getESACCIAGB <- function(extent,
                         year = 2010,
                         version = "v3.0",
                         resolution = "10km",
                         outdir = NULL,
                         download = TRUE,
                         tiles_dir = "data/ESACCI-BIOMASS",
                         n_cores = 1) {

  # Validate inputs
  bbox <- validate_extent(extent)
  validated <- validate_esacci_args(year, version)
  year <- validated$year
  version <- validated$version

  # Get or download tiles
  if (download) {
    message(sprintf("Downloading ESA CCI Biomass for year %d, version %s", year, version))
    files <- download_esacci_biomass(
      roi = extent,
      year = year,
      version = version,
      output_folder = tiles_dir,
      n_cores = n_cores
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", tiles_dir)
    agb_tiles <- esacci_tile_names(extent, year, version, type = "agb")
    sd_tiles <- esacci_tile_names(extent, year, version, type = "sd")
    files <- c(
      file.path(tiles_dir, basename(agb_tiles)),
      file.path(tiles_dir, basename(sd_tiles))
    )
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", tiles_dir))
    }
  }

  # Process tiles
  message("Processing ESA CCI Biomass tiles...")
  result <- process_esacci_biomass(files, extent, resolution, outdir)

  return(result)
}
