Gully detection based on LiDAR and terrain derivatives with Deep Learning
================

Exploring existing gully inventories in the Gisborne area in New Zealand
to develop a gully detection approach based on LiDAR and terrain
derivatives.

Summary of work so far:

1.  Reference data needed some correction regarding co-registration, the
    approach followed is [documented
    here](https://loreabad6.github.io/Gullies/pre-processing/coregistration_approach.html).
    The sample preparation for deep learning is [documented
    here](https://loreabad6.github.io/Gullies/deep_learning/sample_preparation.html).

2.  A calculation of terrain derivatives was prepared based on the LiDAR
    DEM data provided. The approach is [documented
    here](https://loreabad6.github.io/Gullies/pre-processing/terrain_derivatives.html)
    and to developed this, an [R package
    `terrain`](https://github.com/loreabad6/terrain) was created to ease
    the workflow.

3.  A summary of the exploration of the reference data and initial tests
    with deep learning approaches in ArcGIS are [documented
    here](https://loreabad6.github.io/Gullies/exploration/esda.html) and
    [here](https://loreabad6.github.io/Gullies/exploration/deepl1.html).

4.  Further experimentation with ArcGIS Pro deep learning tools led to
    the insights [documented
    here](https://loreabad6.github.io/Gullies/exploration/deepl2.html).

## Acknowledgements

This research work is supported by the New Zealand Ministry of Business,
Innovation and Employment research program “Smarter Targeting of Erosion
Control (STEC)” (Contract C09X1804).
