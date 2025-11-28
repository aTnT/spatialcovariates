# ESA CCI Biomass Functions
# Ported and adapted from Plot2Map package

#' Validate ESA CCI Biomass year and version arguments
#'
#' @param esacci_biomass_year Numeric or character, year to validate
#' @param esacci_biomass_version Character, version to validate
#'
#' @return List with validated esacci_biomass_year and esacci_biomass_version
#' @keywords internal
#' @export
validate_esacci_biomass_args <- function(esacci_biomass_year, esacci_biomass_version) {
  valid_years <- c(2007, 2010, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022)
  valid_versions <- c("v2.0", "v3.0", "v4.0", "v5.0", "v5.01", "v6.0")

  # Handle "latest" keywords
  if (is.character(esacci_biomass_year) && esacci_biomass_year == "latest") {
    esacci_biomass_year <- 2022
  }
  if (is.character(esacci_biomass_version) && esacci_biomass_version == "latest") {
    esacci_biomass_version <- "v6.0"
  }

  esacci_biomass_year <- as.numeric(esacci_biomass_year)
  if (!esacci_biomass_year %in% valid_years) {
    stop(sprintf("Invalid year: %d. Valid years are: %s",
                esacci_biomass_year, paste(valid_years, collapse = ", ")))
  }

  if (!esacci_biomass_version %in% valid_versions) {
    stop(sprintf("Invalid version: %s. Valid versions are: %s",
                esacci_biomass_version, paste(valid_versions, collapse = ", ")))
  }

  # Version-specific year constraints
  if (esacci_biomass_version %in% c("v2.0", "v3.0")) {
    if (!esacci_biomass_year %in% c(2010, 2017, 2018)) {
      stop(sprintf("Version %s only supports years 2010, 2017, and 2018", esacci_biomass_version))
    }
  } else if (esacci_biomass_version == "v4.0") {
    if (!esacci_biomass_year %in% c(2010, 2017:2020)) {
      stop(sprintf("Version %s only supports years 2010, 2017-2020", esacci_biomass_version))
    }
  } else if (esacci_biomass_version %in% c("v5.0", "v5.01")) {
    if (!esacci_biomass_year %in% c(2010, 2017:2021)) {
      stop(sprintf("Version %s only supports years 2010, 2017-2021", esacci_biomass_version))
    }
  } else if (esacci_biomass_version == "v6.0") {
    if (!esacci_biomass_year %in% c(2007, 2010, 2015:2022)) {
      stop(sprintf("Version %s only supports years 2007, 2010, 2015-2022", esacci_biomass_version))
    }
  }

  return(list(
    esacci_biomass_year = esacci_biomass_year,
    esacci_biomass_version = esacci_biomass_version
  ))
}

#' Generate ESA CCI AGB tile names for a region
#'
#' @param roi sf object, SpatVector, or numeric bbox
#' @param esacci_biomass_year Numeric, year
#' @param esacci_biomass_version Character, version string
#' @param type Character, either "agb" or "sd" for standard deviation
#'
#' @return Character vector of tile filenames
#' @keywords internal
esacci_tile_names <- function(roi, esacci_biomass_year, esacci_biomass_version, type = "agb") {
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
    file_version <- gsub("^v", "fv", esacci_biomass_version)

    # Handle v5.01 special case (can be stored as either fv5.0 or fv5.01)
    if (esacci_biomass_version == "v5.01") {
      file_version <- "fv5.0"
    }

    if (type == "sd") {
      tile_names[i] <- sprintf("%s%s%s%s_ESACCI-BIOMASS-L4-AGB_SD-MERGED-100m-%d-%s.tif",
                              lat_letter, lat_str, lon_letter, lon_str, esacci_biomass_year, file_version)
    } else {
      tile_names[i] <- sprintf("%s%s%s%s_ESACCI-BIOMASS-L4-AGB-MERGED-100m-%d-%s.tif",
                              lat_letter, lat_str, lon_letter, lon_str, esacci_biomass_year, file_version)
    }
  }

  return(unique(tile_names))
}

