#' ---
#' title: "Exploratory Spatial Data Analysis"
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
#' ## Setup
#' Call libraries and data

#+ setup, include = F
knitr::opts_chunk$set(echo = F, warning = F, cache = T,
                      message = F, out.width = "100%")

#+ Libraries
library(here)
library(sf)
library(stars)
library(tidyverse, quietly = T, warn.conflicts = F)
library(mapview)
library(tmap)
library(ggforce)

#+ Directories
stec_dir = "R:/RESEARCH/02_PROJECTS/01_P_330001/119_STEC/04_Data/Gullies-Mangatu"

#+ Data
# g57 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_57_tm.shp'))
# g97_1 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_97_tm.shp'))
# g97_2 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'gullies_97_f_tm.shp'))
g39 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1939_ero_feat_nztm.shp'))
g60 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1960_ero_feat_nztm.shp'))
g70 = st_read(here(stec_dir, 'mangatu_coregistered_LA', 'mangatu_1970_ero_feat_nztm.shp'))
g88 = st_read(here(stec_dir, 'Mangatu_feature_extraction', 'mangatu_1988_ero_feat_nztm.shp'))

#' ## Explore I
#' First I will combine all the data into one single object to better explore 
#' and summarize variables
#' 
#+ Combine, echo = T
# Establish some common variables
gully = list(g39, g60, g70, g88)
year = c(1939, 1960, 1970, 1988)
colnames = names(g39)
# Create function to harmonize datasets
prepare_for_merge = function(x, y) {
  z = mutate(x, year = y)
  names(z) = c(colnames, 'year')
  z
}
# Merge data
l = purrr::map2(gully, year, prepare_for_merge)
gully_merge = do.call(rbind, l) %>% 
  mutate_if(is.character, factor) %>% 
  mutate(Shape_Width = Shape_Area/Shape_Leng)

#' Now that we have one single file, we can take a look at some of the attributes.
#' 
#' ### Features per year
#' We can summarize our data to check how many erosion features we have per year.
#' I have calculated a proxy for the feature width as $Area/Length$. 
#' 
#+ Explore1, echo = T
e1 = gully_merge %>% 
  st_drop_geometry() %>% 
  group_by(year) %>% 
  summarise(
    feature_count = n(), 
    total_area = sum(Shape_Area), 
    total_length = sum(Shape_Leng),
    total_width = sum(Shape_Width)
  ) %>% 
  ungroup() 

e1 %>% 
  knitr::kable()

e1 %>% 
  pivot_longer(-year, names_to = 'indicator') %>% 
  ggplot(aes(x = year, y = value)) +
  geom_line() + geom_point() +
  labs(y = "") +
  facet_wrap(~indicator, scales = 'free_y', nrow = 2)

#' Let's take a look now at the variation of the indicators per feature and year
#+ Explore2, fig.show = 'hold', echo = T
d = gully_merge %>% 
  st_drop_geometry() %>% 
  select(-c(EROS, eros_feat_)) %>% 
  group_by(year) %>% 
  pivot_longer(-year, names_to = 'indicator')
  
d %>% 
  filter(indicator == "Shape_Area") %>%
  ggplot(aes(x = as.factor(year), y = value)) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 5e4)) +
  labs(x = 'year', y = 'area (m2)')
d %>% 
  filter(indicator == "Shape_Leng") %>%
  ggplot(aes(x = as.factor(year), y = value)) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 2e3)) +
  labs(x = 'year', y = 'length (m)')
d %>% 
  filter(indicator == "Shape_Width") %>%
  ggplot(aes(x = as.factor(year), y = value)) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 25)) +
  labs(x = 'year', y = 'width (m)')

