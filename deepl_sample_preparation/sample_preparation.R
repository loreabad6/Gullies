#' ---
#' title: "Vector sample preparation for Deep Learning analysis"
#' subtitle: "STEC project"
#' author: "Lorena Abad"
#' date: "March 8, 2021"
#' output: 
#'   html_document: 
#'     toc: true
#'     toc_depth: 3
#'     toc_float: true
#'     code_folding: hide
#' ---
#' ## Setup
#' Call libraries and data

#+ setup, include = F
knitr::opts_chunk$set(echo = FALSE, warning = F, message = F, out.width = "100%")

#+ Libraries
library(here)
library(sf)
library(tidyverse, quietly = T, warn.conflicts = F)

#+ Directories
stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#+ Data
g39 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1939_ero_feat_nztm.shp'))
g57 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_57_tm.shp'))
g60 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1960_ero_feat_nztm.shp'))
g70 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1970_ero_feat_nztm.shp'))
g88 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'mangatu_1988_ero_feat_nztm.shp'))
g97_1 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_97_tm.shp'))
g97_2 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_97_f_tm.shp'))

#+ Combine, echo = T
# Establish some common variables
eros_marden2014 = list(g39, g60, g70, g88)
year_marden2014 = c(1939, 1960, 1970, 1988)
# Create function to harmonize datasets
prepare_for_merge = function(x, y, colnames) {
  z = mutate(x, year = y)
  if (!is.null(colnames)) {
    names(z) = c(colnames, 'year')
  }
  z
}
# Merge data
eros_ = purrr::map2(
  eros_marden2014,
  year_marden2014,
  prepare_for_merge,
  colnames = names(g39)
)
eros_merge = do.call(rbind, eros_) %>% 
  mutate_if(is.character, factor)

#+ Filter
gullies_marden2014 = eros_merge %>% 
  filter(str_detect(eros_feat_, "gully")) %>% 
  select(year) 

#' Apply same process for data from Marden et al. 2012
#+ Combine2
eros_marden2012 = list(g57, g97_1, g97_2)
year_marden2012 = c(1957, 1997, 1997)
l_ = lapply(eros_marden2012, st_cast, "POLYGON")
l_0 = lapply(l_, select, geometry)
l_1 = purrr::map2(
  l_0,
  year_marden2012,
  prepare_for_merge,
  colnames = NULL
)
gullies_marden2012 = do.call(rbind, l_1) %>% 
  mutate_if(is.character, factor) %>% 
  st_transform(crs = st_crs(gullies_marden2014))

#' Merge both sources
#+ connect
gullies = rbind(gullies_marden2012, gullies_marden2014)

#' Export data
#+ export, eval = F
st_write(gullies, here("deepl_sample_preparation/gullies.shp"), delete_dsn = T)

#+ render, eval = F, include = F
o = knitr::spin('exploration/esda.R', knit = FALSE)
rmarkdown::render(o)