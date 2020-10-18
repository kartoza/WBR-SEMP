# WBR SEMP Ecological Infrastructure

These models were used to calculate the ecological infrastructure values for the WBR SEMP.

The design was based on the process workflow outlined in the paper: Integrated Spatial Prioritization for the Greater KNP Buffer, Holness 2017

Expected input layers include:

Area of interest: A projected copy of the relevant area of interest.
Landcover status: The only raster input, this is a landcover state of class 1 (Natural), 2 (Degraded) or 3 (Transformed).
Erosion: Erosion and gully areas.
Strategic water source areas: Areas of significant water production and availability, typically (in South African context) areas with >135mm precipitation per annum.
Wetlands: Wetlands with a valid hydrogeomorphic category attribute which matches the relative filter criteria listed in the process workflow/ models.

Rehabilitated wetlands were included specifically for use with the WBR SEMP, as this is a different file and utilised different categorisation attributes, however for the purposes of the process workflow they follow the same "rules" as the processing of other wetlands data.

## Model descriptions

Although it is possible to add help information to custom algorithms, the QGIS Process modeler does not include a graphical tool for including help information and details for models. As a result, this section is designed to outline the purpose and functions of the available models.

- prepare-processing-vector: cleans (fix geometry), reprojects and clips a vector layer to the project aoi boundary.
- prepare-processing-vector-hard: performs the same operations as prepare-processing-vector but include a 0 width buffer (which may take a significant amount of time on larger data sources). Note that this expects valid vector inputs and the repair shapefile algorithm may need to applied to the input before using this model on problematic data sets.
- water-availability: calculates water availability environmental infrastuctrure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- erosion-control: calculates erosion control environmental infrastuctrure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- water-quality: calculates water quality ecological infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- flood-attenuation: calculates flood attenuation ecological infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- calculate-ei: generate and aggregate the four pillar datasets produced in other models to produce a composite ecological infrastructure coverage using the maximum value at any point. Each layer in then scored according to the criteria outlined below in line with the process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer). These composite outputs are then summed into the cumulative ecological infrastructure.

### EI scoring criteria

Composite ecological infrastructure scores are calculated using the following criteria:

- Key Ecological Infrastructure (Natural) *[Areas with an ei score of 2 and a landcover status of 1]*: 10
- Additional Ecological Infrastructure (Natural) *[Areas with an ei score of 1 and a landcover status of 1]*: 8
- Key Ecological Infrastructure (Degraded) *[Areas with an ei score of 2 and a landcover status of 2]*: 6
- Additional Ecological Infrastructure (Degraded) *[Areas with an ei score of 1 and a landcover status of 2]*: 3
- Transformed Ecological Infrastructure *[Areas with a landcover status of 3]*: 1

A composite ecological infrastructure was created by obtaining the maximum value in a stack of the initial cornerstone datasets, being:

- Erosion Control
- Flood Attentuation
- Water Avaliability
- Water Quality

All 5 of the resulting composite layers, scored with values of 0-10, were then added to each other and the result multiplied by 2 to obtain the cumulative ecological infrastructure with a score range of 0-100.

### Implementation notes

This version of the ecological infrastructure modelling framework uses a raster-centric processing approach to replace the previously utilised vector-centric processing workflow. This addresses issues with processing speed and scalability. In addition, the cumulative scoring procedure was modified from the previous version.

#### Processing GOTCHAS

The native raster calculation algorithm did not work in processing models. These were switched for the GDAL raster calculator. Initial evaluation of the maximum positions in raster overlays was attempted with the GDAL "build birtual raster" system, however some results were found to be inconsistent during quality assurance checks. Instead, the SAGA processing toolkit was used and will require the relevant environment configuration. The SAGA Mosaic tool was used for maximum cell value calculations, however this process requires a regular/ consistent grid cell size with a 1:1 aspect ratio. As the input landcover data had cells of 20x19.9994 in dimension, it had to be resampled to match the extents and cell size of generated and overlay rasters.

The landcover status raster was resampled prior to the model operation using the `SAGA>>Raster Tools>>Resampling` tool with the following configuration:
- Cellsize: 20.0 (Projected CRS with units in meters)
- Downscaling: Nearest Neighbour
- Upscaling: Mean Value (Cell Area Weighted)

The area of interest layer is not extensively utilised in all models. It was included for the purpose of clipping the output rasters using the clip be vector mask, but in the troubleshooting of cumulative calculations this step was dropped to simplify the models and prevent errors.

#### Output issues

**NOTE: The cumulative ecological infrastructure raster output by the the model IS NOT CORRECT by default.** Somewhere in the workflow there seems to be an issue with "No Data" (the current form explicitly sets all 0 value cells to NODATA in the composite raster calculations, however this problem is introduced regardless of that particular setting and it is included so that we know what to expect on the other end of the outputs). In it's current form, the output only includes areas where the input rasters intersect each other and all areas which intersect "NODATA" are excluded from the output. This seems to persist through various forms of attempted resolution, including the native raster calculator, GDAL raster calculator and SAGA raster calculator, regardless of attempted formulae and settings to try and force the utilisation of the NODATA areas as 0 values.

The workflow utilised for obtaining correct result is as follows:

- Obtain the 5 cornerstone composite datasets (output in tif format).
- Load the cornerstone data into QGIS and explicitly disable the No Data value option from the layer properties.
- Create a new SAGA grid (sdat) for each dataset by exporting them with their own value using the calulation formula `a`. Ensure that the raster calculator is explicitly set to use the NODATA values.
- Generate a 0 area grid by using any cornerstone layer as the input and using the raster calculation value of `0`.
- Generate a cumulative SAGA grid with the calculation formula `a+b+c+d+e+f`.
- Create a geotiff from the cumulative sdat and correct the values to desired range of 0-100 by using the QGIS native raster calculator and the formula `"layer@1"*2`.

### Obtaining cornerstone composite datasets

The cornerstone datasets with composite values can be obtained by specifying the outputs in the ei calculation model, which is currently configured to output only the cumulative ei result (for illustrative purposes).
