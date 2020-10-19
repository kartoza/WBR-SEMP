# WBR SEMP Ecological Infrastructure

These models were used to calculate the ecological infrastructure values for the WBR SEMP.

The design was based on the process workflow outlined in the paper: Integrated Spatial Prioritization for the Greater KNP Buffer, Holness 2017

Expected input layers include:

- Area of interest: A projected copy of the relevant area of interest.
- Landcover status: The only raster input, this is a landcover state of class 1 (Natural), 2 (Degraded) or 3 (Transformed).
- Erosion: Erosion and gully areas.
- Strategic water source areas: Areas of significant water production and availability, typically (in South African context) areas with >135mm precipitation per annum.
- Wetlands: Wetlands with a valid hydrogeomorphic category attribute which matches the relative filter criteria listed in the process workflow/ models.

Rehabilitated wetlands were included specifically for use with the WBR SEMP, as this is a different file and utilised different categorisation attributes, however for the purposes of the process workflow they follow the same "rules" as the processing of other wetlands data.

## Model descriptions

Although it is possible to add help information to custom algorithms, the QGIS Process modeler does not include a graphical tool for including help information and details for models. As a result, this section is designed to outline the purpose and functions of the available models.

- prepare-processing-vector: cleans (fix geometry), reprojects and clips a vector layer to the project aoi boundary.
- prepare-processing-vector-hard: performs the same operations as prepare-processing-vector but include a 0 width buffer (which may take a significant amount of time on larger data sources). Note that this expects valid vector inputs and the repair shapefile algorithm may need to applied to the input before using this model on problematic data sets.
- water-availability: calculates water availability environmental infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
- erosion-control: calculates erosion control environmental infrastructure value from available input data in line with process workflow (Holness 2017, Integrated Spatial Prioritization for the Greater KNP Buffer)
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
- Flood Attenuation
- Water Availability
- Water Quality

All 5 of the resulting composite layers, scored with values of 0-10, were then added to each other and the result multiplied by 2 to obtain the cumulative ecological infrastructure with a score range of 0-100.

### Implementation notes

This version of the ecological infrastructure modelling framework uses a raster-centric processing approach to replace the previously utilised vector-centric processing workflow. This addresses issues with processing speed and scalability. In addition, the cumulative scoring procedure was modified from the previous version.

#### River buffers

River buffers in the reference paper and workflow indicated only a mimimum and a maximum buffer region. As a result, the models were designed to utilise adjustable model variables. For the WBR SEMP EI calculations, these variables were designated according to an estimate natural jenks variance based on the river order attributes as follows:

Standard riparean buffers:

- 32m: Order 1
- 50m: Order 2
- 65m: Order 3
- 80m: Order 4
- 100m: Order 5

SWSA riparean buffers:

- 100m: Order 1
- 200m: Order 2
- 300m: Order 3
- 400m: Order 4
- 500m: Order 5

#### Processing GOTCHAS

The native raster calculation algorithm did not work in processing models. These were switched for the GDAL raster calculator. Initial evaluation of the maximum positions in raster overlays was attempted with the GDAL "build virtual raster" system, however some results were found to be inconsistent during quality assurance checks. Instead, the SAGA processing toolkit was used and will require the relevant environment configuration. The SAGA Mosaic tool was used for maximum cell value calculations, however this process requires a regular/ consistent grid cell size with a 1:1 aspect ratio. As the input landcover data had cells of 20x19.9994 in dimension, it had to be resampled to match the extents and cell size of generated and overlay rasters. NoData/ NaN values also caused issues where they would prevent the representation of intersecting cells. This resulted in only intersecting positive cells from all input rasters being calculated. This was resolved in the final models by using explicit No Data settings in various points of the workflow and a separate conversion process.

The landcover status raster was resampled prior to the model operation using the `SAGA>>Raster Tools>>Resampling` tool with the following configuration:
- Cellsize: 20.0 (Projected CRS with units in meters)
- Downscaling: Nearest Neighbour
- Upscaling: Mean Value (Cell Area Weighted)
