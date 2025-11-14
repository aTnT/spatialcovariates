#' @keywords internal
"_PACKAGE"

#' spatialcovariates: Automated Covariate Fetching for Plot2Map Bias Modeling
#'
#' The spatialcovariates package provides automated functions to fetch, process,
#' and stack environmental covariates commonly used in Plot2Map workflows for
#' bias modeling and uncertainty quantification.
#'
#' @section Main Functions:
#'
#' The package exports the following main user-facing functions:
#'
#' \describe{
#'   \item{\code{\link{getBiasCovariates}}}{Fetch and stack all covariates at once (recommended)}
#'   \item{\code{\link{getESACCIAGB}}}{Fetch ESA CCI Biomass AGB and SD maps}
#'   \item{\code{\link{getPotapovHeight}}}{Fetch Global Forest Canopy Height}
#'   \item{\code{\link{getDinersteinBiome}}}{Fetch RESOLVE Ecoregions biomes}
#'   \item{\code{\link{getSextonTreeCover}}}{Fetch Global Tree Canopy Cover}
#'   \item{\code{\link{getSRTMTerrain}}}{Fetch SRTM terrain (slope and aspect)}
#'   \item{\code{\link{getIFL}}}{Fetch Intact Forest Landscapes}
#' }
#'
#' @section Key Features:
#'
#' \itemize{
#'   \item{Download data from public sources without API keys}
#'   \item{Automatic spatial cropping and resolution resampling}
#'   \item{Parallel downloads for faster processing}
#'   \item{Built-in caching to avoid redundant downloads}
#'   \item{Full integration with Plot2Map workflows}
#' }
#'
#' @section Getting Started:
#'
#' The simplest way to use the package is with \code{getBiasCovariates()}:
#'
#' \preformatted{
#' library(spatialcovariates)
#'
#' # Define your region of interest
#' bbox <- c(xmin = -75, ymin = -10, xmax = -50, ymax = 5)
#'
#' # Fetch all covariates
#' covariates <- getBiasCovariates(
#'   extent = bbox,
#'   year = 2010,
#'   resolution = "10km",
#'   n_cores = 4
#' )
#'
#' # Use in Plot2Map
#' library(Plot2Map)
#' extractBiasCovariates(plot_data, covariates[["agb"]], covariates[[-1]])
#' }
#'
#' @docType package
#' @name spatialcovariates-package
#' @aliases spatialcovariates
NULL
