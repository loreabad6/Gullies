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
#' #' ## Setup
#' Call libraries and data

#+ setup, include = F
knitr::opts_chunk$set(echo = TRUE, warning = F, message = F, out.width = "100%")

#+ Libraries
library(here)
library(terrain)

#+ Directories
stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#' Set a prefix for file naming
#+ prefix, eval = T
prefix = "mangatu_"

#' Convert to SAGA format
#+ Load, eval = F
elev_to_sgrd(
  elev_filename = here(stec_dir, 'Mangatu_feature_extraction', 'Mangatu_LiDAR_DEM_2019.tif'), 
  out_filename = here('data_rs', 'terrain', paste0(prefix, 'dem.sgrd'))
)
