#' ---
#' title: "Deep Learning in ArcGIS Pro"
#' subtitle: "STEC project"
#' author: "Lorena Abad"
#' date: "March 20, 2021"
#' output: 
#'   bookdown::html_document2:
#'     number_sections: false
#'     toc: true
#'     toc_depth: 3
#'     toc_float: true
#' ---
#+ setup, include = F
knitr::opts_chunk$set(echo = F, warning = F, cache = T,
                      message = F, out.width = "100%")
library(here)

#' ## Getting started with Deep Learning 
#' In [*Deep Learning Testing*](https://loreabad6.github.io/Gullies/exploration/deepl1.html)
#' I did some short exploration of the ArcGIS Pro tools for Deep Learning. 
#' Not being familiar myself with Deep Learning techniques before going into
#' these tools, I did some small tests to understand how to set-up a Deep 
#' Learning workflow, from installation to model training and object detection.
#' I will first summarise here these steps, for documentation and further
#' "reproducibility".
#' 
#' ### Set-up ESRI for Deep Learning
#' First of all, some specifications of the software I used to run the
#' Deep Learning tools:
#' 
#' - ArcGIS Pro 2.7.2 with an Advance License
#' - Processor: Intel(R) Xeon(R) CPU E5-1650 v4 @ 3.60GHz
#' - Installed RAM: 64GB
#' - GPU: NVIDIA GeForce GTX 1070
#' 
#' According to the [ESRI Deep Learning Frameworks](https://github.com/Esri/deep-learning-frameworks)
#' It is possible to download an installer that will take care of including
#' all the deep learning packages into the Python environment in ArcGIS Pro. 
#' However, this did not work properly, so I had to follow the instructions
#' on [their guide](https://github.com/Esri/deep-learning-frameworks/blob/master/install-deep-learning-frameworks-manually-2-7.pdf)
#' to clone the default environment for ArcGIS projects into a new 
#' `deeplearning` environment, and then install the libraries separately.
#' 
#' ### Workflow and pre-requisites {.tabset}
#' #### Workflow 
#' In general to detect objects with Deep Learning, one would use the following
#' combination of tools:
#+ fig.align='center', fig.cap = "Deep Learning workflow for object detection in ArcGIS Pro"
library(DiagrammeR)
grViz(
"digraph {
  graph [layout = dot, rankdir = LR]
  
  node [shape = round, fontname = Helvetica, fillcolor = lightblue, style = filled]        
  rec1 [label = 'Export Training Data for Deep Learning']
  rec2 [label = 'Train Deep Learning Model']
  rec3 [label = 'Detect Objects Using Deep Learning']
  
  # edge definitions with the node IDs
  rec1 -> rec2 -> rec3 
  }", 
  width = 800, height = 80
)
#' I found some limitations for each of these steps which I included in the next
#' tabs. I refer to them as pre-requisites to successfully run a deep learning 
#' workflow in ArcGIS Pro based solely on my efforts. It might as well be that
#' there are other ways to do this more efficiently that I am not aware of yet. 
#' 
#' #### Export Training Data
#' This tool creates labelled chips that will be subsequently used to train models.
#'  
#+ fig2, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","export_training_tool.png"))
#' <details>
#'  <summary>Tool screenshot</summary>
#+  fig2, eval = T, out.width = "50%", fig.align='center', fig.cap = "Export Training Data for Deep Learning Tool"
#' </details> <br>
#' 
#' I decided to use Mask RCNN (details [here](https://alittlepain833.medium.com/simple-understanding-of-mask-rcnn-134b5b330e95)),
#' method and hence the decisions for the parameters required for this tool.
#' I summarize the most important parameters below. 
#' 
#' | **Parameter** | **Description** |
#' | ----| --------------- |
#' | Input raster | A *single* band (any type) or a *three* band (8-bit, scaled, RGB channels) raster. |
#' | Input feature class | Training polygons. They can be overlapping and differ in sizes. |
#' | Image format | What output format should the chips have? I used TIFF. |
#' | Tile size | How big should the tiles be? Larger tile sizes seem to avoid problems when using the subsequent tools. |
#' | Stride | Overlap between tiles, should be smaller than the tile size. For no overlap `tile = stride` size. |
#' | Metadata | Depends on the model to train. I use RCNN Masks. |
#' | Rotation angle | For data augmentation, rotates the chips at certain angles to create more training samples. An angle of 90 will create 4x the number of samples. |
#' 
#' The output consists on a `images` and a `labels` directory. 
#' The images are basically cropped subsets from the original input raster. 
#' The labels are "masks" that should ideally have a value of `1` when the pixel
#' is overlayed by a training polygon or `0` when it is not. During my tests I realized that 
#' using overlapping training polygons can result in strange labels, where there are values 
#' outside of the `0-1` range generated. Users have [reported this issue on the ESRI forums without an answer so far](https://community.esri.com/t5/arcgis-pro-questions/quot-export-training-data-for-deep-learning-quot-creates/m-p/225513).
#' However, after some further testing I realized this is not really 
#' a problem when using a *three* band raster and hence did not look for a solution. 
#' 
#' In general this tool took between **10 and 20 minutes** to run.
#' 
#' **NOTE:** About the **Input raster** parameter
#' 
#' This can be a *single* band raster or an *three* band RGB-like raster. We aimed at
#' trainng our model with multiple bands (at least 15), but since we were limited by
#' the input data constraint, we selected a combination of three bands from the terrain
#' derivatives. Next, we had to convert this multiband raster into an 8-BIT-Unsigned scaled raster
#' to be able to run the **Training** tool. This was done with the *Copy Raster* tool in ArcGIS.
#' 
#+ fig3, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","copy_raster_tool.png"))
#' <details>
#'  <summary>Tool screenshot</summary>
#+  fig3, eval = T, out.width = "50%", fig.align='center', fig.cap = "Copy Raster Tool"
#' </details> <br>
#' 
#' #### Train Model
#' This tool is used to train the deep learning model (details of usage can be found
#' [here](https://pro.arcgis.com/en/pro-app/latest/tool-reference/image-analyst/train-deep-learning-model.htm)).
#' 
#' Some parameters to consider, which will vary computation time and outputs:
#' 
#' | **Parameter** | **Description** |
#' | ----| --------------- |
#' | Input training data | The folder containing the image chips, labels, and statistics required to train the model.<br>This is the output from the **Export Training Data For Deep Learning** tool.<br>To train a model, the input images must be 8-bit rasters with three bands.|
#' | Max Epochs | A maximum epoch of one means the dataset will be passed forward and backward through the neural network one time. The default value is 20.<br>The number of epochs is a hyperparameter that defines the number times that the learning algorithm will work through the entire training dataset.|
#' | Model type | MASKRCNN —The MaskRCNN approach will be used to train the model. MaskRCNN is used for object detection. It is used for instance segmentation, which is precise delineation of objects in an image. This model type can be used to detect building footprints. It uses the MaskRCNN metadata format for training data as input. Class values for input training data must start at 1. This model type can only be trained using a CUDA-enabled GPU. |
#' | Batch size | The number of training samples to be processed for training at one time. The default value is 2. If you have a powerful GPU, this number can be increased to 8, 16, 32, or 64. <br>The batch size is a hyperparameter that defines the number of samples to work through before updating the internal model parameters. |
#' | Chip size | All model types support the chip_size argument, which is the chip size of the tiles in the training samples. The image chip size is extracted from the .emd file from the folder specified in the in_folder parameter. |
#' | Learning rate | No value defined: The rate at which existing information will be overwritten with newly acquired information throughout the training process. If no value is specified, the optimal learning rate will be extracted from the learning curve during the training process. |
#' | Backbone Model | Default used: RESNET50 —The preconfigured model will be a residual network trained on the ImageNET Dataset that contains more than 1 million images and is 50 layers deep. |
#' 
#+ fig4, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","train_dl_tool.png"))
knitr::include_graphics(here("deep_learning","ESRI_workflow","train_dl_tool_env.png"))
#' <details>
#'  <summary>Tool screenshot</summary>
#+  fig4, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Train Deep Learning Model Tool"
#' </details> <br>
#' 
#' Adding a chip size larger than 512 or a batch size larger than 4 resulted in
#' the error *CUDA out of memory*, i.e. the GPU installed was not enough.
#' 
#' In general training the deep learning models took between **10 and 12 hours**. 
#' 
#' #### Detect Objects
#' Finally, this tool was used to detect the objects using the deep learning models
#' previously trained.
#' 
#+ fig5, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","detect_objects_tool.png"))
knitr::include_graphics(here("deep_learning","ESRI_workflow","detect_objects_tool_env.png"))
#' <details>
#'  <summary>Tool screenshot</summary>
#+  fig5, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Detect Objects using Deep Learning Tool"
#' </details> <br>
#' 
#' The threshold parameter refers to the minimum confidence value to keep for the detected objects.
#' The padding size was the main parameter tested with this tool. 
#' The resulting objects and the run time varied depending on which padding size was selected. 
#' For an overview of the runtime see the figures below. 
#' 
#+  fig6, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Ellapsed times vs Padding size"
library(tidyverse)
processing = data.frame(
  padding = c(250, 200, 128, 64, 32, 16, 4, 0),
  elapsed_time = c(
    83*3600 + 53*60 + 23,
    58*60 + 55,
    11*60 + 58,
    05*60 + 31,
    03*60 + 49,
    03*60 + 26,
    03*60 + 07,
    03*60 + 24
  ),
  zoom = c(F, rep(TRUE, 7))
)
ggplot(processing) +
  aes(x = padding, y = elapsed_time) +
  geom_smooth(formula = "y ~ x", method = "loess", se = FALSE, color = "grey30") +
  geom_point(size = 4, color = "orange") +
  labs(
    x = "Padding Size", 
    y = "", 
    title = "Elapsed time according to padding size"
  ) + scale_y_time()

