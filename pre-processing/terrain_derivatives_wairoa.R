#' ---
#' title: "Terrain derivatives"
#' subtitle: "STEC project"
#' author: "Lorena Abad"
#' date: "February 9, 2021"
#' output: 
#'   html_document: 
#'     toc: true
#'     toc_depth: 3
#'     toc_float: true
#'     code_folding: show
#' ---
#' 
#' ## Setup
#' Call libraries, data and initialize SAGA

#+ setup, include = F
knitr::opts_chunk$set(echo = TRUE, warning = F, message = F, out.width = "100%")

#+ Libraries
library(here)
# remotes::install_github('loreabad6/terrain')
library(terrain)
library(terra)

#+ Directories
# stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#' Set a prefix for file naming
#+ prefix, eval = T
prefix = "wairoa_g119_"
in_dem = here('data_wairoa', 'LiDAR_DEM_2018_grid119.tif')
out = here('data', 'terrain')

#' ### Convert to SAGA format
#+ Load, eval = F
elev_to_sgrd(
  elev_filename = in_dem,
  out_filename = here(out, paste0(prefix, "dem.sdat"))
)

#' ### Initialize SAGA
#' To create the terrain derivatives we need to have a SAGA local GUI
#+ init, eval = F
saga_path = here('..', 'Earthflows_R/software/saga-7.6.1_x64')
saga_env = init_saga(saga_path)

#' ## Calculate derivatives
#+ demset, eval = F
dem = here(out, paste0(prefix, 'dem.sgrd'))

#+ calc, eval = F
elev_to_morphometry(
  elev_sgrd = dem,
  out_dir = out,
  prefix = prefix,
  envir = saga_env,
  cplan = T,
  cprof = T,
  ddgrd = T,
  mbidx = T,
  slope = T,
  textu = T,
  tridx = T
)

elev_to_lighting(
  elev_sgrd = dem,
  out_dir = out,
  prefix = prefix,
  envir = saga_env,
  shade = T
)

elev_to_terrain_analysis(
  elev_sgrd = dem,
  out_dir = out,
  prefix = prefix,
  envir = saga_env,
  lsfct = T,
  flow = T,
  spcar = T,
  twidx = T
)

slope = here(out, paste0(prefix, 'slope.sgrd'))
spcar = here(out, paste0(prefix, 'spcar.sgrd'))
flow = here(out, paste0(prefix, 'flow.sgrd'))

elev_to_hidrology(
  elev_sgrd = dem,
  slope_sgrd = slope,
  spcar_sgrd = spcar,
  out_dir = out,
  prefix = prefix,
  envir = saga_env,
  spidx = T
)

elev_to_channel(
  elev_sgrd = dem,
  flow_sgrd = flow,
  out_dir = out,
  prefix = prefix,
  envir = saga_env,
  chnet = TRUE,
  vdcnw = TRUE,
  init_value = 500,
  chnet_shp = TRUE
)

#' ### Convert from SAGA to GeoTIFF
#' The current version of GDAL (3.1.4) offered by OSGEO4W
#' does not seem to support WKT crs inputs. Hence, we need
#' to rely still on the ArcGIS toolbox to reproject the data. 
#+ translate, eval = F
# c = sf::st_crs("EPSG:2193")$wkt
terrain_to_tif(
  out
  # out_crs = c
)

#' ## Remarks:
#' Some layers still need to be checked visually!
#' 
#' ## Overview:
#+ eval = F
# files = list.files(path = "data/terrain", pattern = "*tif$", full.names = T)
# file_names = list.files(path = "data/terrain", pattern = "*tif$")
# library(stars)
# library(purrr)
# files_read = files[2:15] %>% map(function(x) read_stars(x, proxy = T))
# par(mfrow = c(3,5))
# invisible(lapply(files_read, function(x) {
#   plot(x, key.pos = NULL, reset = F, main = NULL)
# }))
#+ out.width = "90%"
knitr::include_graphics("../data_overview/terrain_derivatives.png")
#+ render, eval = F, include = F
o = knitr::spin('pre-processing/terrain_derivatives.R', knit = FALSE)
rmarkdown::render(o)
