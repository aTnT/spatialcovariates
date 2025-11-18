# Requirements for spatialcovariates R Package

## Overview

This document outlines the requirements for developing a new R package
called `spatialcovariates`. The package will provide automated functions
to fetch, process, and stack environmental covariates commonly used in
Plot2Map workflows for bias modeling and uncertainty quantification
(e.g., as demonstrated in the Mexico AGB mapping notebook).

The package focuses on reproducibility by: - Prioritizing
STAC-compatible catalogs for querying and downloading data. - Clipping
rasters to a user-specified extent (e.g., country boundary). -
Resampling/aggregating to a target resolution (e.g., 10 km to match ESA
CCI AGB maps). - Handling fallbacks for non-STAC sources (e.g., direct
FTP downloads or shapefile rasterization).

Once implemented, the package can be imported into Plot2Map (e.g., via
[`library(spatialcovariates)`](https://atnt.github.io/spatialcovariates/))
and used in functions like `extractBiasCovariates()` by passing the
stacked covariates.

**Target Users**: Plot2Map developers and users analyzing AGB maps
globally or regionally.

**Package Structure**: - `DESCRIPTION`: Standard R package metadata
(Title: “Automated Covariate Fetching for Plot2Map Bias Modeling”;
Version: 0.1.0; Depends: R (\>= 4.0); Imports: terra, sf, rstac, httr,
etc.). - `R/`: Core functions (detailed below). - `man/`: Rd
documentation for all exported functions. - `tests/`: Unit tests for
each function (e.g., using `testthat`). - `README.md`: Installation,
usage examples (including Mexico demo), and citations. - No vignettes
initially; add one for full workflow integration.

## Dependencies

Add these to `DESCRIPTION` under `Imports` and `Suggests` where
appropriate. Ensure compatibility with Plot2Map’s existing stack (terra,
sf, etc.).

### Required (`Imports`)

- `terra` (\>= 1.7-78): Raster processing, cropping, resampling,
  aggregation.
- `sf` (\>= 1.0-16): Spatial vector handling (e.g., extents as sf
  polygons).
- `rstac` (\>= 1.1.1): STAC catalog queries and downloads.
- `httr` (\>= 1.4.7): HTTP requests for direct downloads.
- `dplyr` (\>= 1.1.4): Data manipulation (if needed for tile listing).
- `raster` (\>= 3.6-20): Legacy compatibility (e.g., `rasterize` for
  shapefiles).

### Optional (`Suggests`)

- `rgee` (\>= 1.1.5): Fallback for GEE exports (e.g., Sexton Tree Cover
  if STAC fails).
- `testthat` (\>= 3.2.0): For testing.

No external APIs requiring keys (STAC is public; fallbacks are direct
links).

## CRAN Compatibility

The package must be fully CRAN-compatible to facilitate easy submission
and maintenance. Key requirements include:

- **R CMD Check Compliance**: Pass `R CMD check --as-cran` with zero
  errors, zero warnings, and zero notes on at least R versions 4.0+
  (test via `devtools::check()` or `rcmdcheck`).
- **Documentation Standards**: Use `roxygen2` for all Rd files; ensure
  `@examples` are executable and non-interactive (no plotting unless
  wrapped in `if(interactive())`).
- **Code Style and Practices**:
  - Follow tidyverse style guide (e.g., via `lintr` or `styler`).
  - No calls to
    [`install.packages()`](https://rdrr.io/r/utils/install.packages.html),
    [`library()`](https://rdrr.io/r/base/library.html) in functions; use
    [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) for
    optional deps.
  - Avoid
    [`packageStartupMessage()`](https://rdrr.io/r/base/message.html) in
    `.onLoad()`; use
    [`utils::packageDescription()`](https://rdrr.io/r/utils/packageDescription.html)
    for version checks sparingly.
  - All functions must handle missing arguments gracefully with
    defaults.
- **Testing Coverage**: Aim for \>80% code coverage via `testthat`;
  include tests for edge cases (e.g., invalid extents, offline mode).
- **Versioning and Metadata**:
  - Support R \>= 4.0 in `DESCRIPTION`.
  - Include `NEWS.md` for changelog (even for v0.1.0).
  - License: MIT (explicitly state in `DESCRIPTION` and include
    `LICENSE` file).
- **Platform Independence**: Ensure no platform-specific code (e.g.,
  test on Linux/Mac/Windows via `rhub::check_for_cran()`).
- **Submission Readiness**: Before finalizing, run
  `devtools::spell_check()` for spelling, `devtools::release()` dry-run,
  and validate with CRAN’s repository policies (e.g., no external
  binaries).

## Functions to Implement

Implement each function in `R/Covariates.R`. All functions should: -
Accept `extent` (sf polygon or numeric bbox vector). - Accept `year`
(numeric, default 2010 to match notebook). - Accept `resolution`
(character, e.g., “10km”; compute aggregation factor based on native
res). - Accept `outdir` (character, optional; save processed rasters as
GeoTIFF). - Return
[`terra::rast`](https://rspatial.github.io/terra/reference/rast.html)
(or list for paired outputs). - Include verbose logging (e.g.,
[`cat()`](https://rdrr.io/r/base/cat.html) for progress). - Handle
errors gracefully (e.g., if STAC fails, try direct download). - Document
with `@param`, `@return`, `@examples` in Rd format.

### 1. `getESACCIAGB`

- **Purpose**: Fetch ESA CCI Biomass AGB and SD maps (v3, 2010).
- **Source**: MAAP STAC catalog (`esa-cci-biomass-l4-v3`).
- **Logic**:
  - Use `rstac::stac("https://stac-browser.maap-project.org")`.
  - Query with
    `stac_search(collections = "esa-cci-biomass-l4-v3", bbox = st_bbox(extent), datetime = paste0(year, "-01-01/", year, "-12-31"))`.
  - Fetch assets: `agb` and `sd` (NetCDF).
  - Crop to `extent` using
    [`terra::crop()`](https://rspatial.github.io/terra/reference/crop.html).
  - If `resolution == "10km"`, aggregate with
    `terra::aggregate(fact = 3, fun = mean, na.rm = TRUE)` (approx. for
    native ~3 km to 10 km).
- **Output**: Named list `list(agb = rast, sd = rast)`.
- **Filename on Save**: `agb_{year}_10km.tif`, `sd_{year}_10km.tif`.

### 2. `getPotapovHeight`

- **Purpose**: Fetch Global Forest Canopy Height (Potapov et al., 2021;
  ~2010, 30m).
- **Source**: MAAP/GLAD STAC (`glad-glclu2020-change-v2` or `gfch`);
  fallback to GLAD FTP tiles.
- **Logic**:
  - STAC query on `https://stac-browser.maap-project.org` with
    collections including height asset.
  - Crop and aggregate to `resolution` (fact ~3 for 30m → 10km, mean).
  - Fallback: Download tiles covering `extent` from GLAD FTP (implement
    tile-listing helper).
- **Output**: `rast` (height in meters).
- **Filename on Save**: `height_10km.tif`.

### 3. `getDinersteinBiome`

- **Purpose**: Fetch and rasterize RESOLVE Ecoregions biomes (Dinerstein
  et al., 2017; static).
- **Source**: Direct shapefile download from
  `https://ecoregions.appspot.com/ecoregions.zip`.
- **Logic**:
  - Download and unzip to tempdir.
  - Read with `sf::st_read("ecoregions.shp")`.
  - Rasterize `BIOME_NUM` field to initial 10km grid using
    `terra::rasterize(vect(ecoreg["BIOME_NUM"]), rast(extent, resolution = 10000), field = "BIOME_NUM")`.
  - Mask to `extent`.
- **Output**: `rast` (biome classes as integers).
- **Filename on Save**: `Ecoregions2017_biome.tif`.

### 4. `getSextonTreeCover`

- **Purpose**: Fetch Global Tree Canopy Cover (Sexton et al., 2015; 30m,
  2015).
- **Source**: UMD GLCF FTP
  (`ftp://ftp.glcf.umd.edu/glcf/Global_TreeCover/v3/2015/`); fallback to
  GEE via `rgee`.
- **Logic**:
  - Identify and download tiles covering `extent` (implement
    `list_tiles_for_extent()` helper based on lon/lat grid).
  - Mosaic with
    [`terra::mosaic()`](https://rspatial.github.io/terra/reference/mosaic.html).
  - Crop to `extent`; aggregate to `resolution` (mean).
- **Output**: `rast` (% tree cover).
- **Filename on Save**: `TC_Sexton_2015_10km.tif`.

### 5. `getSRTMTerrain`

- **Purpose**: Fetch SRTM V3 DEM and compute slope/aspect.
- **Source**: OpenTopography STAC (`otsrtm.042013.4326.1`).
- **Logic**:
  - STAC query on `https://portal.opentopography.org/api/v1/stac`.
  - Fetch DEM asset.
  - Crop to `extent`.
  - Compute `slope <- terra::terrain(dem, "slope", unit = "degrees")`;
    `aspect <- terra::terrain(dem, "aspect", unit = "degrees")`.
  - Aggregate to `resolution` (mean).
- **Output**: Named list `list(slope = rast, aspect = rast)`.
- **Filename on Save**: `slope_10km.tif`, `aspect_10km.tif`.

### 6. `getIFL`

- **Purpose**: Fetch Intact Forest Landscapes (2016; binary).
- **Source**: OpenLandMap STAC (`forest.cover_esacci.ifl`).
- **Logic**:
  - STAC query on `https://stac.openlandmap.org` with datetime for 2016.
  - Fetch IFL asset (binary: 1 = intact).
  - Crop to `extent`; aggregate to `resolution` (sum \> 0 for binary).
- **Output**: `rast` (binary).
- **Filename on Save**: `ifl_16.tif`.

### 7. `getBiasCovariates` (Wrapper)

- **Purpose**: Orchestrate fetching all covariates and stack them.
- **Logic**:
  - Call all above functions sequentially.
  - Stack with `c(...)`; name layers: `"agb"`, `"height"`, `"biome"`,
    `"treecover"`, `"slope"`, `"aspect"`, `"ifl"`.
  - Note: Use 2015/2016 for tree cover/IFL despite `year` param
    (document year mismatches).
- **Output**: `SpatRaster` stack.
- **Integration Note**: Export this as the main user-facing function;
  suggest calling in Plot2Map’s data loading sections.

## Testing and Validation

- **Unit Tests**: For each function, test on a small extent (e.g.,
  Mexico bbox) with `testthat`. Assert: Non-NA cells \> 0, CRS matches
  EPSG:4326, resolution ~10km.
- **Integration Test**: Run full `getBiasCovariates()` and verify stack
  has 7 layers; compare outputs to notebook’s pre-aggregated files (if
  provided).
- **Edge Cases**: Non-forest extents (e.g., desert), invalid years,
  missing outdir.

## Documentation and Examples

- **Rd Files**: Full params/returns/examples for each.

- **README Example**:

  ``` r
  library(spatialcovariates)
  mexico <- sf::st_read("ne_10m_admin_0_countries.shp") |> subset(ADM0_A3 == "MEX")
  covariates <- getBiasCovariates(mexico, year = 2010, resolution = "10km")
  plot(covariates)
  # Now pass to Plot2Map::extractBiasCovariates(plot_data, map_agb_raster = covariates[["agb"]], covariate_rasters = covariates[-1])
  ```

- **License**: MIT (compatible with Plot2Map).

## References

Include these in `inst/REFERENCES.bib` (BibTeX) and cite in README/Rd
files.

1.  **ESA CCI Biomass v3**: Saatchi, S., et al. (2023). ESA Climate
    Change Initiative (CCI) Biomass Climate Data Record (CDR) Version
    3.0. [MAAP STAC
    Catalog](https://stac-browser.maap-project.org/collections/esa-cci-biomass-l4-v3).

2.  **Potapov Forest Height**: Potapov, P., et al. (2021). The last
    frontiers of wilderness: Tracking loss of intact forest landscapes
    from 2000 to 2013. *Science Advances*, 7(6). [GLAD/MAAP
    STAC](https://stac-browser.maap-project.org/collections/glad-glclu2020-change-v2);
    [GEE Asset](https://gee-community-catalog.org/projects/gfch/).

3.  **Dinerstein Ecoregions**: Dinerstein, E., et al. (2017). An
    ecoregion-based approach to protecting half the terrestrial realm.
    *BioScience*, 67(6), 534-545.
    [Download](https://ecoregions.appspot.com/downloads).

4.  **Sexton Tree Cover**: Sexton, J. O., et al. (2015). Global, 30-m
    resolution continuous fields of tree cover: Landsat-based rescaling
    of MODIS vegetation continuous fields with lidar-based estimates of
    error. *International Journal of Digital Earth*, 8(4), 282-300.
    [GLCF FTP](ftp://ftp.glcf.umd.edu/glcf/Global_TreeCover/v3/2015/);
    [GEE Asset](https://gee-community-catalog.org/projects/global_tcc/).

5.  **SRTM V3 DEM**: Farr, T. G., et al. (2007). The Shuttle Radar
    Topography Mission. *Reviews of Geophysics*, 45(2). [OpenTopography
    STAC](https://portal.opentopography.org/api/v1/stac/collections/otsrtm.042013.4326.1).

6.  **Intact Forest Landscapes (IFL) 2016**: Potapov, P., et al. (2017).
    Mapping the world’s intact forest landscapes by remote sensing.
    *Ecology and Society*, 22(2). [OpenLandMap
    STAC](https://stac.openlandmap.org/collections/forest.cover_esacci.ifl);
    [Official Site](https://intactforests.org/data.html).

**Additional Tools**: - STAC Protocol: [STAC
Specification](https://stacspec.org/). - Plot2Map Reference: [Plot2Map
GitHub](https://github.com/aTnT/Plot2Map);
[Documentation](https://atnt.github.io/Plot2Map/index.html).

## Implementation Notes for Claude Code Agent

- Start with `usethis::create_package("spatialcovariates")`.
- Implement functions one-by-one, testing with Mexico example.
- Ensure all code is vectorized/efficient for large extents.
- Output: Commit-ready repo with all files; include a
  `devtools::document()` run.
