# ETH Global Canopy Height 2020 Functions
# ETH provides 10m resolution canopy height for year 2020
# Data accessed via Google Earth Engine (requires rgee package)

#' Fetch ETH Global Canopy Height 2020 via Google Earth Engine
#'
#' Downloads and processes ETH Global Canopy Height 2020 data at 10m resolution
#' via Google Earth Engine and aggregates to target resolution. Requires rgee
#' package and authenticated Google Earth Engine account.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param scale Numeric, scale in meters for GEE export (default: 10 for native resolution).
#'   For large areas, use larger scale (e.g., 30, 100) to reduce processing time.
#'
#' @return SpatRaster object with canopy height in meters for year 2020
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' library(rgee)
#'
#' # Initialize Earth Engine (first time setup)
#' ee_Initialize()
#'
#' # Define extent for a region
#' bbox <- c(xmin = -75, ymin = -10, xmax = -70, ymax = -5)
#'
#' # Fetch ETH Canopy Height 2020
#' height <- getETHCanopyHeight(bbox, resolution = "10km")
#' plot(height, main = "Canopy Height 2020 (m)")
#' }
#'
#' @references
#' Lang, N., Kalischek, N., Armston, J., Schindler, K., Dubayah, R., & Wegner, J. D. (2023).
#' Global canopy height regression and uncertainty estimation from GEDI LIDAR waveforms with
#' deep ensembles. *Remote Sensing of Environment*, 268, 112760.
#' \doi{10.1016/j.rse.2021.112760}
#'
#' @note
#' \strong{Requirements}:
#' \itemize{
#'   \item Install rgee package: \code{install.packages("rgee")}
#'   \item Set up Google Earth Engine account: https://earthengine.google.com/signup/
#'   \item Initialize rgee: \code{rgee::ee_Initialize()}
#' }
#'
#' \strong{GEE Asset}: \code{users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1}
#'
#' \strong{Performance Notes}:
#' \itemize{
#'   \item For large regions (>1000 km²), use \code{scale = 30} or higher to reduce processing time
#'   \item Native 10m resolution may cause memory issues for very large extents
#'   \item Consider processing large regions in smaller chunks
#' }
getETHCanopyHeight <- function(extent,
                               resolution = "10km",
                               outdir = NULL,
                               scale = 10) {

  # Check if rgee is installed
  if (!requireNamespace("rgee", quietly = TRUE)) {
    stop("Package 'rgee' is required but not installed.\n",
         "Install it with: install.packages('rgee')\n",
         "Then set up Earth Engine: rgee::ee_install() and rgee::ee_Initialize()")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Fetching ETH Global Canopy Height 2020 from Google Earth Engine...")

  # Check if Earth Engine is initialized
  tryCatch({
    rgee::ee$Image(1)$getInfo()
  }, error = function(e) {
    stop("Google Earth Engine not initialized. Run: rgee::ee_Initialize()\n",
         "If this is your first time, also run: rgee::ee_install()")
  })

  # Create Earth Engine geometry
  ee_bbox <- rgee::ee$Geometry$Rectangle(
    coords = c(bbox[1], bbox[2], bbox[3], bbox[4]),
    proj = "EPSG:4326",
    geodesic = FALSE
  )

  # Load ETH Canopy Height asset
  # Asset: users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1
  message("Loading ETH Canopy Height asset...")
  eth_height <- rgee::ee$Image("users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1")

  # Clip to extent
  eth_height <- eth_height$clip(ee_bbox)

  # Export from Earth Engine to local file
  message(sprintf("Exporting from GEE at %dm scale (this may take a few minutes)...", scale))

  # Create temporary directory for GEE export
  temp_dir <- tempdir()
  temp_file <- file.path(temp_dir, "eth_height_temp.tif")

  # Download using ee_as_rast (rgee function)
  tryCatch({
    height_raster <- rgee::ee_as_rast(
      image = eth_height,
      region = ee_bbox,
      scale = scale,
      via = "drive",  # Use Google Drive for large exports
      lazy = FALSE
    )
  }, error = function(e) {
    stop("Failed to export from Google Earth Engine: ", e$message, "\n",
         "Possible causes:\n",
         "1. Region too large - try smaller extent or larger scale parameter\n",
         "2. Google Drive not linked - run: rgee::ee_Initialize(drive = TRUE)\n",
         "3. Earth Engine quota exceeded - wait and try again later")
  })

  message("Processing ETH Canopy Height...")

  # Convert to terra SpatRaster if needed
  if (!inherits(height_raster, "SpatRaster")) {
    height_raster <- terra::rast(height_raster)
  }

  # Aggregate to target resolution if needed
  current_res <- terra::res(height_raster)[1] * 111000  # Convert degrees to meters (approximate)
  agg_factor <- calc_aggregation_factor(current_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating canopy height by factor %d (%dm -> %dm)",
                   agg_factor, round(current_res), target_res))
    height_raster <- terra::aggregate(height_raster, fact = agg_factor, fun = mean, na.rm = TRUE)
  }

  # Set layer name
  names(height_raster) <- "canopy_height"

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    height_file <- file.path(outdir, sprintf("eth_height2020_%s.tif", res_label))
    terra::writeRaster(height_raster, height_file, overwrite = TRUE)
    message(sprintf("Saved ETH Canopy Height to %s", height_file))
  }

  message("ETH Canopy Height 2020 ready!")
  return(height_raster)
}