ggplot(filter(processing, zoom)) +
  aes(x = padding, y = elapsed_time) +
  geom_smooth(formula = "y ~ x", method = "loess", se = FALSE, color = "grey30") +
  geom_point(size = 4, color = "orange") +
  labs(
    x = "Padding Size", 
    y = "", 
    title = "Zoommed for padding size below 200"
  ) +
  scale_y_time() 

#' ## Application
#' 
#' The goal of these tests was to apply the Deep Learning Tools provided in ArcGIS Pro
#' to detect gully features on terrain derivatives obtained from a LiDAR DEM. 
#' 
#' ### Input data
#' Initially 15 derivatives (see figure \@ref(fig:fig7)) were computed from the DEM.
#' 
#' |  |  |  |  |  |
#' | ---- | ---- | ---- | ---- | ---- |
#' | channel network | planar curvature | profile curvature | downslope distance gradient | flow accumulation |
#' | LS-factor | mass balance index | hillshade | slope | specific catchment area |
#' | stream power index | texture | terrain ruggedness index | terrain wetness index | vertical distance to channel network |
#' 
#+ fig7, eval = T, fig.show="hold", out.width = "80%", fig.align='center', fig.cap = "Terrain derivatives computed"
knitr::include_graphics(here("data_overview", "derivatives.png"))
#' 
#' The plan was to use all of them for gully detection. 
#' Since, that was not possible, I did a selection of derivatives,
#' see [here](pre-processing/terrain-selection.R).
#' 
#' The combinations tested were:
#' 
#' - Planar curvature + Slope + Terrain wetness index (cplan+slope+twidx)
#' - LS-factor + Terrain ruggedness index + Terrain wetness index (lsfct+tridx+twidx)
#' - LS-factor + Hillshade + Terrain ruggedness index (lsfct+shade+tridx)
#' 
#' ### Model characteristics
#' The ArcGIS Pro workflow for Deep Learning was applied for each of these combinations, 
#' preparing training data and running a model for each of them.
#' 
#+ fig8, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","cplanslopetwidx_loss_graph.png"))
knitr::include_graphics(here("deep_learning","ESRI_workflow","cplanslopetwidx_show_results.png"))
#' <details>
#'  <summary> 1. `cplan+slope+twidx` model characteristics </summary>
#+  fig8, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Loss graph and Results subset for the first model"
#' </details> <br>
#' 
#+ fig9, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","lsfcttridxtwidx_loss_graph.png"))
knitr::include_graphics(here("deep_learning","ESRI_workflow","lsfcttridxtwidx_show_results.png"))
#' <details>
#'  <summary> 2. `lsfct+tridx+twidx` characteristics </summary>
#+  fig9, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Loss graph and Results subset for the second model"
#' </details> <br>
#' 
#+ fig10, eval = F
knitr::include_graphics(here("deep_learning","ESRI_workflow","lsfctshadetridx_loss_graph.png"))
knitr::include_graphics(here("deep_learning","ESRI_workflow","lsfctshadetridx_show_results.png"))
#' <details>
#'  <summary> 3. `lsfct+shade+tridx` characteristics </summary>
#+  fig10, eval = T, fig.show="hold", out.width = "50%", fig.align='center', fig.cap = "Loss graph and Results subset for the third model"
#' </details> <br>
#' 
#' Each of the resulting models were then passed to the Detect Objects tool with 
#' distinct padding sizes (250, 200, 128, 64, 32, 16, 4, 0). Every run of the tool
#' resulted in slightly different results. 
#' 
#' ## Results
#' The final detected objects obtained from each of the models varied depending on the
#' derivatives selection but also on the padding size selected. 
library(tmap)
library(sf)
library(patchwork)
files = list.files(here("deep_learning", "DetectedObjects"), "8bit.*.shp$", full.names = TRUE)
names = list.files(here("deep_learning", "DetectedObjects"), "8bit.*.shp$", full.names = FALSE) 

