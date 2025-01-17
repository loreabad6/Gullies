#' ---
#' title: "Coregistration approach"
#' subtitle: "STEC project"
#' author: "Lorena Abad"
#' date: "February 4, 2021"
#' output: 
#'   html_document: 
#'     toc: true
#'     toc_depth: 2
#'     toc_float: true
#' ---
#' I come up with a provisional way to coregister our data given the 
#' following remarks during my data check:
#' 
#' - **Previous data: `mangatu_eros_feat` folder**
#' - The data seems to be displaced slightly 
#' - It might need some coregistration(?) 
#' - 1960 seems to be good.
#' - **Latest data: `Mangatu_feature_extraction` folder + aerial photos**
#' - Only 1988 was corrected on the second badge of data coming from Raphael
#'   - mangatu_1988_ero_feat.shp (incorrect)
#'   - mangatu_1988_ero_feat_nztm.shp (correct)
#' 
#' ## Setup

#+ Libraries
library(here)
library(sf)
library(tidyverse, quietly = T, warn.conflicts = F)
library(mapview)

#+ Directories
stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#' ## Data exploration
#'
#' 1. Call reference data for coregistration
#+ ref
g88_wrongproj = st_read(here(stec_dir, 'mangatu_eros_feat', 'mangatu_1988_ero_feat.shp'))
g88_goodproj = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'mangatu_1988_ero_feat_nztm.shp'))

#' 2. Extract geometries to check how they relate to each other
#+ Explore
# Extract geometries from good and wrong registration
t1 = g88_goodproj %>% 
  st_geometry() 

t2 = g88_wrongproj %>% 
  st_geometry()

# Transform wrong registration to same CRS as good coregistration
t2t = t2 %>% 
  st_transform(crs = st_crs(g88_goodproj)) 

# Calculate differences between polygons centroids
diff = (st_centroid(t1) - st_centroid(t2t)) 

#' 3. Check the statistics of the differences
#+ Diff
# Density
par(mfrow = c(2,2))
diff %>% 
  st_coordinates() %>% 
  apply(2, function (x) plot(density(x))) %>% 
  invisible()
# Histogram
diff %>% 
  st_coordinates() %>% 
  apply(2, hist) %>% 
  invisible()
# Median
median = diff %>% st_coordinates() %>% apply(2, median)
# Mean
mean = diff %>% st_coordinates() %>% apply(2, mean)
# Min
min = diff %>% st_coordinates() %>% apply(2, min)
# Max
max = diff %>% st_coordinates() %>% apply(2, max)
# Standard deviation
sd = diff %>% st_coordinates() %>% apply(2, sd)

knitr::kable(rbind(min, mean, median, max, sd))

#' 4. Test an affine transformation
#+ affine
# Sum the mean difference to X and Y
t3t = st_sfc(t2t + mean) %>% 
  # Reproject to "good" registration file
  st_set_crs(st_crs(t1))

#' 5. Inspect results
#+ static
t1 %>% 
  plot(border = 'darkgreen', col = NA)
t2t %>% 
  plot(border = 'red', col = NA, add = T)
t3t %>% 
  plot(border = 'blue', col = NA, add = T)

#+ interactive
mapview(t1, layer.name = "Correct proj", col.regions = 'darkgreen') +
  mapview(t2t, layer.name = "Wrong proj", col.regions = 'red') +
  mapview(t3t, layer.name = "Affine proj", col.regions = 'blue')

#' 6. Setting parameters
#+ params
crs_out = st_crs(t1)
displacement = mean

#' ## Coregistering files
#' With the above defined parameters, we can proceed to coregister our files
#'
#' 1. Load files
#+ extra_data
g39 = st_read(here(stec_dir, 'mangatu_eros_feat', 'mangatu_1939_ero_feat.shp'))
g60 = st_read(here(stec_dir, 'mangatu_eros_feat', 'mangatu_1960_ero_feat.shp'))
g70 = st_read(here(stec_dir, 'mangatu_eros_feat', 'mangatu_1970_ero_feat.shp'))

#' 2. Establish coregistration function
#+ func
coregister = function(x, crs = crs_out, affine_displacement = displacement) {
 new_geom = st_sfc(st_geometry(x) + affine_displacement, crs = crs)
 x = st_drop_geometry(x)
 st_geometry(x) = new_geom
 x
}

#' 3. Coregister files
#+ coregister
g39_co = coregister(g39)
g70_co = coregister(g70)

#' 4. Reproject 1960 file
#+ reproj
g60_proj = g60 %>%  st_transform(crs= crs_out)

#' 5. View results
#+ interactive2, eval = F
# Giving an error when rendering, try directly on console
mapview(g39, layer.name = "Wrong proj 1939", col.regions = 'red') +
  mapview(g39_co, layer.name = "Affine proj 1939", col.regions = 'blue') +
  mapview(g60_proj, layer.name = "Correct proj 1960", col.regions = 'orange') +
  mapview(g70_co, layer.name = "Affine proj 1970", col.regions = 'green') +
  mapview(g70, layer.name = "Wrong proj 1970", col.regions = 'purple') +
  mapview(g88_goodproj, layer.name = "Correct proj 1988", col.regions = 'yellow')

#' 6. Save results
#+ save, eval = F
st_write(g39_co, here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1939_ero_feat_nztm.shp'))
st_write(g60_proj, here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1960_ero_feat_nztm.shp'))
st_write(g70_co, here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1970_ero_feat_nztm.shp'))

#' ## Closing remarks
#' This approach is based on the 1988 coregistration. If we compare this 
#' correction with 1960, there will be mismatches. 
#' 
#' It could be that there is 
#' a need for rescaling factors or other parameters to make this match correctly,
#' but since the data is pre-HR-satellite-imagery timed, it is very hard for me
#' to find a better way to correctly coregister this (that I can think off).
#' 
#' Until we get a better deal, I will use this newly created files to do some 
#' ESDA and some initial testing.

#+ render, eval = F, include = F
o = knitr::spin('coregistration_approach.R', knit = FALSE)
rmarkdown::render(o)