#' ### Erosion features 
#' There are two columns that refer to this variable `EROS` and `eros_feat_`. 
#' I initially thought `EROS` was an acronym way to represent the long name
#' description in `eros_feat_`, but when I group by both features and get a count,
#' we can see that "Aggraded riverbed" is represented with three different 
#' types of `EROS` values. These are not many features, in these categories, 
#' summing up to **40** elements, but it would be still worth to check what they are.
#+ Explore3, echo = T
gully_merge %>% 
  st_drop_geometry() %>% 
  group_by(EROS, eros_feat_) %>% 
  summarise(count = n()) %>% 
  ungroup() %>% 
  knitr::kable()

#' Coming back to the variation of the erosion feature measurements, now per 
#' eorsion type and per year
#+ Explore4, fig.show = 'hold', echo = T
e = gully_merge %>% 
  st_drop_geometry() %>% 
  select(-c(EROS)) %>%
  group_by(eros_feat_) %>% 
  pivot_longer(-c(eros_feat_, year), names_to = 'indicator')

e %>% 
  filter(indicator == "Shape_Area") %>%
  ggplot(aes(x = eros_feat_, y = value, fill = as.factor(year))) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 1.5e5)) +
  labs(x = 'erosion feature', y = 'area (m2)') +
  scale_fill_discrete("Year") +
  theme(legend.position = "top", axis.text.x = element_text(angle = 90))

e %>% 
  filter(indicator == "Shape_Leng") %>%
  ggplot(aes(x = eros_feat_, y = value, fill = as.factor(year))) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 1e4)) +
  labs(x = 'erosion feature', y = 'length (m)') +
  scale_fill_discrete("Year") +
  theme(legend.position = "top", axis.text.x = element_text(angle = 90))

e %>% 
  filter(indicator == "Shape_Width") %>%
  ggplot(aes(x = eros_feat_, y = value, fill = as.factor(year))) +
  geom_boxplot() +
  facet_zoom(ylim = c(0, 35)) +
  labs(x = 'erosion feature', y = 'width (m)') +
  scale_fill_discrete("Year") +
  theme(legend.position = "top", axis.text.x = element_text(angle = 90))

#' The map below shows the evolution of these features over time.
#' 
#' Highlights:
#' 
#' 1. co-registration seems to be good
#' 2. 1988 shows a reduced extent of erosion features
#' 3. It is likely that re-vegetation plays a big role
#' 
#+ Explore5, eval = F, echo = T
tm = tm_shape(gully_merge) +
  tm_polygons(
    col = 'eros_feat_', 
    border.alpha = 0, 
    palette = "Dark2",
    legend.hist = T,
    title = "Erosion Feature",
    legend.hist.title = "Feature Count"
  ) +
  tm_facets(along = 'year', free.coords = F) +
  tm_layout(legend.outside = T, legend.hist.width = 0.8)
tmap_animation(tm, width = 1200, height = 1000, 
               filename = 'Data_overview/erosion_evolution.gif', 
               loop = T, delay = 150, restart.delay = 250)
#+ show
knitr::include_graphics('../Data_overview/erosion_evolution.gif')