#' Download ESA CCI Biomass data from CEDA Archive
#'
#' @param esacci_biomass_year Numeric or "latest", year to download (2007, 2010, 2015-2022)
#' @param esacci_biomass_version Character or "latest", version to download (v2.0-v6.0)
#' @param esacci_folder Character, directory to save files (default: "data/ESACCI-BIOMASS")
#' @param n_cores Integer, number of cores for parallel download (default: parallel::detectCores() - 1)
#' @param timeout Numeric, download timeout in seconds (default: 600)
#' @param file_names Character vector, optional specific filenames to download
#'
#' @return Character vector of downloaded file paths
#'
#' @importFrom pbapply pblapply
#' @importFrom parallel makeCluster stopCluster detectCores
#' @importFrom rvest read_html html_table
#' @importFrom httr GET content
#'
#' @export
download_esacci_biomass <- function(esacci_biomass_year = "latest",
                                   esacci_biomass_version = "latest",
                                   esacci_folder = "data/ESACCI-BIOMASS",
                                   n_cores = parallel::detectCores() - 1,
                                   timeout = 600,
                                   file_names = NULL) {

  # Validate arguments
  validated <- validate_esacci_biomass_args(esacci_biomass_year, esacci_biomass_version)
  esacci_biomass_year <- validated$esacci_biomass_year
  esacci_biomass_version <- validated$esacci_biomass_version

  base_url <- "https://data.ceda.ac.uk/neodc/esacci/biomass/data/agb/maps"

  # Check if output directory exists, if not create it
  if (!dir.exists(esacci_folder)) {
    dir.create(esacci_folder, recursive = TRUE)
    message(paste("Created output directory:", esacci_folder))
  }

  # Construct URL
  url <- file.path(base_url, esacci_biomass_version, "geotiff", as.character(esacci_biomass_year))

  # Fetch file list
  page <- rvest::read_html(url)
  file_table <- rvest::html_table(page, fill = TRUE)[[1]]
  available_files <- file_table$X1

  # If specific file_names are provided, use those. Otherwise, use all available files.
  if (!is.null(file_names)) {
    file_names <- intersect(file_names, available_files)
    if (length(file_names) == 0) {
      if (esacci_biomass_version == "v5.01") {
        # Create versions with 5.0 and 5.01
        v5_0 <- gsub("-fv[0-9.]+", "-fv5.0", file_names)
        v5_01 <- gsub("-fv[0-9.]+", "-fv5.01", file_names)

        # Combine both versions
        result <- c(v5_0, v5_01)

        file_names <- intersect(result, available_files)

      } else {
        stop("None of the specified file names are available for download.")
      }
    }
  } else {
    file_names <- available_files
  }

  # Download function
  download_file <- function(file_name) {
    options(timeout = max(timeout, getOption("timeout")))

    file_url <- file.path(url, file_name)
    output_file <- file.path(esacci_folder, file_name)
    download.file(file_url, output_file, mode = "wb", quiet = TRUE)
    return(output_file)
  }

  message(paste0("Downloading ", length(file_names), " ESA CCI Biomass ", esacci_biomass_version,
                 " file(s) for year ", esacci_biomass_year, "..."))

  # Setup parallel processing with progress bar
  cl <- parallel::makeCluster(n_cores)

  # Parallel download with progress and error handling
  downloaded_files <- pbapply::pblapply(file_names, function(file_name) {
    tryCatch({
      download_file(file_name)
    }, error = function(e) {
      warning(paste("Failed to download:", file_name, "-", e$message))
      return(file.path(esacci_folder, file_name))
    })
  }, cl = cl)

  parallel::stopCluster(cl)

  # Check which files actually exist and return only those
  downloaded_files <- unlist(downloaded_files)
  existing_files <- downloaded_files[file.exists(downloaded_files)]

  return(existing_files)
}