read_func = function(x, name) {
  read_sf(x, quiet = TRUE) %>% 
    mutate(filename = name)
}

detected_gullies_combine = do.call(rbind, purrr::map2(files, names, read_func)) 
detected_gullies = detected_gullies_combine %>% 
  mutate(
    model = map_chr(str_split(filename, "_"), `[[`, 2),
    padding = str_extract(
      map_chr(str_split(filename, "_"), `[[`, 4),
      "\\d+"
    )
  ) %>% 
  mutate(model = case_when(
    model == "curvslopetwidx" ~ "cplanslopetwidx",
    model == "merge3" ~ "lsfctshadetridx",
    TRUE ~ model
  )) %>% 
  select(-c(Class, filename)) %>% 
  relocate(geometry, .after = padding) %>% 
  arrange(Confidence) %>% 
  mutate(padding = as.numeric(padding))

#' In general, a higher amount of objects were detected for the `lsfct+shade+tridx` model.
#+ fig11, eval = T, fig.show="hold", out.width = "100%", fig.align='center', fig.cap = "Distribution of Confidence values for the detected objects according to the padding size and model"
ggplot(detected_gullies) +
  geom_histogram(aes(Confidence)) +
  scale_x_continuous(breaks = c(50, 75, 100)) +
  facet_grid(model ~ padding)

