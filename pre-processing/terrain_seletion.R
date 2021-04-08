library(stars)
library(here)
files = list.files(here("terrain"),
                   pattern = "*.tif$", full.names = TRUE)
terrain = lapply(files[c(6,8,13)], read_stars, proxy = TRUE)
terrain_merge = do.call(c, terrain) %>% merge() %>% 
  st_set_dimensions(names = c("x", "y", "derivative"))
terrain_merge %>% plot()
write_stars(terrain_merge, "terrain/terrain_selected_top3.tif")

