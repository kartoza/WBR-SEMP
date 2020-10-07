# WBR SEMP Eclogical Infrastructure

## Model descriptions

Although it is possible to add help information to custom algorithms, the QGIS Process modeler does not include a graphical tool for including help information and details for models. As a result, this section is designed to outline the purpose and functions of the available models.

- prepare-processing-vector: cleans (fix geometry), reprojects and clips a vector layer to the project aoi boundary
- prepare-processing-vector-hard: performs the same operations as prepare-processing-vector but include a 0 width buffer (which may take a significant amount of time on larger data sources). Note that this expects valid vector inputs and he repair shapefile algorithm may need to applied to the input before using this model on problematic data sets.
- environmental-infrastructure-framework: contains the full model workflow for water-availability, which is the most complex, but includes additional inputs, resources and artifacts not used in the model which are kept for the purposes of extensibility and for the production of new models or future modifications.
- water-availability: calculates water availability environmental infrastuctrure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- erosion-control: calculates erosion control environmental infrastuctrure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- water-quality: calculates water quality ecological infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- flood-attenuation: calculates flood attenuation ecological infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- ei-calculator: union and aggregate four pillar datasets produced in other models to produce a combined ecological infrastructure coverage which is clipped and categorised by land coverage class in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer). There is a vector version which struggled with geometry errors, so a raster vesrion was developed which calculates the composite and cumulative scores using the same principals but with a raster analysis workflow which operates on the rasterised results of the cornerstone feature vector datasets.

### Cumulative EI score

CEI based on the following initial IEI (integrated/ composite ecological infrastructure) scores:

- Key Ecological Infrastructure (Natural): 10
- Additional Ecological Infrastructure (Natural): 8
- Key Ecological Infrastructure (Degraded): 6
- Additional Ecological Infrastructure (Degraded): 3
- Transformed Ecological Infrastructure: 1

These were added to the existing area score (*eival* bewteen 1 and 2) value and converted into a percentage value using the formula:

```
(("iei" + "eival")/{max_cei_score})*100
```

or

```
("iei" + "eival")*({max_cei_score})/100)
```

max_cei_score is expected to be 12 and values multiplied by 8.33333

### Implementation notes

Due to errors in the input geometries and the results, the system could not be run globally in an auomated fashion and required segmenting of the vector data, which was manually processed using a combination of processing models and manual geoprocessing techniques. Likewise, whilst the logical workflow for the raster analysis was followed, the processing was implemented manually to achieve the required results.