#' The spatial distribution of the objects detected with the `lsfct+shade+tridx` model
#' seemed also to offer a better overview of the gully location throughout the study area.
#' This model seemed to be the most promising combination of terrain derivatives. 
#+ fig12, eval = T, fig.height = 2, fig.show="hold", out.width = "90%", fig.align='center', fig.cap = "Spatial distribution of detected objects by model"
tmap_mode("plot")
tm_shape(detected_gullies) +
  tm_polygons(col = "Confidence", palette = "-magma", legend.hist = T) +
  tm_layout(legend.width = 0.3, legend.hist.width = 1) +
  tm_facets(by = "model", ncol = 3) 
#' 
#' To simplify the exploration, I will only look into the results of this model.
#' All the other results are in the [deep_learning/DetectedObjects](deep_learning/DetectedObjects)
#' directory as shapefiles. 
#' 
#' Below is an overview of the detected objects according to the padding size used.
#' In the background in light grey, the reference gully data is mapped.
#+ fig13, eval = T, fig.height = 3, fig.show="hold", out.width = "100%", fig.align='center', fig.cap = "Spatial distribution of detected objects by padding size"
detected_gullies_bestmodel = detected_gullies %>% 
  filter(model == "lsfctshadetridx") %>% 
  mutate(area = st_area(geometry))
