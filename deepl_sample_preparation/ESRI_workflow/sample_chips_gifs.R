library(magick)
library(raster)
library(here)
path_tridx = "deepl_sample_preparation/chips_tridx_mask/images/"
path_dem = "deepl_sample_preparation/chips_dem_mask/images/"
path_rgb = "deepl_sample_preparation/chips_rgb_poly/images/"

chips_as_gif = function(path, n_sample, fps, normalize = FALSE) {
  chips = list.files(path, pattern = ".tif", full.names = TRUE)
  chips_sample = sample(chips, n_sample)
  if (normalize) {
    chips_rast = lapply(chips_sample, raster)
    norm = function(rast) {
      mnv = cellStats(rast, "min")
      mxv = cellStats(rast, "max")
      as.array((rast - mnv) / (mxv - mnv))
    }
    chips_norm = lapply(chips_rast, norm)
    chips_read = lapply(chips_norm, image_read)
  } else {
    chips_read = lapply(chips_sample, image_read)
  }
  chips_join = image_join(chips_read)
  image_animate(chips_join, fps = fps)
}

gif_tridx = chips_as_gif(path_tridx, 15, 1)
gif_rgb = chips_as_gif(path_rgb, 15, 1)
gif_dem = chips_as_gif(path_dem, 15, 1, normalize = T)

image_write_gif(gif_tridx, "deepl_sample_preparation/ESRI_workflow/chips_tridx.gif", delay = 1)
image_write_gif(gif_rgb, "deepl_sample_preparation/ESRI_workflow/chips_rgb.gif", delay = 1)
image_write_gif(gif_dem, "deepl_sample_preparation/ESRI_workflow/chips_dem.gif", delay = 1)
