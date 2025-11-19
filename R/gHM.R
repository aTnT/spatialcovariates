# Global Human Modification Index Functions
# gHM accessed via Google Earth Engine (requires rgee package)

#' Fetch Global Human Modification Index via Google Earth Engine
#'
#' Downloads and processes Global Human Modification (gHM) data at 1km resolution
#' via Google Earth Engine and aggregates to target resolution. The gHM quantifies
#' the cumulative impact of direct human pressures on the environment. Requires
#' rgee package and authenticated Google Earth Engine account.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param resolution Character, target resolution (e.g., "10km", "1000m"). Default: "10km"
#' @param outdir Character, optional directory to save processed raster. Default: NULL
#' @param scale Numeric, scale in meters for GEE export (default: 1000 for native resolution).
#'   For very large areas, use larger scale to reduce processing time.
#'
#' @return SpatRaster object with human modification index (0-1), where:
#'   0 = No human modification, 1 = Maximum human modification
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
#' # Fetch Global Human Modification Index
#' ghm <- getGlobalHumanMod(bbox, resolution = "10km")
#' plot(ghm, main = "Human Modification Index (0-1)")
#' }
#'
#' @references
#' Kennedy, C. M., Oakleaf, J. R., Theobald, D. M., Baruch-Mordo, S., & Kiesecker, J. (2019).
#' Managing the middle: A shift in conservation priorities based on the global human
#' modification gradient. *Global Change Biology*, 25(3), 811-826.
#' \doi{10.1111/gcb.14549}
#'
#' @note
#' \strong{Requirements}:
#' \itemize{
#'   \item Install rgee package: \code{install.packages("rgee")}
#'   \item Set up Google Earth Engine account: https://earthengine.google.com/signup/
#'   \item Initialize rgee: \code{rgee::ee_Initialize()}
#' }
#'
#' \strong{GEE Asset}: \code{CSP/HM/GlobalHumanModification}
#'
#' \strong{Performance Notes}:
#' \itemize{
#'   \item Native 1km resolution is usually fast enough for most regions
#'   \item For very large regions (>10,000 km²), consider using \code{scale = 5000} or higher
#' }
getGlobalHumanMod <- function(extent,
                              resolution = "10km",
                              outdir = NULL,
                              scale = 1000) {

  # Check if rgee is installed
  if (!requireNamespace("rgee", quietly = TRUE)) {
    stop("Package 'rgee' is required but not installed.\n",
         "Install it with: install.packages('rgee')\n",
         "Then set up Earth Engine: rgee::ee_install() and rgee::ee_Initialize()")
  }

  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message("Fetching Global Human Modification from Google Earth Engine...")

  # Check if Earth Engine is initialized
  tryCatch({
    rgee::ee$Image(1)$getInfo()
  }, error = function(e) {
    stop("Google Earth Engine not initialized. Run: rgee::ee_Initialize()\n",
         "If this is your first time, also run: rgee::ee_install()")
  })

  # Load gHM dataset from GEE
  ghm_image <- rgee::ee$Image("CSP/HM/GlobalHumanModification")$select("gHM")

  # Create bounding box geometry
  roi <- rgee::ee$Geometry$Rectangle(
    coords = c(bbox[1], bbox[2], bbox[3], bbox[4]),
    proj = "EPSG:4326",
    geodesic = FALSE
  )

  # Clip to ROI
  ghm_clipped <- ghm_image$clip(roi)

  # Export from Earth Engine
  message(sprintf("Exporting gHM from GEE at %dm scale (this may take a few minutes)...", scale))

  ghm_rast <- tryCatch({
    rgee::ee_as_raster(
      image = ghm_clipped,
      region = roi,
      scale = scale,
      via = "drive",
      quiet = TRUE
    )
  }, error = function(e) {
    stop("Failed to export from Earth Engine. Error: ", e$message, "\n",
         "Try increasing 'scale' parameter or reducing extent size.")
  })

  # Convert to terra SpatRaster if needed
  if (!inherits(ghm_rast, "SpatRaster")) {
    ghm_rast <- terra::rast(ghm_rast)
  }

  # Set layer name
  names(ghm_rast) <- "gHM"

  # Aggregate to target resolution if needed
  native_res <- scale  # meters
  agg_factor <- calc_aggregation_factor(native_res, target_res)

  if (agg_factor > 1) {
    message(sprintf("Aggregating gHM by factor %d (%dm -> %dm)",
                   agg_factor, native_res, target_res))
    ghm_rast <- terra::aggregate(ghm_rast, fact = agg_factor, fun = mean, na.rm = TRUE)
  }

  # Save if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    ghm_file <- file.path(outdir, sprintf("gHM_%s.tif", res_label))
    terra::writeRaster(ghm_rast, ghm_file, overwrite = TRUE)
    message(sprintf("Saved gHM to %s", ghm_file))
  }

  return(ghm_rast)
}
