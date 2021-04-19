#' ---
#' title: "Deep Learning in ArcGIS Pro"
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

#' ## Getting started with Deep Learning 
#' In [*Deep Learning Testing*](https://loreabad6.github.io/Gullies/exploration/deepl1.html)
#' I did some short exploration of the ArcGIS Pro tools for Deep Learning. 
#' Not being familiar myself with Deep Learning techniques before going into these tools, 
#' I did some small tests to understand how to set-up a Deep Learning workflow, from 
#' installation to model training and object detection. I will first summarise here these steps,
#' for documentation and further "reproducibility".
#' 
#' ### Setting-up an ArcGIS Deep Learning workflow. 
#' First of all, some specifications of the software I used to run the Deep Learning tools:
#' - ArcGIS Pro 2.7.2 with an Advance License
#' - Processor: Intel(R) Xeon(R) CPU E5-1650 v4 @ 3.60GHz
#' - Installed RAM: 64GB
#' - GPU: NVIDIA GeForce GTX 1070
#' 
#' https://github.com/Esri/deep-learning-frameworks