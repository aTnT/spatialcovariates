# Main wrapper function to get all bias covariates

#' Fetch and Stack All Bias Covariates for Plot2Map
#'
#' Orchestrates the fetching and processing of all environmental covariates
#' commonly used in Plot2Map workflows for bias modeling and uncertainty
#' quantification. Downloads and processes ESA CCI Biomass, Forest Height,
#' Biomes, Tree Cover, Terrain (slope/aspect), and Intact Forest Landscapes.
#'
#' @param extent sf object, SpatVector, or numeric bbox vector (xmin, ymin, xmax, ymax)
#'   specifying the region of interest
#' @param year Numeric, base year for temporal datasets (default: 2010).
#'   Note: Not all datasets have data for all years. See Details.
#' @param resolution Character, target resolution for all layers (e.g., "10km", "1000m").
#'   Default: "10km"
#' @param outdir Character, optional directory to save processed rasters. Default: NULL
#' @param download Logical, whether to download tiles (TRUE) or use existing. Default: TRUE
#' @param data_dir Character, base directory for all data storage. Default: "data"
#' @param n_cores Integer, number of cores for parallel downloads. Default: 1
#' @param include_agb Logical, include ESA CCI AGB data. Default: TRUE
#' @param include_height Logical, include Potapov height data. Default: TRUE
#' @param include_biome Logical, include Dinerstein biomes. Default: TRUE
#' @param include_treecover Logical, include Sexton tree cover. Default: TRUE
#' @param include_terrain Logical, include SRTM terrain (slope/aspect). Default: TRUE
#' @param include_ifl Logical, include Intact Forest Landscapes. Default: TRUE
#'
#' @return SpatRaster stack with named layers:
#'   \describe{
#'     \item{agb}{Aboveground Biomass (Mg/ha) from ESA CCI}
#'     \item{height}{Forest Canopy Height (m) from Potapov et al.}
#'     \item{biome}{Biome classification (1-14) from RESOLVE Ecoregions}
#'     \item{treecover}{Percent Tree Cover (0-100) from Sexton et al.}
#'     \item{slope}{Slope (degrees) from SRTM}
#'     \item{aspect}{Aspect (degrees, 0-360) from SRTM}
#'     \item{ifl}{Intact Forest Landscape binary (0/1)}
#'   }
#'
#' @details
#' ## Temporal Coverage
#'
#' Not all datasets have data for all years. The function uses the following logic:
#'
#' - **ESA CCI AGB**: Available for 2010, 2017-2022. Uses specified year if available,
#'   otherwise defaults to 2010.
#' - **Potapov Height**: Represents ~2019 conditions regardless of year parameter.
#' - **Dinerstein Biomes**: Static dataset (2017), no temporal variation.
#' - **Sexton Tree Cover**: Available for 2010 and 2015. Uses 2010 if year <= 2010,
#'   otherwise 2015.
#' - **SRTM Terrain**: Static DEM, no temporal variation.
#' - **IFL**: Available for 2000, 2013, 2016, 2020. Uses closest available year.
#'
#' ## Data Sources
#'
#' All data is downloaded from public sources without requiring API keys:
#' - ESA CCI: CEDA Archive
#' - Potapov Height: GLAD/UMD
#' - Dinerstein: RESOLVE Ecoregions
#' - Sexton: UMD GLCF
#' - SRTM: CGIAR-CSI
#' - IFL: Intact Forests
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#'
#' # Define extent for Mexico
#' mexico_bbox <- c(xmin = -118, ymin = 14, xmax = -86, ymax = 33)
#'
#' # Fetch all covariates at 10km resolution
#' covariates <- getBiasCovariates(
#'   extent = mexico_bbox,
#'   year = 2010,
#'   resolution = "10km",
#'   n_cores = 4
#' )
#'
#' # Plot stack
#' plot(covariates)
#'
#' # Access individual layers
#' agb <- covariates[["agb"]]
#' slope <- covariates[["slope"]]
#'
#' # Use in Plot2Map workflow
#' library(Plot2Map)
#' bias_model <- extractBiasCovariates(
#'   plot_data = my_plots,
#'   map_agb_raster = covariates[["agb"]],
#'   covariate_rasters = covariates[[c("height", "biome", "treecover",
#'                                     "slope", "aspect", "ifl")]]
#' )
#' }
#'
#' @references
#' See individual function documentation for detailed references:
#' \code{\link{getESACCIAGB}}, \code{\link{getPotapovHeight}},
#' \code{\link{getDinersteinBiome}}, \code{\link{getSextonTreeCover}},
#' \code{\link{getSRTMTerrain}}, \code{\link{getIFL}}
getBiasCovariates <- function(extent,
                             year = 2010,
                             resolution = "10km",
                             outdir = NULL,
                             download = TRUE,
                             data_dir = "data",
                             n_cores = 1,
                             include_agb = TRUE,
                             include_height = TRUE,
                             include_biome = TRUE,
                             include_treecover = TRUE,
                             include_terrain = TRUE,
                             include_ifl = TRUE) {

  # Validate inputs
  bbox <- validate_extent(extent)
  target_res <- parse_resolution(resolution)

  message(sprintf("Fetching bias covariates for year %d at resolution %s", year, resolution))
  message(sprintf("Region extent: [%.2f, %.2f] to [%.2f, %.2f]",
                 bbox[1], bbox[2], bbox[3], bbox[4]))

  # Initialize list to store covariates
  covariates_list <- list()

  # 1. ESA CCI AGB and SD
  if (include_agb) {
    message("\n=== Fetching ESA CCI Biomass (AGB) ===")
    tryCatch({
      esa <- getESACCIAGB(
        extent = extent,
        year = year,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "ESACCI-BIOMASS"),
        n_cores = n_cores
      )
      if (!is.null(esa$agb)) {
        covariates_list$agb <- esa$agb
      }
      # Note: SD is available but not included in main stack by default
    }, error = function(e) {
      warning(sprintf("Failed to fetch ESA CCI AGB: %s", e$message))
    })
  }

  # 2. Potapov Forest Height
  if (include_height) {
    message("\n=== Fetching Potapov Forest Height ===")
    tryCatch({
      height <- getPotapovHeight(
        extent = extent,
        year = year,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "POTAPOV_HEIGHT"),
        n_cores = n_cores
      )
      covariates_list$height <- height
    }, error = function(e) {
      warning(sprintf("Failed to fetch Potapov height: %s", e$message))
    })
  }

  # 3. Dinerstein Biomes
  if (include_biome) {
    message("\n=== Fetching Dinerstein Biomes ===")
    tryCatch({
      biome <- getDinersteinBiome(
        extent = extent,
        resolution = resolution,
        outdir = outdir,
        download = download,
        data_dir = file.path(data_dir, "ECOREGIONS")
      )
      covariates_list$biome <- biome
    }, error = function(e) {
      warning(sprintf("Failed to fetch Dinerstein biomes: %s", e$message))
    })
  }

  # 4. Sexton Tree Cover
  if (include_treecover) {
    message("\n=== Fetching Sexton Tree Cover ===")
    # Determine which year to use (2010 or 2015)
    tc_year <- ifelse(year <= 2010, 2010, 2015)
    tryCatch({
      treecover <- getSextonTreeCover(
        extent = extent,
        year = tc_year,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "SEXTON_TCC"),
        n_cores = n_cores
      )
      covariates_list$treecover <- treecover
    }, error = function(e) {
      warning(sprintf("Failed to fetch Sexton tree cover: %s", e$message))
    })
  }

  # 5. SRTM Terrain (slope and aspect)
  if (include_terrain) {
    message("\n=== Fetching SRTM Terrain (Slope & Aspect) ===")
    tryCatch({
      terrain <- getSRTMTerrain(
        extent = extent,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "SRTM"),
        n_cores = n_cores
      )
      if (!is.null(terrain$slope)) {
        covariates_list$slope <- terrain$slope
      }
      if (!is.null(terrain$aspect)) {
        covariates_list$aspect <- terrain$aspect
      }
    }, error = function(e) {
      warning(sprintf("Failed to fetch SRTM terrain: %s", e$message))
    })
  }

  # 6. Intact Forest Landscapes
  if (include_ifl) {
    message("\n=== Fetching Intact Forest Landscapes ===")
    # Determine which IFL year to use (2000, 2013, 2016, 2020)
    ifl_years <- c(2000, 2013, 2016, 2020)
    ifl_year <- ifl_years[which.min(abs(ifl_years - year))]

    tryCatch({
      ifl <- getIFL(
        extent = extent,
        year = ifl_year,
        resolution = resolution,
        outdir = outdir,
        download = download,
        data_dir = file.path(data_dir, "IFL")
      )
      covariates_list$ifl <- ifl
    }, error = function(e) {
      warning(sprintf("Failed to fetch IFL: %s", e$message))
    })
  }

  # Check if we got any covariates
  if (length(covariates_list) == 0) {
    stop("Failed to fetch any covariates. Check error messages above.")
  }

  message("\n=== Stacking Covariates ===")
  message(sprintf("Successfully fetched %d covariate layer(s): %s",
                 length(covariates_list),
                 paste(names(covariates_list), collapse = ", ")))

  # Stack all rasters
  covariate_stack <- terra::rast(covariates_list)
  names(covariate_stack) <- names(covariates_list)

  # Save stack if outdir specified
  if (!is.null(outdir)) {
    ensure_directory(outdir)
    res_label <- gsub("000$", "km", as.character(target_res/1000))
    stack_file <- file.path(outdir, sprintf("bias_covariates_%d_%s.tif", year, res_label))
    terra::writeRaster(covariate_stack, stack_file, overwrite = TRUE)
    message(sprintf("\nSaved covariate stack to %s", stack_file))
  }

  message("\n=== Complete! ===")
  return(covariate_stack)
}
