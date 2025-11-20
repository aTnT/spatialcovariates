# Main wrapper function to get all bias covariates

#' Fetch and Stack All Bias Covariates for Plot2Map
#'
#' Orchestrates the fetching and processing of all environmental covariates
#' commonly used in Plot2Map workflows for bias modeling and uncertainty
#' quantification. Downloads and processes ESA CCI Biomass, Tree Canopy Cover,
#' Biomes, Terrain (slope/aspect), and Intact Forest Landscapes.
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
#' @param include_agb Logical, include ESA CCI AGB data. Default: FALSE.
#'   Note: For Plot2Map workflows, use \code{\link{getESACCIAGB}} separately to get
#'   both AGB and SD together, avoiding duplicate downloads.
#' @param include_tcc Logical, include GLAD TCC 2010 tree cover data. Default: TRUE
#' @param include_height Logical, include ETH Canopy Height 2020 (requires rgee). Default: FALSE
#' @param include_biome Logical, include Dinerstein biomes. Default: TRUE
#' @param include_treecover Logical, include Hansen GFC tree cover. Default: TRUE
#' @param include_terrain Logical, include SRTM terrain metrics (elevation, slope, aspect, TRI, TPI, roughness).
#'  Default: TRUE
#' @param include_ghm Logical, include Global Human Modification Index (requires rgee). Default: FALSE
#' @param include_ifl Logical, include Intact Forest Landscapes. Default: TRUE
#' @param gee_scale Numeric, scale for GEE exports (used for include_height and include_ghm). Default: 30
#'
#' @return SpatRaster stack with named layers (exact layers depend on include_* parameters):
#' \describe{
#' \item{agb}{Aboveground Biomass (Mg/ha) from ESA CCI (if include_agb=TRUE)}
#' \item{tcc2010}{Tree Canopy Cover (percent) from GLAD TCC 2010}
#' \item{canopy_height}{Canopy Height (m) from ETH 2020 (if include_height=TRUE)}
#' \item{biome}{Biome classification (1-14) from RESOLVE Ecoregions}
#' \item{treecover2000}{Percent Tree Cover (0-100) from Hansen GFC 2000}
#' \item{elevation}{Elevation (m) from SRTM (if include_terrain=TRUE)}
#' \item{slope}{Slope (degrees) from SRTM (if include_terrain=TRUE)}
#' \item{aspect}{Aspect (degrees, 0-360) from SRTM (if include_terrain=TRUE)}
#' \item{tri}{Terrain Ruggedness Index from SRTM (if include_terrain=TRUE)}
#' \item{tpi}{Topographic Position Index from SRTM (if include_terrain=TRUE)}
#' \item{roughness}{Roughness from SRTM (if include_terrain=TRUE)}
#' \item{ghm}{Global Human Modification Index (0-1) from Kennedy et al. (2019) (if include_ghm=TRUE, requires rgee)}
#' \item{ifl}{Intact Forest Landscape binary (0/1)}
#' }
#'
#' @details
#' \strong{Temporal Coverage}
#'
#' Not all datasets have data for all years. The function uses the following logic:
#'
#' \itemize{
#'   \item \strong{ESA CCI AGB}: Available for 2010, 2017-2022. Uses specified year if available,
#'     otherwise defaults to 2010.
#'   \item \strong{GLAD TCC 2010}: Static dataset representing year 2010 tree canopy cover.
#'   \item \strong{ETH Canopy Height 2020}: Static dataset representing year 2020 canopy height (10m resolution).
#'     Requires rgee package and Google Earth Engine account.
#'   \item \strong{Dinerstein Biomes}: Static dataset (2017), no temporal variation.
#'   \item \strong{Hansen GFC Tree Cover}: Uses year 2000 baseline regardless of year parameter.
#'   \item \strong{SRTM Terrain}: Static DEM, no temporal variation. Provides elevation and
#'     derived metrics (slope, aspect, TRI, TPI, roughness).
#'   \item \strong{Global Human Modification}: Static dataset (2016), no temporal variation. Requires rgee.
#'   \item \strong{IFL}: Available for 2000, 2013, 2016, 2020. Uses closest available year.
#' }
#'
#' \strong{Data Sources}
#'
#' Data is downloaded from public sources. Most do not require API keys:
#' \itemize{
#'   \item ESA CCI: CEDA Archive
#'   \item GLAD TCC 2010: GLAD/UMD
#'   \item ETH Canopy Height 2020: Google Earth Engine (requires rgee + GEE account)
#'   \item Dinerstein: RESOLVE Ecoregions
#'   \item Hansen GFC: Google Cloud Storage
#'   \item SRTM: CGIAR-CSI
#'   \item gHM: Google Earth Engine (requires rgee + GEE account)
#'   \item IFL: Intact Forests
#' }
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
#' # Recommended: Fetch AGB and SD separately (for Plot2Map workflows)
#' biomass_data <- getESACCIAGB(
#'   extent = mexico_bbox,
#'   year = 2010,
#'   resolution = "10km"
#' )
#' agb_map <- biomass_data$agb
#' sd_map <- biomass_data$sd
#'
#' # Fetch environmental covariates (no AGB duplication)
#' covariates <- getBiasCovariates(
#'   extent = mexico_bbox,
#'   year = 2010,
#'   resolution = "10km",
#'   n_cores = 4
#'   # include_agb = FALSE by default
#' )
#'
#' # Plot stack
#' plot(covariates)
#'
#' # Use in Plot2Map workflow
#' library(Plot2Map)
#' bias_data <- extractBiasCovariates(
#'   plot_data = my_plots,
#'   map_agb = agb_map,
#'   map_sd = sd_map,
#'   covariates = list(
#'     height = covariates[["height"]],
#'     biome = covariates[["biome"]],
#'     treecover = covariates[["treecover2000"]],
#'     slope = covariates[["slope"]],
#'     aspect = covariates[["aspect"]],
#'     ifl = covariates[["ifl"]]
#'   )
#' )
#' }
#'
#' @references
#' See individual function documentation for detailed references:
#' \code{\link{getESACCIAGB}}, \code{\link{getGLADTCC2010}}, \code{\link{getETHCanopyHeight}},
#' \code{\link{getDinersteinBiome}}, \code{\link{getHansenGFC}},
#' \code{\link{getSRTMTerrain}}, \code{\link{getGlobalHumanMod}}, \code{\link{getIFL}}
getBiasCovariates <- function(extent,
                             year = 2010,
                             resolution = "10km",
                             outdir = NULL,
                             download = TRUE,
                             data_dir = "data",
                             n_cores = 1,
                             include_agb = FALSE,
                             include_tcc = TRUE,
                             include_height = FALSE,
                             include_biome = TRUE,
                             include_treecover = TRUE,
                             include_terrain = TRUE,
                             include_ghm = FALSE,
                             include_ifl = TRUE,
                             gee_scale = 30) {

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
        names(esa$agb) <- "agb"
        covariates_list$agb <- esa$agb
      }
      # Note: SD is available but not included in main stack by default
    }, error = function(e) {
      warning(sprintf("Failed to fetch ESA CCI AGB: %s", e$message))
    })
  }

  # 2. GLAD TCC 2010
  if (include_tcc) {
    message("\n=== Fetching GLAD TCC 2010 ===")
    tryCatch({
      tcc <- getGLADTCC2010(
        extent = extent,
        year = year,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "GLAD_TCC_2010"),
        n_cores = n_cores
      )
      names(tcc) <- "tcc2010"
      covariates_list$tcc2010 <- tcc
    }, error = function(e) {
      warning(sprintf("Failed to fetch GLAD TCC 2010: %s", e$message))
    })
  }

  # 3. ETH Canopy Height 2020 (optional - requires rgee)
  if (include_height) {
    message("\n=== Fetching ETH Canopy Height 2020 (Google Earth Engine) ===")
    tryCatch({
      height <- getETHCanopyHeight(
        extent = extent,
        resolution = resolution,
        outdir = outdir,
        scale = gee_scale
      )
      names(height) <- "canopy_height"
      covariates_list$canopy_height <- height
    }, error = function(e) {
      warning(sprintf("Failed to fetch ETH Canopy Height 2020: %s\n", e$message),
              "To use ETH height data:\n",
              "1. Install rgee: install.packages('rgee')\n",
              "2. Set up Earth Engine: rgee::ee_install() and rgee::ee_Initialize()")
    })
  }

  # 4. Dinerstein Biomes
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
      names(biome) <- "biome"
      covariates_list$biome <- biome
    }, error = function(e) {
      warning(sprintf("Failed to fetch Dinerstein biomes: %s", e$message))
    })
  }

  # 5. Hansen GFC Tree Cover 2000
  if (include_treecover) {
    message("\n=== Fetching Hansen GFC Tree Cover 2000 ===")
    tryCatch({
      treecover <- getHansenGFC(
        extent = extent,
        year = 2000,  # Hansen GFC uses 2000 baseline
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "HANSEN_TC"),
        n_cores = n_cores
      )
      names(treecover) <- "treecover2000"
      covariates_list$treecover2000 <- treecover
    }, error = function(e) {
      warning(sprintf("Failed to fetch Hansen GFC tree cover: %s", e$message))
    })
  }

  # 6. SRTM Terrain (elevation, slope, aspect, TRI, TPI, roughness)
  if (include_terrain) {
    message("\n=== Fetching SRTM Terrain ===")
    tryCatch({
      terrain <- getSRTMTerrain(
        extent = extent,
        resolution = resolution,
        outdir = outdir,
        download = download,
        tiles_dir = file.path(data_dir, "SRTM"),
        n_cores = n_cores
      )
      if (!is.null(terrain$elevation)) {
        names(terrain$elevation) <- "elevation"
        covariates_list$elevation <- terrain$elevation
      }
      if (!is.null(terrain$slope)) {
        names(terrain$slope) <- "slope"
        covariates_list$slope <- terrain$slope
      }
      if (!is.null(terrain$aspect)) {
        names(terrain$aspect) <- "aspect"
        covariates_list$aspect <- terrain$aspect
      }
      if (!is.null(terrain$tri)) {
        names(terrain$tri) <- "tri"
        covariates_list$tri <- terrain$tri
      }
      if (!is.null(terrain$tpi)) {
        names(terrain$tpi) <- "tpi"
        covariates_list$tpi <- terrain$tpi
      }
      if (!is.null(terrain$roughness)) {
        names(terrain$roughness) <- "roughness"
        covariates_list$roughness <- terrain$roughness
      }
    }, error = function(e) {
      warning(sprintf("Failed to fetch SRTM terrain: %s", e$message))
    })
  }

  # 7. Global Human Modification Index (via Google Earth Engine)
  if (include_ghm) {
    message("\n=== Fetching Global Human Modification (GEE) ===")
    tryCatch({
      ghm <- getGlobalHumanMod(
        extent = extent,
        resolution = resolution,
        outdir = outdir,
        scale = gee_scale
      )
      names(ghm) <- "ghm"
      covariates_list$ghm <- ghm
    }, error = function(e) {
      warning(sprintf("Failed to fetch gHM: %s", e$message))
    })
  }

  # 8. Intact Forest Landscapes
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
      names(ifl) <- "ifl"
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

  # Align all rasters to a common grid before stacking
  # Use the first raster as template
  template <- covariates_list[[1]]

  if (length(covariates_list) > 1) {
    for (i in 2:length(covariates_list)) {
      # Resample to match template extent and resolution
      covariates_list[[i]] <- terra::resample(covariates_list[[i]], template, method = "near")
    }
  }

  # Stack all rasters (names are already set on individual layers)
  covariate_stack <- terra::rast(covariates_list)

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
