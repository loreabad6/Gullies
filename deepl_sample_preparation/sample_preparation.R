#' ---
#' title: "Vector sample preparation for DeepL analysis"
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
g88 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'mangatu_1988_ero_feat_nztm.shp'))
gully_centroid = g88 %>%
  filter(str_detect(eros_feat_, "gully")) %>% 
  mutate(geometry = st_centroid(geometry))
st_write(gully_centroid, "deepl_sample_preparation/gully_point_features.shp")

sa = st_read(here(stec_dir, "Mangatu_feature_extraction", "mangatu_study_area.shp"))
sa_proj = sa %>%
  st_transform(crs = st_crs(g88)) 

sa_border = sa_proj %>% 
  st_buffer(-1000)

erosion_features_buf = g88 %>% 
  st_union() %>% 
  st_buffer(units::set_units(100, "m"))

no_feature = st_difference(sa_border, erosion_features_buf)

set.seed(837)
control_samples = no_feature %>% 
  st_sample(150) %>% 
  st_sf() %>% 
  transmute(class = "control", classvalue = 0)

gully = gully_centroid %>% 
  transmute(class = "gully", classvalue = 1)


samples = rbind(gully, control_samples) 
st_write(samples, "deepl_sample_preparation/sample_point_features.shp")