gullies = st_read(here("data_overview", "gullies.shp"), quiet = TRUE) %>% 
  mutate(area = st_area(geometry))
tm_shape(gullies) +
  tm_fill(col = "grey70") +
  tm_shape(detected_gullies_bestmodel) +
  tm_polygons(
    col = "Confidence", palette = "-magma",
    legend.hist = T
  ) +
  tm_facets(by = "padding", ncol = 4) 

#+ fig14, eval = T, fig.show="hold", out.width = "80%", fig.align='center', fig.cap = "Number of detected objects by padding size"
ggplot(detected_gullies_bestmodel) +
  geom_bar(aes(as.factor(padding))) +
  labs(y = "No. of detected objects", x = "Padding size")

#+ fig15, eval = T, fig.show="hold", out.width = "80%", fig.align='center', fig.cap = "Area of detected objects"
g1 = ggplot((detected_gullies_bestmodel)) +
  geom_violin(aes(y = as.numeric(area)*0.0001, x = as.factor(padding))) +
  labs(y = "Area (ha)", x = "Padding size", title = "Area of detected objects by padding size")

g2 = ggplot(gullies) +
  geom_violin(aes(x = "Reference", y = as.numeric(area)*0.0001)) +
  labs(y = "Area (ha)", x = NULL, title = "Area of reference gully features (for comparison)")

g1 / g2
#' In general, the main limitation is the size of the objects, which are simply not on 
#' the same range as for the actual gully features.
#' 
#' ## Limitations and outlook
#' 
#' 1. Number of bands 
#' 
#' It is really important to note that the ESRI deep learning tools are limited to the 
#' number of bands that can be used for training. This can be a *single* band raster
#' or an *three* band RGB-like raster. I believe this has to do with training models 
#' on very-high-resolution RGB imagery, for which these deep learning methods seem to
#' be optimized. However, this is a big disadvantage when having multiple bands for
#' instance with high-resolution Sentinel-2 image, where the full potential is not
#' exploited. For our case study, the goal was to include several terrain derivatives
#' obtained from a LiDAR DEM. However, due to the tools limitations, we had to select
#' three bands at a time to simulate an RGB image to be used for training. 
#' 
#' Other tools such as eCognition or directly using Python modules seem to allow for
#' multiple bands as input, and this still needs to be tested. 
#' 
#' 2. GPU constraints
#' 
#' The ability to run more powerful models that run for longer times and that require 
#' larger batch sizes or higher number of epochs is restricted by the hardware in use. 
#' This is well-known for the machine learning domain, and hence alternatives like 
#' high-performance cloud computing could be considered (although they usually come
#' at a cost).
#' 
#' 3. Not completely satisfactory results
#' 
#' The resulting gully objects detected with the three tested models were in general 
#' matching spatially the gully features on the field, however the size of the objects
#' was very small compared to the size of the actual gullies on the reference data.
#' 
#' The object sizes (mainly their length) do not seem to reach the shapes found on the
#' field. I believe this could be related to the tile size selected (512 pixels), which 
#' might have been insufficient to completely capture the majority of gullies per tile.
#' However, working with larger tiles sizes was not possible due to GPU constraints. 
#' 
#' A possible solution is to work with the resulting features within an OBIA workflow
#' that allows growing these objects in combination with the aerial imagery from the area.
#' This is one possible idea that will be tested in a next step. 
#' 
#' ## References
#' - Brownlee, J. (2018)
#' [Difference Between a Batch and an Epoch in a Neural Network](https://machinelearningmastery.com/difference-between-a-batch-and-an-epoch/).
#+ render, eval = F, include = F
o = knitr::spin('exploration/deepl2.R', knit = FALSE)
rmarkdown::render(o)
