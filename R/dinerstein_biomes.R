# Dinerstein RESOLVE Ecoregions Biomes Functions

#' Download RESOLVE Ecoregions shapefile
#'
#' Downloads the global RESOLVE Ecoregions 2017 shapefile from the official source.
#'
#' @param output_folder Character, directory to save and extract files
#'   (default: "data/ECOREGIONS")
#' @param timeout Numeric, download timeout in seconds (default: 600)
#'
#' @return Character, path to the extracted shapefile
#'
#' @keywords internal
download_dinerstein_biomes <- function(output_folder = "data/ECOREGIONS",
                                      timeout = 600) {

  ensure_directory(output_folder)

  zip_url <- "https://storage.googleapis.com/teow2016/Ecoregions2017.zip"
  zip_file <- file.path(output_folder, "Ecoregions2017.zip")
  shp_file <- file.path(output_folder, "Ecoregions2017.shp")

  # Check if shapefile already exists
  if (file.exists(shp_file)) {
    message("Ecoregions shapefile already exists, skipping download")
    return(shp_file)
  }

  # Download zip file
  message("Downloading RESOLVE Ecoregions 2017 shapefile...")
  success <- download_with_retry(zip_url, zip_file, timeout = timeout, quiet = TRUE)

  if (!success) {
    stop("Failed to download Ecoregions shapefile from ", zip_url)
  }

  # Extract zip file
  message("Extracting shapefile...")
  tryCatch({
    utils::unzip(zip_file, exdir = output_folder)
  }, error = function(e) {
    stop(sprintf("Failed to extract %s: %s", zip_file, e$message))
  })

  # Verify shapefile exists
  if (!file.exists(shp_file)) {
    stop(sprintf("Shapefile not found after extraction: %s", shp_file))
  }

  # Clean up zip file
  unlink(zip_file)

  message(sprintf("Ecoregions shapefile ready at %s", shp_file))
  return(shp_file)
}

#' Process Dinerstein biomes (rasterize, crop, aggregate)
#'
#' @param shp_file Character, path to ecoregions shapefile
#' @param extent sf object, SpatVector, or numeric bbox
#' @param resolution Character or numeric, target resolution (e.g., "10km")
#' @param outdir Character, optional output directory to save processed raster
#'
#' @return SpatRaster object with biome classes as integers
#'
#' @importFrom sf st_read st_crop st_bbox
#' @importFrom terra rast vect rasterize crop aggregate writeRaster modal
#'
#' @keywords internal
process_dinerstein_biomes <- function(shp_file, extent, resolution = "10km", outdir = NULL) {

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Reading ecoregions shapefile...")
  # Read shapefile
  ecoreg <- tryCatch({
    sf::st_read(shp_file, quiet = TRUE)
  }, error = function(e) {
    stop(sprintf("Failed to read shapefile %s: %s", shp_file, e$message))
  })

  # Check for BIOME_NUM field
  if (!"BIOME_NUM" %in% names(ecoreg)) {
    stop("BIOME_NUM field not found in ecoregions shapefile")
  }

  # Crop to extent for efficiency
  # Fix invalid geometries before cropping to avoid S2 errors
  extent_sf <- sf::st_as_sfc(sf::st_bbox(bbox, crs = 4326))
  sf::sf_use_s2(FALSE)  # Disable spherical geometry for invalid source data
  ecoreg <- sf::st_crop(ecoreg, extent_sf)
  sf::sf_use_s2(TRUE)  # Re-enable S2

  if (nrow(ecoreg) == 0) {
    stop("No ecoregions found within the specified extent")
  }

  message("Rasterizing biomes...")

  # Create template raster at target resolution
  # Convert resolution to degrees (approximate)
  res_deg <- target_res / 111000

  template <- terra::rast(
    xmin = bbox[1], xmax = bbox[3],
    ymin = bbox[2], ymax = bbox[4],
    resolution = res_deg,
    crs = "EPSG:4326"
  )

  # Convert sf to terra::vect
  ecoreg_vect <- terra::vect(ecoreg)

  # Rasterize using BIOME_NUM field
  # Use 'max' to handle overlaps (though there shouldn't be any)
  biome_rast <- terra::rasterize(ecoreg_vect, template, field = "BIOME_NUM", fun = "max")

  # Crop to exact extent (in case rasterization extended it)
  extent_vect <- terra::ext(bbox[1], bbox[3], bbox[2], bbox[4])
  biome_rast <- terra::crop(biome_rast, extent_vect)

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    biome_file <- file.path(outdir, "Ecoregions2017_biome.tif")
    terra::writeRaster(biome_rast, biome_file, overwrite = TRUE, datatype = "INT2U")
    message(sprintf("Saved biome raster to %s", biome_file))
  }

  return(biome_rast)
}

#' Fetch RESOLVE Ecoregions Biomes (Dinerstein et al., 2017)
#'
#' Downloads and processes the RESOLVE Ecoregions 2017 dataset, rasterizing
#' biome classifications to the target resolution.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param download Logical, whether to download shapefile (TRUE) or use existing. Default: TRUE
#' @param data_dir Character, directory containing/to contain ecoregions shapefile.
#'   Default: "data/ECOREGIONS"
#'
#' @return SpatRaster object with biome classes as integers (1-14). Biome codes:
#'   \describe{
#'     \item{1}{Tropical & Subtropical Moist Broadleaf Forests}
#'     \item{2}{Tropical & Subtropical Dry Broadleaf Forests}
#'     \item{3}{Tropical & Subtropical Coniferous Forests}
#'     \item{4}{Temperate Broadleaf & Mixed Forests}
#'     \item{5}{Temperate Conifer Forests}
#'     \item{6}{Boreal Forests/Taiga}
#'     \item{7}{Tropical & Subtropical Grasslands, Savannas & Shrublands}
#'     \item{8}{Temperate Grasslands, Savannas & Shrublands}
#'     \item{9}{Flooded Grasslands & Savannas}
#'     \item{10}{Montane Grasslands & Shrublands}
#'     \item{11}{Tundra}
#'     \item{12}{Mediterranean Forests, Woodlands & Scrub}
#'     \item{13}{Deserts & Xeric Shrublands}
#'     \item{14}{Mangroves}
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
#' # Fetch biome classification
#' biomes <- getDinersteinBiome(bbox, resolution = "10km")
#' plot(biomes, main = "RESOLVE Ecoregions Biomes")
#' }
#'
#' @references
#' Dinerstein, E., Olson, D., Joshi, A., Vynne, C., Burgess, N. D., Wikramanayake, E., ...
#' & Saleem, M. (2017). An ecoregion-based approach to protecting half the terrestrial realm.
#' BioScience, 67(6), 534-545. \doi{10.1093/biosci/bix014}
getDinersteinBiome <- function(extent,
                              resolution = "10km",
                              outdir = NULL,
                              download = TRUE,
                              data_dir = "data/ECOREGIONS") {

  bbox <- validate_extent(extent)

  # Get or download shapefile
  if (download) {
    message("Downloading RESOLVE Ecoregions 2017 shapefile...")
    shp_file <- download_dinerstein_biomes(output_folder = data_dir)
  } else {
    shp_file <- file.path(data_dir, "Ecoregions2017.shp")
    if (!file.exists(shp_file)) {
      stop(sprintf("Shapefile not found at %s. Set download=TRUE to fetch it.", shp_file))
    }
  }

  # Process shapefile
  message("Processing biomes...")
  result <- process_dinerstein_biomes(shp_file, extent, resolution, outdir)

  return(result)
}
