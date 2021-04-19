#' ---
#' title: "Deep Learning Testing"
#' subtitle: "STEC project"
#' author: "Lorena Abad"
#' date: "March 20, 2021"
#' output: 
#'   html_document: 
#'     toc: true
#'     toc_depth: 3
#'     toc_float: true
#'     code_folding: hide
#' ---
#+ setup, include = F
knitr::opts_chunk$set(echo = F, warning = F, cache = T,
                      message = F, out.width = "100%")

#' ## Deep Learning tests I
#' With the gully features from 1988 I ran some tests to train a deep 
#' learning model based on the RGB imagery
#' The model is a Mask RCNN 
#' (details [here](https://alittlepain833.medium.com/simple-understanding-of-mask-rcnn-134b5b330e95)), 
#' which trains a model on imagery based on masked polygons around
#' ground-truth features to detect objects with similar characteristics.
#' 
#' 1. Export samples
#+ out.width = "50%"
knitr::include_graphics("../deep_learning/ESRI_workflow/export_samples.PNG")
#' Some samples of the resulting chips:
#+ out.width = "70%"
knitr::include_graphics("../deep_learning/ESRI_workflow/sample_chips_rgb.gif")
#' 2. Train model
#+ out.width = "50%"
knitr::include_graphics("../deep_learning/ESRI_workflow/train_model.PNG")
#+ out.width = "70%"
knitr::include_graphics("../deep_learning/ESRI_workflow/rgb_loss_graph.png")
knitr::include_graphics("../deep_learning/ESRI_workflow/rgb_show_results.png")
#' 3. Detect objects
#+ out.width = "50%"
knitr::include_graphics("../deep_learning/ESRI_workflow/detect_objects.PNG")

#' ## Considerations at this point:
#' Results have not been successful so far with the trained models. 
#' Further points to test:
#' 
#' - Use DEM and derivatives as input data
#' - Check how to use polygons as masks to generate labeled chips
#' - Test different parameters on the literature to adjust the models
#' 
#' ## Deep Learning tests II
#' 
#' I managed to make the workflow work for the DEM data and derivatives. 
#' So far for one derivative at a time, eventually it would be useful to 
#' use a combination of distinct derivatives that allow the differentiation of the 
#' gully features on LiDAR derived data. 
#' 
#' The training is now performed with a combination of all gully features for 
#' 1939, 1957, 1960, 1970, 1988, 1997 from *Marden et al. 2012, 2014*. 
#' The preparation of the samples is 
#' [documented here](https://loreabad6.github.io/Gullies/deep_learning/sample_preparation.html)
#+ eval = F
library(sf)
library(tmap)
gullies = st_read("data_overview/gullies.shp")
t = tm_shape(gullies) +
  tm_polygons(border.col = "red", alpha = 0, width = 2) +
  tm_facets("year")
tmap_save(t, filename = "data_overview/gully_reference_data.png",
          dpi = 300, width = 15, height = 10, units = "cm")
#+ out.width = "80%"
knitr::include_graphics("../data_overview/gully_reference_data.png")
#' I tested the approach with the raw DEM values and with the Terrain Ruggedness 
#' Index (TRI) derivative
#' 
#' ### Results with DEM values
#' 
#' This are examples of the created chips used for training: 
#+ out.width = "70%"
knitr::include_graphics("../deep_learning/ESRI_workflow/sample_chips_dem.gif")
#' The chip size was increased to 512x512 and the reference features were combined to 
#' include all the active gullies detected from 1939 to 1997. 
#' 
#' The model characteristics show more insightful results compared to the RGB model:
#+ out.width = "70%"
knitr::include_graphics("../deep_learning/ESRI_workflow/dem_loss_graph.png")
knitr::include_graphics("../deep_learning/ESRI_workflow/dem_show_results.png")
#' However, applying the model on a subset of the study area was unsuccessful. 
#' Running the model for the whole area is still needed, but it is already noticeable 
#' that DEM values vary greatly among gully features, and a more standard measure is needed.
#' This is why the TRI is used next.
#' 
#' ### Results with TRI values
#' This are examples of the created chips used for training: 
#+ out.width = "70%"
knitr::include_graphics("../deep_learning/ESRI_workflow/sample_chips_tridx.gif")
#' The generation of chips also included an image augmentation process to increase the number
#' of chip samples used for training the model. All the active gully features were used as masks.
#' The training of this model is still undergoing and will take a significant amount of time
#' until results area shown.
#' 
#' ## Limitations so far:
#' - Computing power is limited on my local machine
#' - Work-flows are run now with CPU instead of GPU since there is a configuration error
#' - Testing different compositions of layers is limiting
#' - Doing a sensitivity analysis of the best parameters for model training needs larger computational power
#' 
#' ## References:
#' Marden, M., Arnold, G., Seymour, A., & Hambling, R. (2012). History and distribution of steepland gullies in response to land use change, East Coast Region, North Island, New Zealand. Geomorphology, 153–154, 81–90. https://doi.org/10.1016/j.geomorph.2012.02.011
#' Marden, M., Herzig, A., & Basher, L. (2014). Erosion process contribution to sediment yield before and after the establishment of exotic forest: Waipaoa catchment, New Zealand. Geomorphology, 226, 162–174. https://doi.org/10.1016/j.geomorph.2014.08.007
#' 
#+ render, eval = F, include = F
o = knitr::spin('exploration/deepl1.R', knit = FALSE)
rmarkdown::render(o)
 