#' ### Erosion Features 1988
#' A quick overview of the erosion features mapped in 1988 overlayed to the 
#' aerial imagery collected between 2012 and 2013 and LiDAR DEM from 2019.
#' 
#+ show2
knitr::include_graphics('../Data_overview/LiDAR_Aerial_1988_erosion.png') 
#' 
#' When zooming in, we can see that re-vegetation has played a big role in 
#' the erosion status of the Mangatu area. 
#' 
#' ## Considerations so far:
#' 
#' - Check the 1957 and 1997 data: It comes from a different source and 
#'   the attributes are different
#' - LiDAR DEM shows really nice the features: do a screening of what 
#'   terrain variables can be useful.
#' - Based on which imagery will we map? The mismatch between samples 
#'   and optical data might be a problem, since re-vegetation has played
#'   a big role.
#' 
#' Thoughts:
#' 
#' - Try to map the gullies only based on aerial photographs and DEM
#'   derivatives:
#'   - Candidate derivatives: slope, curvature (planar, profile), VDCN,
#'     *roughness*, hillshade, LS factor, *wetness index*
#'   - For roughness and wetness index select one specific index from SAGA.
#'   - Check Stream Power Index, seems meant to detect Gullies.
#' - Use "active gully" polygons from 1988 as a reference to create chips
#'   for Deep Learning approach  
#' 
#' ## Explore II
#' 
#' There are several mismatches with the 1988 data, some errors either
#' from coregistration errors or from original biases and errors from the 
#' delineation. For example:
#' 
#' Missing gully (?) inside red circle, is this a new feature, part of the 
#' neighbor basin or simply wrongly mapped?
knitr::include_graphics('../data_overview/Unmapped_Gully.png') 
#' 
#' The feature in the black outline clearly does not correspond to the aerial
#' photography, why? was there any change in the landscape (unlikely), or does
#' this have to do with a wrong delineation.
knitr::include_graphics('../data_overview/Unaligned_Feature.png')
#' 
#' The idea now would be to use bounding boxes of likely gully features as
#' labeled boxes of training data. Likewise, we could need to create training
#' data of areas not exposed by erosion. 
#' 
# gully_active = gully_merge %>% 
#   filter(eros_feat_ == "Active gully")
# ggplot(gully_active) +
#   geom_point(aes(x = Shape_Leng, y = Shape_Width, color = year))
# 
# gully_long = gully_active %>% 
#   filter(Shape_Width < 50)
# 
# tmap_mode("view")
# tm_shape(gully_long) +
#   tm_polygons(
#     col = "black",
#     border.alpha = 0,
#     alpha = 0.5, 
#     )
# 
# gully_int = st_intersection(gully_long)
# 
# tmap_mode("plot")
# tm_shape(gully_int) +
#   tm_fill(col = "grey", border.alpha = 0)

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
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/export_samples.PNG")
#' Some samples of the resulting chips:
#+ out.width = "70%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/sample_chips_rgb.gif")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips2.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips3.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips4.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips5.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips6.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips7.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips8.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips9.png")
# knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/chips10.png")
#' 2. Train model
#+ out.width = "50%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/train_model.PNG")
#+ out.width = "70%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/model_characteristics_rgb/loss_graph.png")
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/model_characteristics_rgb/show_results.png")
#' 3. Detect objects
#+ out.width = "50%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/detect_objects.PNG")

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
#' The training is now performed wiht a combination of all gully features for 
#' 1939, 1957, 1960, 1970, 1988, 1997 from *Marden et al. 2012, 2014*:
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
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/sample_chips_dem.gif")
#' The chip size was increased to 512x512 and the reference features were combined to 
#' include all the active gullies detected from 1939 to 1997. 
#' 
#' The model characteristics show more insightful results compared to the RGB model:
#+ out.width = "70%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/model_characteristics_dem/loss_graph.png")
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/model_characteristics_dem/show_results.png")
#' However, applying the model on a subset of the study area was unsuccessful. 
#' Running the model for the whole area is still needed, but it is already noticeable 
#' that DEM values vary greatly among gully features, and a more standard measure is needed.
#' This is why the TRI is used next.
#' 
#' ### Results with TRI values
#' This are examples of the created chips used for training: 
#+ out.width = "70%"
knitr::include_graphics("../deepl_sample_preparation/ESRI_workflow/sample_chips_tridx.gif")
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
#' ## References:
#' Marden, M., Arnold, G., Seymour, A., & Hambling, R. (2012). History and distribution of steepland gullies in response to land use change, East Coast Region, North Island, New Zealand. Geomorphology, 153–154, 81–90. https://doi.org/10.1016/j.geomorph.2012.02.011
#' Marden, M., Herzig, A., & Basher, L. (2014). Erosion process contribution to sediment yield before and after the establishment of exotic forest: Waipaoa catchment, New Zealand. Geomorphology, 226, 162–174. https://doi.org/10.1016/j.geomorph.2014.08.007
#' 
#+ render, eval = F, include = F
o = knitr::spin('exploration/esda.R', knit = FALSE)
rmarkdown::render(o)
