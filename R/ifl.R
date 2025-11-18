# Intact Forest Landscapes (IFL) Functions

#' Download Intact Forest Landscapes shapefile
#'
#' Downloads IFL 2016 shapefile from the official Intact Forests website.
#'
#' @param output_folder Character, directory to save and extract files
#'   (default: "data/IFL")
#' @param timeout Numeric, download timeout in seconds (default: 600)
#' @param year Numeric, year to download (2000, 2013, 2016, or 2020). Default: 2016
#'
#' @return Character, path to the extracted shapefile
#'
#' @keywords internal
download_ifl <- function(output_folder = "data/IFL",
                        timeout = 600,
                        year = 2016) {

  ensure_directory(output_folder)

  # IFL data URLs by year
  ifl_urls <- list(
    "2000" = "https://intactforests.org/data/ifl_2000.zip",
    "2013" = "https://intactforests.org/data/ifl_2013.zip",
    "2016" = "https://intactforests.org/data/ifl_2016.zip",
    "2020" = "https://intactforests.org/data/ifl_2020.zip"
  )

  year_str <- as.character(year)
  if (!year_str %in% names(ifl_urls)) {
    stop(sprintf("IFL data not available for year %d. Available years: %s",
                year, paste(names(ifl_urls), collapse = ", ")))
  }

  zip_url <- ifl_urls[[year_str]]
  zip_file <- file.path(output_folder, sprintf("ifl_%d.zip", year))
  shp_file <- file.path(output_folder, sprintf("ifl_%d.shp", year))

  # Check if shapefile already exists
  if (file.exists(shp_file)) {
    message(sprintf("IFL %d shapefile already exists, skipping download", year))
    return(shp_file)
  }

  # Download zip file
  message(sprintf("Downloading IFL %d shapefile from %s...", year, zip_url))
  success <- download_with_retry(zip_url, zip_file, timeout = timeout, quiet = FALSE)

  if (!success) {
    stop(sprintf("Failed to download IFL shapefile from %s", zip_url))
  }

  # Extract zip file
  message("Extracting shapefile...")
  tryCatch({
    utils::unzip(zip_file, exdir = output_folder)
  }, error = function(e) {
    stop(sprintf("Failed to extract %s: %s", zip_file, e$message))
  })

  # The shapefile name inside the zip may vary, so search for it
  shp_files <- list.files(output_folder, pattern = "\\.shp$", full.names = TRUE)

  if (length(shp_files) == 0) {
    stop(sprintf("No shapefile found after extracting %s", zip_file))
  }

  # Use the first .shp file found
  shp_file <- shp_files[1]

  # Clean up zip file
  unlink(zip_file)

  message(sprintf("IFL shapefile ready at %s", shp_file))
  return(shp_file)
}