#' Generate ESA-CCI AGB tile names (Plot2Map compatible)
#'
#' This function generates file names for ESA-CCI AGB tiles based on a given polygon.
#'
#' @param pol An sf or SpatVector object representing the polygon of interest.
#' @inheritParams download_esacci_biomass
#'
#' @return A character vector of unique file names for ESA-CCI AGB tiles.
#'
#' @importFrom sf st_bbox
#' @importFrom terra ext xmin xmax ymin ymax
#'
#' @export
ESACCIAGBtileNames <- function(pol,
                               esacci_biomass_year = "latest",
                               esacci_biomass_version = "latest") {

  esacci_args <- validate_esacci_biomass_args(esacci_biomass_year, esacci_biomass_version)
  esacci_biomass_year <- esacci_args$esacci_biomass_year
  esacci_biomass_version <- esacci_args$esacci_biomass_version

  if (inherits(pol, "SpatVector")) {
    bb <- terra::ext(pol)
    bb_vec <- c(terra::xmin(bb), terra::ymin(bb), terra::xmax(bb), terra::ymax(bb))
  } else if (inherits(pol, "sf") || inherits(pol, "sfc")) {
    bb_vec <- sf::st_bbox(pol)
  } else {
    stop("The object representing the polygon of interest must be of class SpatVector from terra package or any sf object.")
  }

  crds <- expand.grid(x = c(bb_vec[1], bb_vec[3]), y = c(bb_vec[2], bb_vec[4]))
  fnms <- character(nrow(crds))

  for (i in 1:nrow(crds)) {
    lon <- 10 * (crds$x[i] %/% 10)
    lat <- 10 * (crds$y[i] %/% 10) + 10
    LtX <- ifelse(lon < 0, "W", "E")
    LtY <- ifelse(lat < 0, "S", "N")
    WE <- paste0(LtX, sprintf('%03d', abs(lon)))
    NS <- paste0(LtY, sprintf('%02d', abs(lat)))

    if (esacci_biomass_version == "v5.01") {
      esacci_biomass_version <- "v5.0"
    }

    fnms[i] <- paste0(NS, WE, "_ESACCI-BIOMASS-L4-AGB-MERGED-100m-", esacci_biomass_year, "-f", esacci_biomass_version, ".tif")
  }
  unique(setdiff(fnms, grep("1000m|AGB_SD|aux", fnms, value = TRUE)))
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

  # Define target extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])

  # Calculate aggregation factor
  # ESA CCI native resolution is ~100m
  native_res <- 100  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  message("Processing AGB tiles...")
  # Load, crop, and aggregate AGB tiles BEFORE mosaicking (much faster!)
  agb_rasters <- lapply(agb_files, function(f) {
    tryCatch({
      r <- terra::rast(f)
      # Crop immediately to reduce data volume
      r <- terra::crop(r, extent_vect)
      # Aggregate immediately if needed
      if (agg_factor > 1) {
        r <- terra::aggregate(r, fact = agg_factor, fun = mean, na.rm = TRUE)
      }
      return(r)
    }, error = function(e) {
      warning(sprintf("Failed to process AGB file %s: %s", f, e$message))
      return(NULL)
    })
  })

  # Remove NULLs
  agb_rasters <- agb_rasters[!sapply(agb_rasters, is.null)]

  # Mosaic if multiple tiles (now much smaller!)
  if (length(agb_rasters) == 1) {
    agb <- agb_rasters[[1]]
  } else {
    message(sprintf("Mosaicking %d aggregated AGB tiles...", length(agb_rasters)))
    agb <- do.call(terra::mosaic, agb_rasters)
  }

  # Final crop to exact extent
  agb <- terra::crop(agb, extent_vect)

  # Process SD if available
  sd <- NULL
  if (length(sd_files) > 0) {
    message("Processing SD tiles...")
    # Load, crop, and aggregate SD tiles BEFORE mosaicking
    sd_rasters <- lapply(sd_files, function(f) {
      tryCatch({
        r <- terra::rast(f)
        r <- terra::crop(r, extent_vect)
        if (agg_factor > 1) {
          r <- terra::aggregate(r, fact = agg_factor, fun = mean, na.rm = TRUE)
        }
        return(r)
      }, error = function(e) {
        warning(sprintf("Failed to process SD file %s: %s", f, e$message))
        return(NULL)
      })
    })

    # Remove NULLs
    sd_rasters <- sd_rasters[!sapply(sd_rasters, is.null)]

    if (length(sd_rasters) == 1) {
      sd <- sd_rasters[[1]]
    } else {
      message(sprintf("Mosaicking %d aggregated SD tiles...", length(sd_rasters)))
      sd <- do.call(terra::mosaic, sd_rasters)
    }

    # Final crop to exact extent
    sd <- terra::crop(sd, extent_vect)
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
#' @param esacci_biomass_year Numeric or "latest", year to fetch (2007, 2010, 2015-2022). Default: 2010
#' @param esacci_biomass_version Character or "latest", ESA CCI version (v2.0-v6.0). Default: "latest"
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed rasters. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param esacci_folder Character, directory containing existing tiles (if download=FALSE).
#'   Default: "data/ESACCI-BIOMASS"
#' @param n_cores Integer, number of cores for parallel download. Default: parallel::detectCores() - 1
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
#' biomass <- getESACCIAGB(mexico_bbox, esacci_biomass_year = 2010, resolution = "10km")
#'
#' # Access AGB and SD
#' plot(biomass$agb, main = "AGB 2010")
#' plot(biomass$sd, main = "SD 2010")
#' }
#'
#' @references
#' Santoro, M., & Cartus, O. (2025). ESA Biomass Climate Change Initiative (Biomass_cci):
#' Global datasets of forest above-ground biomass for the years 2007, 2010, 2015-2022, v6.0.
#' NERC EDS Centre for Environmental Data Analysis. \doi{10.5285/95913ffb6467447ca72c4e9d8cf30501}
getESACCIAGB <- function(extent,
                         esacci_biomass_year = 2010,
                         esacci_biomass_version = "latest",
                         resolution = "10km",
                         outdir = NULL,
                         download = TRUE,
                         esacci_folder = "data/ESACCI-BIOMASS",
                         n_cores = parallel::detectCores() - 1) {

  # Validate inputs
  bbox <- validate_extent(extent)
  validated <- validate_esacci_biomass_args(esacci_biomass_year, esacci_biomass_version)
  esacci_biomass_year <- validated$esacci_biomass_year
  esacci_biomass_version <- validated$esacci_biomass_version

  # Get required tiles for the extent
  agb_tiles <- esacci_tile_names(extent, esacci_biomass_year, esacci_biomass_version, type = "agb")
  sd_tiles <- esacci_tile_names(extent, esacci_biomass_year, esacci_biomass_version, type = "sd")
  all_tiles <- unique(c(basename(agb_tiles), basename(sd_tiles)))

  # Get or download tiles
  if (download) {
    message(sprintf("Downloading ESA CCI Biomass for year %d, version %s",
                    esacci_biomass_year, esacci_biomass_version))
    files <- download_esacci_biomass(
      esacci_biomass_year = esacci_biomass_year,
      esacci_biomass_version = esacci_biomass_version,
      esacci_folder = esacci_folder,
      n_cores = n_cores,
      file_names = all_tiles
    )
  } else {
    # List existing tiles
    message("Using existing tiles from ", esacci_folder)
    files <- c(
      file.path(esacci_folder, basename(agb_tiles)),
      file.path(esacci_folder, basename(sd_tiles))
    )
    files <- files[file.exists(files)]

    if (length(files) == 0) {
      stop(sprintf("No tiles found in %s. Set download=TRUE to fetch them.", esacci_folder))
    }
  }

  # Process tiles
  message("Processing ESA CCI Biomass tiles...")
  result <- process_esacci_biomass(files, extent, resolution, outdir)

  return(result)
}
