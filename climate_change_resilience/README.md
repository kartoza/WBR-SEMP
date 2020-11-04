# Areas important for supporting climate change resilience in the WBR SEMP

The models in the folder were used to calculate the Climate Change -Value for Supporting Resilience for the WBR SEMP. The process workflow used was based on the report by S. Holness: Integrated Spatial Prioritization for the Greater KNP Buffer, 2017 as a guide to design the models.

## Input layers

#### Riparian corridors and buffer
- Rivers filtered to 2nd order and large rivers (filtered the core rivers of the study area).
- Landcover status raster layer used to get the degraded, natural and transformed land types.

#### Areas with important temperature, rainfall and altitudinal gradients
- DEM resampled to 1km.
- Mean monthly precipitation resampled to 1km.
- Mean monthly temperature resampled to 1km.

#### Areas of high biotic diversity
- Vegetation map for 2018. Biomes, bioregions and vegetation type was used to identify areas with high biotic diversity.

#### Local refugia- south facing slopes and kloofs
- DEM resampled to 90m.
- Rivers clipped to proposed study area extent.

#### Priority large unfragmented landscapes
- Protected areas layer from SANBI.
- Priority large unfragmented landscapes from SANBI.

#### Centres of floristic endemism
- The data has all species of plantae, and Holness identified vascular plant species endemic to the KNP region. The current data does not show which species are endemic and which are not.

## Description of Model
To get the climate change resilience (ccr) output, 4 sub-models were designed to get the layers that will be combined to get the ccr layer. The intact centre of endemism and the large priority intact landscapes are the only two layers that were created without the use of a model.
#### Riparian corridors and buffer:
- The model buffers clipped and filtered rivers at 10km, 5km and 1km distance. then converts the buffers to raster at 90m resolution. It takes the raster landcover layer separates it to the 3 classes (i.e. natural, degraded and transformed). The rasterized layers are then combined with the landcover layers to produce cost surface raster/ friction map. then finally calculates the cost to produce the riparian corridor and buffer layer.
#### Biophysical diversity
- The process begins with clipping the three raster layers (DEM, precipitation and temperature) to the aoi extent. The layers are then resampled to 1km and re-projected to UTM 35S. The GRASS GIS neighbors tool is used to calculate maximum and minimum values of altitude, temperature and precipitation found within a roving 7x7 grid. 
#### Habitat diversity: 
- The vegetation map for 2018 is the main input for the processing of the high biotic diversity layer/ habitat layer. The process involves rasterizing the vegetation map according to biomes, bioregions and vegetation type to 1km resolution. The GRASS GIS neighbors tool is used to calculate the number of biomes, bioregions and vegetation types found within a roving 7x7 grid. All three layers are combined to produce the high biotic vegetation map. Note: an extra column for vegetation types must be added manually before using the model.
#### Local refugia: 
- It calculates the south-facing slope and kloofs using input layers mentioned above. 
#### Priority large unfragmented areas: 
- It merges existing protected areas and NPAES data, converts the merged data to raster and produces a layer showing priority areas in the WBR aoi that have experienced less impact.
#### Intact Centre of Endemism
- The threatened vegetaion map was used to create the layer. The endemic column was used to classify the map for the Waterberg region
#### Climate change resilience: 
- This takes in the output layers from the 5 sub-modes and gives each layer a range of 0 to 1 (0 being low diversity, no refugia etc). The model is highly reliant on the raster calculator, but the raster calculator has issues when using it in the modeler. The calculations were done manually using the raster calculator. Out of the six layers that need to be included to produce the CCR layer, only five layers were combined. Before combining the layers, layers which were at a 1km resolution were resmapled to 90m (i.e. when following Holness process workflow).

## Note
This file is subject to changes based on improvements made on the models.
