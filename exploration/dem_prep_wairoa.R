#' Validation of Deep Learning Model on a different study area
#' 
#' Data for gullies, earthflows and cliffs were providaded by Landcare, 
#' done via manual delineation. The area is in Wairoa, and part of the catchment
#' intersects with a part of the Gisborne LiDAR tiles available in Linz.
#' 
#' With this script I will: 
#' 
#' 1. Check Map Sheet tiles that intersect with the Wairoa catchment 
#' 2. 
#' 
#' 
#' 1. DEM preparation
library(here)
library(sf)
library(stars)
library(tidyverse)
# library(qgisprocess)

dir_R = "//shares/sfs_0165_1/ZGIS/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data"
grid_fn = here(dir_R, 'Wairoa','5_km_grid.shp')
grid = read_sf(grid_fn)
dir_local = "D:/STEC/Gullies/data_wairoa/"
lidartiles_fn = here(dir_local, "gisborne-lidar-1m-index-tiles-2018-2020-wairoa.gpkg")
lidartiles = read_sf(lidartiles_fn)
lidartiles %>% 
  st_filter(grid) %>% 
  separate(tilename, into = c("mapsheet", NA, NA), sep = "_") %>% 
  st_drop_geometry() %>% 
  count(mapsheet)

#' I download from the LINZ database the 
#' [Gisborne DEM](https://data.linz.govt.nz/layer/105397-gisborne-lidar-1m-index-tiles-2018-2020/)
#' by the tiles resulting above that intersect with the mapped grid in Wairoa.
#' I will only include areas with more than 100 counts. I added this to R.
#' Next, I will select only those DEM tiles interesting for testing, where we 
#' have some validation data.
lidar_fn = list.files(
  here(dir_R, 'DEM/Gisborne-LiDAR-DEM (partial)'),
  pattern = '.tif'
) %>% as_tibble() %>% 
  transmute(filename = str_remove(value, ".tif")) %>% 
  separate(
    filename,
    into = c("datatype","mapsheet", "year", "tile_X", 'tile_Y'),
    sep = "_",
    remove = FALSE
  )

grid_62 = grid %>% 
  filter(Id %in% c(62))
lidartiles_62 = lidartiles %>% 
  st_filter(grid_62) %>% 
  mutate(matchname = stringi::stri_replace_first_fixed(tilename, "_", "_2018_")) %>% 
  mutate(matchname = str_c("DEM_", matchname)) %>% 
  st_drop_geometry()

grid_119 = grid %>% 
  filter(Id %in% c(119))
lidartiles_119 = lidartiles %>% 
  st_filter(grid_119) %>% 
  mutate(matchname = stringi::stri_replace_first_fixed(tilename, "_", "_2018_")) %>% 
  mutate(matchname = str_c("DEM_", matchname)) %>% 
  st_drop_geometry()

lidar_62 = lidar_fn %>% 
  filter(filename %in% lidartiles_62$matchname) %>% 
  mutate(filepath = str_c(dir_R, '/DEM/Gisborne-LiDAR-DEM (partial)/', filename, '.tif'))
lidar_119 = lidar_fn %>% 
  filter(filename %in% lidartiles_119$matchname) %>% 
  mutate(filepath = str_c(dir_R, '/DEM/Gisborne-LiDAR-DEM (partial)/', filename, '.tif'))


#' Now we can combine the DEMs for grid # 62 and 119
dem_62 = st_mosaic(
  lidar_62$filepath,
  dst = here(dir_local, 'LiDAR_DEM_2018_grid62.tif')
)  
dem_119 = st_mosaic(
  lidar_119$filepath,
  dst = here(dir_local, 'LiDAR_DEM_2018_grid119.tif')
) 
