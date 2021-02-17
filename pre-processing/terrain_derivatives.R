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
#'     code_folding: hide
#' ---
#' 
#' ## Setup
#' Call libraries, data and initialize SAGA

#+ setup, include = F
knitr::opts_chunk$set(echo = TRUE, warning = F, message = F, out.width = "100%")

#+ Libraries
library(here)
library(terrain)
library(terra)

#+ Directories
stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#' Set a prefix for file naming
#+ prefix, eval = T
prefix = "mangatu_"
in_dem = here(stec_dir, 'Mangatu_feature_extraction', 'Mangatu_LiDAR_DEM_2019.tif')
out = here('data_rs', 'terrain')

#' ### Convert to SAGA format
#+ Load, eval = F
elev_to_sgrd(
  elev_filename = in_dem,
  out_filename = here(out, paste0(prefix, "dem.sgrd"))
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
  vdcnw = T
)

#' ### Convert from SAGA to GeoTIFF
library(stars)
r = read_stars(in_dem)
c = st_crs(r)$wkt
terrain_to_tif(out, c)