#' Process IFL shapefile (rasterize, crop, aggregate)
#'
#' @param shp_file Character, path to IFL shapefile
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed raster
#'
#' @return SpatRaster object with binary IFL classification (1 = intact, 0 = not intact)
#'
#' @importFrom sf st_read st_crop st_bbox st_as_sfc
#' @importFrom terra rast vect rasterize crop aggregate writeRaster
#'
#' @keywords internal
process_ifl <- function(shp_file, extent, resolution = "10km", outdir = NULL) {

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Reading IFL shapefile...")

  # Read shapefile
  ifl <- tryCatch({
    sf::st_read(shp_file, quiet = TRUE)
  }, error = function(e) {
    stop(sprintf("Failed to read shapefile %s: %s", shp_file, e$message))
  })

  # Crop to extent for efficiency
  extent_sf <- sf::st_as_sfc(sf::st_bbox(bbox, crs = 4326))

  tryCatch({
    ifl <- sf::st_crop(ifl, extent_sf)
  }, error = function(e) {
    # st_crop can fail for various reasons, try intersection instead
    message("st_crop failed, trying st_intersection...")
    ifl <- sf::st_intersection(ifl, extent_sf)
  })

  if (nrow(ifl) == 0) {
    warning("No intact forest landscapes found within the specified extent. Returning empty raster.")

    # Create empty raster
    res_deg <- target_res / 111000
    template <- terra::rast(
      xmin = bbox[1], xmax = bbox[3],
      ymin = bbox[2], ymax = bbox[4],
      resolution = res_deg,
      crs = "EPSG:4326"
    )
    template[] <- 0  # Fill with zeros (no IFL)
    return(template)
  }

  message("Rasterizing IFL...")

  # Create template raster at target resolution
  res_deg <- target_res / 111000

  template <- terra::rast(
    xmin = bbox[1], xmax = bbox[3],
    ymin = bbox[2], ymax = bbox[4],
    resolution = res_deg,
    crs = "EPSG:4326"
  )

  # Convert sf to terra::vect
  ifl_vect <- terra::vect(ifl)

  # Rasterize as binary: any IFL polygon = 1
  ifl_rast <- terra::rasterize(ifl_vect, template, fun = "max", background = 0)

  # Set all non-zero values to 1 (binary)
  ifl_rast[ifl_rast > 0] <- 1

  # Crop to exact extent
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  ifl_rast <- terra::crop(ifl_rast, extent_vect)

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    year <- stringr::str_extract(basename(shp_file), "\\d{4}")
    if (is.na(year)) year <- "2016"
    year_short <- substr(year, 3, 4)
    ifl_file <- file.path(outdir, sprintf("ifl_%s.tif", year_short))
    terra::writeRaster(ifl_rast, ifl_file, overwrite = TRUE, datatype = "INT1U")
    message(sprintf("Saved IFL raster to %s", ifl_file))
  }

  return(ifl_rast)
}

#' Fetch Intact Forest Landscapes (IFL)
#'
#' Downloads and processes Intact Forest Landscapes data, providing binary
#' classification of intact vs non-intact forest areas.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, IFL year to fetch (2000, 2013, 2016, or 2020). Default: 2016
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download shapefile (TRUE) or use existing. Default: TRUE
#' @param data_dir Character, directory containing/to contain IFL shapefile.
#'   Default: "data/IFL"
#'
#' @return SpatRaster object with binary values:
#'   \describe{
#'     \item{1}{Intact Forest Landscape}
#'     \item{0}{Non-intact or no forest}
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' # Define extent for Amazon region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -50, ymax = 5)
#'
#' # Fetch IFL 2016 data
#' ifl <- getIFL(bbox, year = 2016, resolution = "10km")
#' plot(ifl, main = "Intact Forest Landscapes 2016")
#' }
#'
#' @references
#' Potapov, P., Hansen, M. C., Laestadius, L., Turubanova, S., Yaroshenko, A.,
#' Thies, C., ... & Esipova, E. (2017). The last frontiers of wilderness:
#' Tracking loss of intact forest landscapes from 2000 to 2013.
#' Science Advances, 3(1), e1600821. \doi{10.1126/sciadv.1600821}
getIFL <- function(extent,
                  year = 2016,
                  resolution = "10km",
                  outdir = NULL,
                  download = TRUE,
                  data_dir = "data/IFL") {

  bbox <- validate_extent(extent)

  if (!year %in% c(2000, 2013, 2016, 2020)) {
    warning("IFL data is available for years 2000, 2013, 2016, and 2020. Using 2016.")
    year <- 2016
  }

  # Get or download shapefile
  if (download) {
    message(sprintf("Downloading IFL %d shapefile...", year))
    shp_file <- download_ifl(output_folder = data_dir, year = year)
  } else {
    # Find shapefile in data_dir
    shp_files <- list.files(data_dir, pattern = sprintf(".*%d.*\\.shp$", year), full.names = TRUE)
    if (length(shp_files) == 0) {
      stop(sprintf("No IFL shapefile found for year %d in %s. Set download=TRUE to fetch it.",
                  year, data_dir))
    }
    shp_file <- shp_files[1]
  }

  # Process shapefile
  message("Processing IFL...")
  result <- process_ifl(shp_file, extent, resolution, outdir)

  return(result)
}
